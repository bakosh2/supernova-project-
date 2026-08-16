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


# ============================================================
# SIMPLE SIRI HOMEWORK ENDPOINT
# ============================================================

from typing import Optional
from pydantic import BaseModel
from fastapi import HTTPException
from agent.agent import run_specialist
from agent.specialists import SPECIALISTS


class SiriHomeworkRequest(BaseModel):
    description: Optional[str] = None
    current_task: Optional[dict] = None
    change: Optional[str] = None


@app.post("/siri-homework")
async def siri_homework_endpoint(req: SiriHomeworkRequest):
    desc = (req.description or "").strip()
    change = (req.change or "").strip()
    current_task = req.current_task

    if not desc and not change:
        raise HTTPException(status_code=400, detail="Description or change request required")

    specialist = SPECIALISTS["siri_homework"]
    captured_task = None

    async def emit(event: dict) -> None:
        nonlocal captured_task
        if event.get("task") and (event.get("type") == "task_preview" or event.get("event") == "task_preview"):
            captured_task = event["task"]

    if current_task and change:
        prompt_text = f"الواجب الأصلي: {desc}\nالنسخة الحالية من المهمة: {json.dumps(current_task, ensure_ascii=False)}\nالتعديل المطلوب من الوالد: {change}"
    else:
        prompt_text = f"أضف واجب: {desc}"

    session_id = f"siri-{uuid.uuid4().hex}"
    history = [{"role": "user", "content": prompt_text}]
    trace = {}

    await run_specialist(
        specialist=specialist,
        session_id=session_id,
        history=history,
        llm=app.state.llm,
        audit=app.state.audit,
        emit=emit,
        trace=trace,
        llm_semaphore=app.state.llm_semaphore,
        tool_choice={"type": "tool", "name": "prepare_task"},
    )

    if not captured_task:
        if not app.state.settings.ameen_mock:
            log.error("Real Anthropic run failed to produce prepare_task tool call")
            raise HTTPException(status_code=500, detail="Failed to prepare task from Anthropic")

        # Mock/Offline test fallback ONLY
        captured_task = {
            "title": desc or "واجب مدرسة",
            "focus_duration": 20,
            "break_duration": 5,
            "validity_days": 1,
            "requires_code": False,
            "subtasks": [
                {"title": "حل الجزء الأول من الواجب", "duration": 7},
                {"title": "حل الجزء الثاني من الواجب", "duration": 7},
                {"title": "إكمال باقي الواجب ومراجعته", "duration": 6}
            ]
        }

    return {
        "title": captured_task.get("title", desc or "واجب مدرسة"),
        "focus_duration": captured_task.get("focus_duration", 20),
        "break_duration": captured_task.get("break_duration", 5),
        "validity_days": captured_task.get("validity_days", 1),
        "requires_code": captured_task.get("requires_code", False),
        "subtasks": [
            {
                "title": sub.get("title", ""),
                "duration": sub.get("duration", 5)
            }
            for sub in captured_task.get("subtasks", [])
        ]
    }

