"""LLM adapters plus a deterministic offline assistant for local demos."""

from __future__ import annotations

import json
import logging
import re
import uuid

log = logging.getLogger("supernova.llm")


class AnthropicLLM:
    def __init__(self, api_key: str, model: str) -> None:
        from anthropic import AsyncAnthropic
        self._client = AsyncAnthropic(api_key=api_key)
        self._model = model

    async def complete(self, system, tools, messages, on_text) -> dict:
        async with self._client.messages.stream(
            model=self._model, max_tokens=1500, system=system, tools=tools, messages=messages,
        ) as stream:
            async for text in stream.text_stream:
                await on_text(text)
            final = await stream.get_final_message()
        content = []
        for block in final.content:
            if block.type == "text":
                content.append({"type": "text", "text": block.text})
            elif block.type == "tool_use":
                content.append({"type": "tool_use", "id": block.id, "name": block.name, "input": block.input})
        return {"role": "assistant", "content": content, "stop_reason": final.stop_reason}


class OpenRouterLLM:
    """Small OpenAI-compatible adapter used when AMEEN_PROVIDER=openrouter."""
    URL = "https://openrouter.ai/api/v1/chat/completions"

    def __init__(self, api_key: str, model: str) -> None:
        import httpx
        self._client = httpx.AsyncClient(timeout=90, headers={"Authorization": f"Bearer {api_key}"})
        self._model = model

    async def complete(self, system, tools, messages, on_text) -> dict:
        system_text = "\n\n".join(b["text"] for b in system if b.get("type") == "text")
        converted = [{"role": "system", "content": system_text}]
        for message in messages:
            content = message.get("content")
            if isinstance(content, str):
                converted.append({"role": message["role"], "content": content})
            elif message["role"] == "assistant":
                calls = [{"id": b["id"], "type": "function", "function": {"name": b["name"], "arguments": json.dumps(b.get("input", {}), ensure_ascii=False)}} for b in content if b.get("type") == "tool_use"]
                converted.append({"role": "assistant", "content": " ".join(b.get("text", "") for b in content if b.get("type") == "text") or None, **({"tool_calls": calls} if calls else {})})
            else:
                converted.extend({"role": "tool", "tool_call_id": b["tool_use_id"], "content": b.get("content", "")} for b in content if b.get("type") == "tool_result")
        payload = {"model": self._model, "max_tokens": 1500, "messages": converted}
        if tools:
            payload["tools"] = [{"type": "function", "function": {"name": tool["name"], "description": tool.get("description", ""), "parameters": tool["input_schema"]}} for tool in tools]
        response = await self._client.post(self.URL, json=payload)
        response.raise_for_status()
        message = response.json()["choices"][0]["message"]
        content = []
        if text := message.get("content"):
            await on_text(text)
            content.append({"type": "text", "text": text})
        content.extend({"type": "tool_use", "id": call["id"], "name": call["function"]["name"], "input": json.loads(call["function"]["arguments"])} for call in message.get("tool_calls", []))
        return {"role": "assistant", "content": content, "stop_reason": "tool_use" if message.get("tool_calls") else "end_turn"}


def _tool_use(task: dict) -> dict:
    return {"type": "tool_use", "id": f"toolu_{uuid.uuid4().hex[:12]}", "name": "add_task", "input": task}


