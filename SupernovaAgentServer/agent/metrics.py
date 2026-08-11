"""In-process counters + latency percentiles, served at /metrics."""

from __future__ import annotations

from collections import Counter, deque


class Metrics:
    def __init__(self) -> None:
        self.counters: Counter[str] = Counter()
        self.tool_calls: Counter[str] = Counter()
        self.risk_actions: Counter[str] = Counter()
        self._turn_ms: deque[float] = deque(maxlen=5000)

    def inc(self, name: str, n: int = 1) -> None:
        self.counters[name] += n

    def record_tool(self, tool_name: str) -> None:
        self.tool_calls[tool_name] += 1

    def record_risk(self, action: str) -> None:
        self.risk_actions[action] += 1

    def record_turn_ms(self, ms: float) -> None:
        self._turn_ms.append(ms)

    @staticmethod
    def _percentile(values: list[float], pct: float) -> float:
        if not values:
            return 0.0
        values = sorted(values)
        idx = min(len(values) - 1, int(round(pct / 100 * (len(values) - 1))))
        return values[idx]

    def snapshot(self) -> dict:
        turns = list(self._turn_ms)
        return {
            "counters": dict(self.counters),
            "tool_calls": dict(self.tool_calls),
            "risk_actions": dict(self.risk_actions),
            "latency_ms": {
                "count": len(turns),
                "p50": round(self._percentile(turns, 50), 2),
                "p95": round(self._percentile(turns, 95), 2),
                "max": round(max(turns), 2) if turns else 0.0,
            },
        }


metrics = Metrics()
