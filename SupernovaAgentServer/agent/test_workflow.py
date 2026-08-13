"""Offline end-to-end checks for the Supernova parent task flow."""

from __future__ import annotations

import asyncio
import os
import sys
from pathlib import Path

os.environ["AMEEN_MOCK"] = "1"
sys.path.insert(0, str(Path(__file__).resolve().parent.parent))

from agent.audit import MemoryAudit  # noqa: E402
from agent.llm import MockLLM  # noqa: E402
from agent.orchestrator import OrchestratorAgent  # noqa: E402
from agent.sessions import MemorySessionStore  # noqa: E402
from agent.tools import TASKS_BY_SESSION  # noqa: E402


async def send(agent: OrchestratorAgent, session_id: str, text: str) -> list[dict]:
    events: list[dict] = []

    async def emit(event: dict) -> None:
        events.append(event)

    await agent.run_turn(session_id=session_id, user_text=text, emit=emit)
    return events


async def main() -> int:
    TASKS_BY_SESSION.clear()
    store = MemorySessionStore()
    agent = OrchestratorAgent(llm=MockLLM(), store=store, audit=MemoryAudit())
    session_id = "family-a"

    draft = await send(agent, session_id, "أبي طفلي يذاكر الرياضيات")
    draft_text = "".join(event.get("text", "") for event in draft if event["type"] == "token")
    assert "واجب الرياضيات" in draft_text and "المدة الإجمالية: 20 دقيقة" in draft_text

    precise = await send(agent, session_id, "الأسئلة من ١ إلى ١٥ مدة 20")
    precise_summary = "".join(event.get("text", "") for event in precise if event["type"] == "token")
    assert "حل الأسئلة 1–5" in precise_summary

    spelling_variant = await send(agent, "family-c", "واجب الرياضيات: سوال ١-٢١ في 30 دقيقة")
    spelling_summary = "".join(event.get("text", "") for event in spelling_variant if event["type"] == "token")
    assert "حل الأسئلة 1–7" in spelling_summary
    assert not TASKS_BY_SESSION.get(session_id), "The agent must not create an assumed task."

    approval = await send(agent, session_id, "نعم")
    task_events = [event for event in approval if event["type"] == "task_added"]
    assert len(task_events) == 1
    assert task_events[0]["task"]["subtasks"][0]["title"] == "حل الأسئلة 1–5"

    # New task after confirmation must not inherit the previous math range.
    science_question = await send(agent, session_id, "أضيف مهمة مذاكرة واجب العلوم من صفحة 1 إلى صفحة 50")
    science_question_text = "".join(event.get("text", "") for event in science_question if event["type"] == "token")
    assert "مذاكرة العلوم" in science_question_text and "المدة الإجمالية: 20 دقيقة" in science_question_text
    science_draft = await send(agent, session_id, "مدة 30")
    science_text = "".join(event.get("text", "") for event in science_draft if event["type"] == "token")
    assert "مذاكرة العلوم" in science_text and "مذاكرة الصفحات 1–17" in science_text

    edited = await send(agent, session_id, "قسمها أكثر وغير المدة إلى 50")
    edited_text = "".join(event.get("text", "") for event in edited if event["type"] == "token")
    assert "المدة الإجمالية: 50 دقيقة" in edited_text
    assert "مذاكرة الصفحات 1–10" in edited_text
    print("Supernova checks passed (new tasks reset context and keep their own subject/range).")
    return 0


if __name__ == "__main__":
    raise SystemExit(asyncio.run(main()))