class MockLLM:
    """Offline demo flow: draft from a clear task, with sensible defaults."""
    _number = re.compile(r"(\d+)")

    async def complete(self, system, tools, messages, on_text) -> dict:
        last = messages[-1]
        if self._is_tool_result(last):
            result = json.loads(last["content"][0]["content"])
            text = "تمت إضافة المهمة إلى قائمة مهام الطفل بنجاح ⭐" if result.get("success") else "لم أتمكن من إضافة المهمة. راجع البيانات وحاول مرة أخرى."
            await on_text(text)
            return {"role": "assistant", "content": [{"type": "text", "text": text}], "stop_reason": "end_turn"}
        user_text = self._last_text(messages)
        details, missing = self._details(messages)
        if self._is_confirmation(user_text) and not missing:
            return {"role": "assistant", "content": [_tool_use(details)], "stop_reason": "tool_use"}
        if self._is_confirmation(user_text):
            text = "لا أستطيع إضافة المهمة قبل فهم نطاقها ومدتها. " + self._question(missing)
            await on_text(text)
            return {"role": "assistant", "content": [{"type": "text", "text": text}], "stop_reason": "end_turn"}
        if missing:
            text = self._question(missing)
            await on_text(text)
            return {"role": "assistant", "content": [{"type": "text", "text": text}], "stop_reason": "end_turn"}
        text = self._summary(details)
        await on_text(text)
        return {"role": "assistant", "content": [{"type": "text", "text": text}], "stop_reason": "end_turn"}

    @staticmethod
    def _question(field: str | None) -> str:
        questions = {
            "title": "ما المهمة التي تريد إعدادها؟",
            "scope": "ما الجزء المحدد الذي تريد تقسيمه؟ مثال: الأسئلة 1 إلى 10 أو الصفحات 10 إلى 15.",
            "focus_duration": "كم المدة الكلية المتاحة لهذه المهمة بالدقائق؟",
            "clarification": "فهمت المهمة. لكي أقسمها بدقة، ما الجزء المطلوب إنجازه (صفحات أو أسئلة) وكم المدة المتاحة بالدقائق؟",
        }
        return "حتى أقسم المهمة بشكل مناسب، " + questions[field or "title"]

    def _details(self, messages: list[dict]) -> tuple[dict, str | None]:
        # A confirmation completes the previous task. Never let its scope,
        # duration or subject leak into the next task in the same chat.
        search_messages = messages[:-1] if self._is_confirmation(self._last_text(messages)) else messages
        last_confirmation = max(
            (index for index, message in enumerate(search_messages)
             if message.get("role") == "user"
             and isinstance(message.get("content"), str)
             and self._is_confirmation(message["content"])),
            default=-1,
        )
        active_messages = messages[last_confirmation + 1:]
        texts = [message["content"].strip() for message in active_messages if message.get("role") == "user" and isinstance(message.get("content"), str) and not self._is_confirmation(message["content"])]
        if not texts:
            return {}, "title"
        source = " ".join(texts)
        if self._is_split_request(texts[0]):
            return {}, "title"
        title = self._title(texts, texts[0])
        scope = self._scope(source) or "المهمة كاملة"
        normalised = source.translate(str.maketrans("٠١٢٣٤٥٦٧٨٩", "0123456789"))
        # Accept natural short answers such as "مدة 30" as well as
        # "لمدة 30 دقيقة". The previous matcher required the word دقيقة,
        # which made a parent answer correctly but receive the same question.
        duration_matches = list(re.finditer(
            r"(?:(?:ال)?مدة|لمدة|وقت|زمن)\s*(?:إلى|الى)?\s*(\d+)|(\d+)\s*(?:دقيقة|دقائق|minutes?)",
            normalised,
            re.I,
        ))
        duration_match = duration_matches[-1] if duration_matches else None
        if self._is_generic_request(source):
            return {}, "title"
        # For a clear task, do not interrogate the parent for every setting.
        # A 20-minute plan is an editable, ADHD-friendly starting point.
        duration = int(duration_match.group(1) or duration_match.group(2)) if duration_match else 20
        subtask_count = self._subtask_count(source)
        subtasks = self._subtasks(title, scope, duration, subtask_count)
        return {
            "title": title,
            "scope": scope,
            "focus_duration": duration,
            "break_duration": 5,
            "validity_days": 1,
            "subtasks": subtasks,
            "requires_code": False,
        }, None

    @staticmethod
    def _title(texts: list[str], fallback: str) -> str:
        # Inspect newest messages first so "غيّرها إلى واجب رياضيات" updates
        # a previous science draft instead of preserving its old subject.
        source = " ".join(texts)
        source_lower = source.lower()
        latest_subject = next((text for text in reversed(texts) if any(word in text for word in (
            "رياض", "جبر", "حساب", "معادلات", "علوم", "علم", "تجربة", "عربي", "لغة", "انجليزي", "إنجليزي", "قراءة", "كتاب", "قصة",
        ))), source)
        if any(word in latest_subject for word in ("رياض", "جبر", "حساب", "معادلات")):
            return "واجب الرياضيات"
        if any(word in latest_subject for word in ("علوم", "علم", "تجربة", "كائنات")):
            return "مذاكرة العلوم"
        if any(word in latest_subject for word in ("عربي", "لغة", "إملاء", "نحو")):
            return "واجب اللغة العربية"
        if any(word in latest_subject for word in ("انجليزي", "إنجليزي", "english", "vocabulary")) or "english" in source_lower:
            return "واجب اللغة الإنجليزية"
        if any(word in latest_subject for word in ("قراءة", "اقرأ", "كتاب", "قصة")):
            return "مهمة القراءة"
        if any(word in source for word in ("مذاكرة", "دراسة", "واجب", "حل")):
            return "مهمة دراسية"
        return fallback

    @staticmethod
    def _scope(text: str) -> str | None:
        # Parents commonly use Arabic-Indic digits and phrases such as
        # "حل سؤال ١ من صفحة ١٢ إلى سؤال ١٥". Normalise first, then accept
        # the flexible wording rather than requiring one exact sentence.
        normalised = text.translate(str.maketrans("٠١٢٣٤٥٦٧٨٩", "0123456789"))
        matches = list(re.finditer(
            r"(?:الأسئلة|الاسئلة|اسئلة|سؤال|السؤال|سوال|الصفحات|صفحات|صفحة)\s*(?:من\s*)?(\d+).*?"
            r"(?:إلى|الى|حتى|[-–])\s*(?:(?:الأسئلة|الاسئلة|اسئلة|سؤال|السؤال|سوال|الصفحات|صفحات|صفحة)\s*)?(\d+)",
            normalised,
        ))
        match = matches[-1] if matches else None
        return match.group(0) if match else None

    @staticmethod
    def _subtask_count(text: str) -> int:
        normalised = text.translate(str.maketrans("٠١٢٣٤٥٦٧٨٩", "0123456789"))
        if any(term in normalised for term in ("قسمها أكثر", "قسمها اكثر", "جزئها أكثر", "جزئها اكثر", "زِد المهام")):
            return 5
        if any(term in normalised for term in ("قسمها أقل", "قسمها اقل", "قلل المهام")):
            return 2
        match = re.search(r"(?:قسمها|جزئها|مهام فرعية)\s*(?:إلى|الى)?\s*(\d+)", normalised)
        return max(2, min(int(match.group(1)), 8)) if match else 3

    @staticmethod
    def _subtasks(title: str, scope: str, total: int, count: int) -> list[dict]:
        numbers = [int(value) for value in re.findall(r"\d+", scope)]
        if len(numbers) < 2:
            labels = [
                f"الجزء الأول من {title}",
                f"الجزء الثاني من {title}",
                f"إكمال الجزء الأخير من {title}",
            ][:count]
            base, remainder = divmod(total, len(labels))
            return [
                {"title": label, "duration": base + (1 if index < remainder else 0)}
                for index, label in enumerate(labels)
            ]
        start, end = numbers[0], numbers[-1]
        width = max(1, (end - start + 1 + count - 1) // count)
        ranges = []
        current = start
        while current <= end:
            finish = min(end, current + width - 1)
            label = "حل الأسئلة" if any(word in scope for word in ("سؤال", "سوال", "اسئلة", "الأسئلة")) else "مذاكرة الصفحات"
            ranges.append(f"{label} {current}–{finish}")
            current = finish + 1
        base, remainder = divmod(total, len(ranges))
        return [{"title": item, "duration": base + (1 if index < remainder else 0)} for index, item in enumerate(ranges)]

    @staticmethod
    def _is_tool_result(message: dict) -> bool:
        return isinstance(message.get("content"), list) and bool(message["content"]) and message["content"][0].get("type") == "tool_result"

    @staticmethod
    def _is_confirmation(text: str) -> bool:
        return bool(re.fullmatch(r"\s*(نعم|ايوه|أيوه|أكيد|اكيد|موافق|موافقة|أوافق|اوافق|أضفها|اضفها|أضف المهمة|اضف المهمة|نعم[،, ]+أضفها|نعم[،, ]+اضفها|تمام[،, ]+أضفها|تمام[،, ]+اضفها|yes|sure|add (it|the task))\s*[!.،؟?]*", text, re.I))

    @staticmethod
    def _last_text(messages: list[dict]) -> str:
        for message in reversed(messages):
            if message.get("role") == "user" and isinstance(message.get("content"), str):
                return message["content"]
        return ""

    @staticmethod
    def _is_split_request(text: str) -> bool:
        return any(value in text for value in ("قسمها", "قسّمها", "قسم المهمة", "مهام صغيرة", "مهام فرعية"))

    @staticmethod
    def _is_generic_request(text: str) -> bool:
        cleaned = re.sub(r"[\s!؟?.،]+", " ", text.strip().lower())
        generic = {
            "أريد إنشاء مهمة", "اريد انشاء مهمة", "أريد اضافة مهمة", "اريد اضافة مهمة",
            "أضف مهمة", "اضف مهمة", "مهمة", "مهمه", "ساعدني في تنظيم واجب",
        }
        return cleaned in generic

    @staticmethod
    def _summary(task: dict) -> str:
        subtasks = "\n".join(f"{index + 1}. {item['title']} — {item['duration']} دقائق" for index, item in enumerate(task["subtasks"]))
        return f"هذا اقتراح للمهمة:\n• {task['title']}\n• المدة الإجمالية: {task['focus_duration']} دقيقة\n• استراحة: {task['break_duration']} دقائق (اقتراح)\n• الصلاحية: يوم واحد (اقتراح)\nالمهام الفرعية:\n{subtasks}\nهل تريد مني إضافة هذه المهمة إلى قائمة مهام الطفل؟"


def make_llm(settings):
    provider = settings.ameen_provider.lower()
    if settings.ameen_mock or provider == "mock":
        return MockLLM()
    if provider == "openrouter" and settings.openrouter_api_key:
        return OpenRouterLLM(settings.openrouter_api_key, settings.ameen_model)
    if settings.anthropic_api_key:
        return AnthropicLLM(settings.anthropic_api_key, settings.ameen_model)
    log.warning("No AI provider key configured — using offline MockLLM")
    return MockLLM()
