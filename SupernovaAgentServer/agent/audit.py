"""Audit trail of prepared operations + risk decisions + traces (PostgreSQL).

Banking compliance requires every prepared operation to be recorded; PDPL
forbids persisting raw conversation content — audit rows carry operation
metadata and the risk decision only, never chat text.

Writes are fire-and-forget (asyncio.create_task) so they add no latency to the
user-facing reply. AMEEN_MOCK=1 / missing DATABASE_URL uses an in-memory sink.
"""

from __future__ import annotations

import asyncio
import json
import logging
from datetime import datetime, timezone

log = logging.getLogger("ameen.audit")

DDL = """
CREATE TABLE IF NOT EXISTS ameen_audit (
    id BIGSERIAL PRIMARY KEY,
    session_id TEXT NOT NULL,
    operation TEXT NOT NULL,
    envelope_type TEXT NOT NULL,
    risk_action TEXT NOT NULL,
    risk_tier TEXT NOT NULL,
    fraud_probability DOUBLE PRECISION NOT NULL,
    risk_reasons JSONB NOT NULL,
    payload_meta JSONB NOT NULL,
    trace JSONB NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS idx_ameen_audit_session ON ameen_audit (session_id, created_at);
"""


def make_entry(session_id: str, envelope: dict, trace: dict) -> dict:
    payload = envelope.get("payload", {})
    # metadata only — amounts/types, no free-text note, no chat content
    payload_meta = {
        k: v for k, v in payload.items() if k not in ("note",) and not isinstance(v, dict)
    }
    risk = envelope["risk"]
    return {
        "session_id": session_id,
        "operation": envelope["operation"],
        "envelope_type": envelope["type"],
        "risk_action": risk["action"],
        "risk_tier": risk["tier"],
        "fraud_probability": float(risk["fraud_probability"]),
        "risk_reasons": risk["reasons"],
        "payload_meta": payload_meta,
        "trace": trace,
        "created_at": datetime.now(timezone.utc).isoformat(),
    }


class MemoryAudit:
    def __init__(self) -> None:
        self.entries: list[dict] = []

    async def record(self, entry: dict) -> None:
        self.entries.append(entry)

    async def ping(self) -> bool:
        return True

    async def close(self) -> None:
        return None


class PostgresAudit:
    def __init__(self, pool) -> None:
        self._pool = pool

    @classmethod
    async def create(cls, database_url: str) -> "PostgresAudit":
        import asyncpg

        pool = await asyncpg.create_pool(database_url, min_size=1, max_size=10)
        async with pool.acquire() as conn:
            await conn.execute(DDL)
        return cls(pool)

    async def record(self, entry: dict) -> None:
        async with self._pool.acquire() as conn:
            await conn.execute(
                """
                INSERT INTO ameen_audit (session_id, operation, envelope_type, risk_action,
                    risk_tier, fraud_probability, risk_reasons, payload_meta, trace, created_at)
                VALUES ($1, $2, $3, $4, $5, $6, $7::jsonb, $8::jsonb, $9::jsonb, $10::timestamptz)
                """,
                entry["session_id"],
                entry["operation"],
                entry["envelope_type"],
                entry["risk_action"],
                entry["risk_tier"],
                entry["fraud_probability"],
                json.dumps(entry["risk_reasons"]),
                json.dumps(entry["payload_meta"], ensure_ascii=False),
                json.dumps(entry["trace"], ensure_ascii=False),
                entry["created_at"],
            )

    async def ping(self) -> bool:
        try:
            async with self._pool.acquire() as conn:
                await conn.fetchval("SELECT 1")
            return True
        except Exception:  # noqa: BLE001
            return False

    async def close(self) -> None:
        await self._pool.close()


async def make_audit(settings) -> MemoryAudit | PostgresAudit:
    if settings.ameen_mock or not settings.database_url:
        if not settings.ameen_mock:
            log.warning("DATABASE_URL not set — audit entries kept in memory only")
        return MemoryAudit()
    try:
        return await PostgresAudit.create(settings.database_url)
    except Exception as exc:  # noqa: BLE001
        log.warning("PostgreSQL unreachable (%s) — audit entries kept in memory only", exc)
        return MemoryAudit()


def fire_and_forget(coro) -> None:
    """Audit must never add latency or crash the reply path."""

    task = asyncio.create_task(coro)

    def _log_failure(t: asyncio.Task) -> None:
        if not t.cancelled() and t.exception() is not None:
            log.error("audit write failed: %s", t.exception())

    task.add_done_callback(_log_failure)
