"""Conversation routing for the Supernova parent-task assistant."""

from __future__ import annotations

import asyncio
import logging
import re
import time

from agent.agent import run_specialist
from agent.metrics import metrics
from agent.prompts import CLASSIFIER_PROMPT, GREETING_REPLY
from agent.specialists import SPECIALISTS

log = logging.getLogger("supernova.orchestrator")

# Specific intents are checked before the general task intent.  This keeps an
# edit such as "خلّ الاستراحة 5 دقائق" in the existing draft instead of
# accidentally starting a new task.
_INTENT_RULES: list[tuple[str, re.Pattern[str]]] = [
    ("confirmation", re.compile(r"^\s*(?:نعم|ايوه|أيوه|أكيد|اكيد|موافق|موافقة|أوافق|اوافق|أضفها|اضفها|أضف المهمة|اضف المهمة|نعم[،, ]+أضفها|نعم[،, ]+اضفها|تمام[،, ]+أضفها|تمام[،, ]+اضفها|yes|sure|add (?:it|the task))\s*[!.،؟?]*$", re.I)),
    ("routine", re.compile(r"روتين|صباحي|قبل النوم|الاستعداد للنوم|روتين المدرسة", re.I)),
    ("focus", re.compile(r"تركيز|يتشتت|تشتت|جلسة", re.I)),
    ("break", re.compile(r"استراحة|راحه|راحة", re.I)),
    ("edit", re.compile(r"غي[ّيرر]|عدل|عدّل|خل[ّيه]|أضف خطوة|اضف خطوة|احذف|بدل|بدّ?ل", re.I)),
    ("task", re.compile(r"مهمة|مهمه|واجب|ذاكر|مذاكرة|اقرأ|قراءة|حل |رتب|رتّب|نظف|نظّف|study|homework|task", re.I)),
]

_GREETING_RE = re.compile(
    r"^\s*(?:مرحبا|مرحباً|هلا|أهلا|أهلاً|اهلين|السلام عليكم|صباح الخير|مساء الخير|شكرا|شكراً|hi|hello|hey|thanks|thank you)[\s!.،؟?]*$",
    re.I,
)
_CLASSIFIER_BLOCKS = [{"type": "text", "text": CLASSIFIER_PROMPT}]
_ROUTE_TARGETS = (*SPECIALISTS, "smalltalk")


async def _silent(_: str) -> None:
    return None


class OrchestratorAgent:
    """Owns one parent conversation and emits WS events for each turn."""

    def __init__(self, *, llm, store, audit, llm_semaphore: asyncio.Semaphore | None = None) -> None:
        self._llm = llm
        self._store = store
        self._audit = audit
        self._sem = llm_semaphore

    @staticmethod
    def _route(text: str, session: dict) -> tuple[str | None, dict]:
        value = text.strip().lower()
        if _GREETING_RE.match(value):
            return "smalltalk", {"method": "keyword", "matched": "greeting"}
        for name, pattern in _INTENT_RULES:
            if pattern.search(value):
                return name, {"method": "keyword", "matched": name}
        sticky = session.get("active_specialist")
        if sticky in SPECIALISTS:
            return sticky, {"method": "sticky", "matched": sticky}
        return None, {"method": "unmatched"}

    async def _classify(self, text: str) -> str | None:
        try:
            answer = await self._llm.complete(
                _CLASSIFIER_BLOCKS, [], [{"role": "user", "content": text}], _silent
            )
        except Exception:  # noqa: BLE001
            log.exception("intent classification failed")
            return None
        reply = " ".join(
            block.get("text", "") for block in answer.get("content", [])
            if isinstance(block, dict) and block.get("type") == "text"
        ).lower()
        return next((target for target in _ROUTE_TARGETS if target in reply[:60]), None)

    async def run_turn(self, *, session_id: str, user_text: str, emit) -> None:
        started = time.perf_counter()
        metrics.inc("requests_total")
        session = await self._store.get(session_id) or {"messages": []}
        history: list[dict] = session["messages"]

        target, decision = self._route(user_text, session)
        if target is None:
            target = await self._classify(user_text) or "smalltalk"
            decision = {"method": "llm_classifier", "matched": target}
        metrics.inc(f"route_{target}_total")

        if target == "smalltalk":
            history.extend([
                {"role": "user", "content": user_text},
                {"role": "assistant", "content": GREETING_REPLY},
            ])
            await emit({"type": "token", "text": GREETING_REPLY})
            await self._store.put(session_id, session)
            metrics.record_turn_ms((time.perf_counter() - started) * 1000)
            await emit({"type": "done"})
            return

        # Confirmation is a turn state, not a specialist. Continue through the
        # specialist that prepared the draft so it retains the appropriate
        # instructions and the add_task tool.
        confirmed = target == "confirmation"
        if confirmed:
            target = session.get("active_specialist") if session.get("active_specialist") in SPECIALISTS else "task"
            decision["specialist"] = target
        session["active_specialist"] = target
        history.append({"role": "user", "content": user_text})
        trace = {"router": {**decision, "specialist": target}, "steps": []}
        ok = await run_specialist(
            specialist=SPECIALISTS[target], session_id=session_id, history=history,
            llm=self._llm, audit=self._audit, emit=emit, trace=trace,
            llm_semaphore=self._sem, task_confirmed=confirmed,
        )
        if not ok:
            # Remove every message from this failed turn, not merely the last
            # tool result. This avoids a dangling tool_use in the next request.
            while history and history[-1] is not None:
                message = history.pop()
                if message.get("role") == "user" and message.get("content") == user_text:
                    break
        await self._store.put(session_id, session)
        metrics.record_turn_ms((time.perf_counter() - started) * 1000)
        if ok:
            await emit({"type": "done"})
