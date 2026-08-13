"""Routing and server-side confirmation guard checks."""

from __future__ import annotations

import asyncio
import os
import sys
from pathlib import Path

os.environ["AMEEN_MOCK"] = "1"
sys.path.insert(0, str(Path(__file__).resolve().parent.parent))

from agent.agent import _execute_tool  # noqa: E402
from agent.orchestrator import OrchestratorAgent  # noqa: E402
from agent.specialists import SPECIALISTS  # noqa: E402


async def main() -> int:
    cases = {
        "أنشئ مهمة واجبات": "task",
        "أبي روتين صباحي": "routine",
        "خلي الاستراحة 5 دقائق": "break",
        "طفلي يتشتت بسرعة": "focus",
        "نعم": "confirmation",
        "أوافق": "confirmation",
        "نعم أضفها": "confirmation",
        "مرحبا": "smalltalk",
    }
    for text, expected in cases.items():
        target, _ = OrchestratorAgent._route(text, {})
        assert target == expected, f"{text!r}: expected {expected}, got {target}"

    # Tool use forged by a model without a new explicit confirmation is denied
    # by the server-side handler, not merely by prompt wording.
    task = {
        "title": "قراءة", "child_age": 8, "scope": "الصفحات 1-3", "focus_duration": 20, "break_duration": 5,
        "validity_days": 1, "subtasks": [{"title": "اقرأ الصفحة 1", "duration": 20}], "requires_code": False,
    }
    _, result, envelope = await _execute_tool(
        {"type": "tool_use", "id": "forged", "name": "add_task", "input": task},
        {"session_id": "guard", "task_confirmed": False}, SPECIALISTS["task"],
    )
    assert envelope is None
    assert result["error"]["code"] == "confirmation_required"
    print("Supernova routing and confirmation-guard checks passed.")
    return 0


if __name__ == "__main__":
    raise SystemExit(asyncio.run(main()))
