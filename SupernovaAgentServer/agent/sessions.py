"""Session persistence + rate limiting.

Sessions live in Redis (key ameen:session:{id}, JSON, TTL 24h) so the service
is stateless and can run under multiple uvicorn workers. AMEEN_MOCK=1 (or an
unreachable Redis at startup) falls back to an in-memory store so dev/test runs
need no infrastructure.
"""

from __future__ import annotations

import json
import logging
import time

log = logging.getLogger("ameen.sessions")

SESSION_KEY = "ameen:session:{id}"
RATE_KEY = "ameen:rate:{id}"


class MemorySessionStore:
    """Single-process fallback. Same interface as RedisSessionStore."""

    def __init__(self, ttl_seconds: int = 86_400) -> None:
        self.ttl = ttl_seconds
        self._data: dict[str, tuple[float, dict]] = {}
        self._rate: dict[str, tuple[float, int]] = {}

    async def get(self, session_id: str) -> dict | None:
        row = self._data.get(session_id)
        if row is None:
            return None
        expires, session = row
        if time.time() > expires:
            del self._data[session_id]
            return None
        return session

    async def put(self, session_id: str, session: dict) -> None:
        self._data[session_id] = (time.time() + self.ttl, session)

    async def check_rate_limit(self, session_id: str, limit: int, window_s: int = 60) -> bool:
        """True if this message is allowed."""
        now = time.time()
        reset_at, count = self._rate.get(session_id, (now + window_s, 0))
        if now > reset_at:
            reset_at, count = now + window_s, 0
        count += 1
        self._rate[session_id] = (reset_at, count)
        return count <= limit

    async def ping(self) -> bool:
        return True


class RedisSessionStore:
    def __init__(self, redis_url: str, ttl_seconds: int = 86_400) -> None:
        import redis.asyncio as aioredis

        self.ttl = ttl_seconds
        self._redis = aioredis.from_url(redis_url, decode_responses=True)

    async def get(self, session_id: str) -> dict | None:
        raw = await self._redis.get(SESSION_KEY.format(id=session_id))
        return json.loads(raw) if raw else None

    async def put(self, session_id: str, session: dict) -> None:
        await self._redis.set(
            SESSION_KEY.format(id=session_id),
            json.dumps(session, ensure_ascii=False),
            ex=self.ttl,
        )

    async def check_rate_limit(self, session_id: str, limit: int, window_s: int = 60) -> bool:
        key = RATE_KEY.format(id=session_id)
        count = await self._redis.incr(key)
        if count == 1:
            await self._redis.expire(key, window_s)
        return count <= limit

    async def ping(self) -> bool:
        try:
            return bool(await self._redis.ping())
        except Exception:  # noqa: BLE001
            return False


async def make_store(settings) -> MemorySessionStore | RedisSessionStore:
    if settings.ameen_mock:
        log.info("AMEEN_MOCK=1 — using in-memory session store")
        return MemorySessionStore(settings.session_ttl_seconds)
    store = RedisSessionStore(settings.redis_url, settings.session_ttl_seconds)
    if await store.ping():
        return store
    log.warning("Redis unreachable at %s — falling back to in-memory sessions", settings.redis_url)
    return MemorySessionStore(settings.session_ttl_seconds)
