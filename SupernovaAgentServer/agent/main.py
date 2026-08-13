"""Supernova agent service — FastAPI + WebSocket streaming.

Run:  uvicorn agent.main:app --host 0.0.0.0 --port 8000 [--workers N]
Mock: AMEEN_MOCK=1 uvicorn agent.main:app --port 8000

Stateless by design: sessions live in Redis, models load once per process,
so multiple workers behind a load balancer just work.
"""

from __future__ import annotations

import asyncio
import json
import logging
import uuid
from contextlib import asynccontextmanager

from fastapi import FastAPI, WebSocket, WebSocketDisconnect

from agent.audit import make_audit
from agent.config import get_settings
from agent.llm import make_llm
from agent.metrics import metrics
from agent.orchestrator import OrchestratorAgent
from agent.sessions import make_store

logging.basicConfig(level=logging.INFO)
log = logging.getLogger("supernova.main")

RATE_LIMIT_MESSAGE = (
    "أرسلت رسائل كثيرة خلال وقت قصير. "
    "انتظر لحظات من فضلك ثم أكمل حديثنا، شكراً لتفهمك."
)


@asynccontextmanager
async def lifespan(app: FastAPI):
    settings = get_settings()
    app.state.settings = settings
    app.state.store = await make_store(settings)
    app.state.audit = await make_audit(settings)
    app.state.llm = make_llm(settings)
    # Backpressure: bound concurrent in-flight LLM calls; excess queues here.
    app.state.llm_semaphore = asyncio.Semaphore(settings.max_inflight_llm)
    app.state.orchestrator = OrchestratorAgent(
        llm=app.state.llm,
        store=app.state.store,
        audit=app.state.audit,
        llm_semaphore=app.state.llm_semaphore,
    )
    log.info(
        "supernova agent up (mock=%s, model=%s)",
        settings.ameen_mock, settings.ameen_model,
    )
    yield
    await app.state.audit.close()


app = FastAPI(title="Supernova Agent", lifespan=lifespan)


@app.get("/health")
async def health():
    redis_ok = await app.state.store.ping()
    db_ok = await app.state.audit.ping()
    ok = redis_ok and db_ok
    return {
        "status": "ok" if ok else "degraded",
        "redis": redis_ok,
        "database": db_ok,
        "mock": app.state.settings.ameen_mock,
    }


@app.get("/metrics")
async def get_metrics():
    return metrics.snapshot()


@app.websocket("/ws")
async def ws_chat(ws: WebSocket) -> None:
    await ws.accept()
    metrics.inc("ws_connections_total")
    settings = app.state.settings
    session_id = ws.query_params.get("session_id") or f"s-{uuid.uuid4().hex}"
    await ws.send_json({"type": "session", "session_id": session_id})

    async def emit(event: dict) -> None:
        await ws.send_json(event)

    try:
        while True:
            raw = await ws.receive_text()
            try:
                data = json.loads(raw)
                text = str(data.get("text", "")).strip()
            except ValueError:
                text = raw.strip()
            if not text:
                await ws.send_json(
                    {"type": "error", "code": "empty_message", "message": "اكتب رسالة من فضلك."}
                )
                continue

            allowed = await app.state.store.check_rate_limit(
                session_id, settings.rate_limit_per_min
            )
            if not allowed:
                metrics.inc("rate_limited_total")
                await ws.send_json(
                    {"type": "error", "code": "rate_limited", "message": RATE_LIMIT_MESSAGE}
                )
                await ws.send_json({"type": "done"})
                continue

            await app.state.orchestrator.run_turn(
                session_id=session_id, user_text=text, emit=emit
            )
    except WebSocketDisconnect:
        pass
