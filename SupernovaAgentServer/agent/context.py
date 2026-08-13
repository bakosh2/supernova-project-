"""Context-window management: sliding window + compression + tool_result caps.

Full history lives in the session store (Redis, TTL 24h). The message list sent
to the API is a VIEW built here — nothing is lost for audit when we compress.

Rules honoured:
- last N turns stay verbatim;
- over the token budget, the oldest turns collapse into ONE summary message
  ("سياق سابق: ...") that preserves committed facts;
- a turn boundary is a plain-text user message, so an un-responded
  tool_use/tool_result pair is never split;
- every tool_result is capped (~2KB) before it ever enters history.
"""

from __future__ import annotations

import json


def estimate_tokens(obj) -> int:
    """~4 chars per token."""
    if isinstance(obj, str):
        return len(obj) // 4
    return len(json.dumps(obj, ensure_ascii=False)) // 4


# ------------------------------------------------------------- tool results


def cap_tool_result(result: dict, max_bytes: int = 2048) -> dict:
    """Truncate long arrays instead of dumping everything into context."""
    if _size(result) <= max_bytes:
        return result
    capped = json.loads(json.dumps(result, ensure_ascii=False))
    for _ in range(64):
        (parent, key), items = _longest_list(capped)
        if parent is None or len(items) <= 1:
            break
        keep = max(1, len(items) // 2)
        dropped = _count_items(items) - keep
        parent[key] = items[:keep] + [f"...{dropped} more, ask to filter"]
        if _size(capped) <= max_bytes:
            return capped
    # No list to shrink (or still too big): hard-truncate the serialized form.
    text = json.dumps(result, ensure_ascii=False)[: max_bytes - 128]
    return {"truncated": True, "preview": text + " ...truncated, ask to filter"}


def _size(obj) -> int:
    return len(json.dumps(obj, ensure_ascii=False).encode("utf-8"))


def _count_items(items: list) -> int:
    # ignore a previously-added "...N more" marker when counting real items
    return sum(1 for it in items if not (isinstance(it, str) and it.startswith("...")))


def _longest_list(obj):
    """Return ((parent, key), largest_list) anywhere in the structure, or ((None, None), [])."""
    candidates = []

    def walk(node, parent, key):
        if isinstance(node, list):
            if parent is not None:
                candidates.append(((parent, key), node))
            for i, v in enumerate(node):
                walk(v, node, i)
        elif isinstance(node, dict):
            for k, v in node.items():
                walk(v, node, k)

    walk(obj, None, None)
    if not candidates:
        return (None, None), []
    return max(candidates, key=lambda c: _size(c[1]))


# ---------------------------------------------------------------- window


def _is_turn_start(msg: dict) -> bool:
    """A plain-text user message starts a turn; tool_result user messages don't."""
    if msg.get("role") != "user":
        return False
    content = msg.get("content")
    if isinstance(content, str):
        return True
    return not any(
        isinstance(b, dict) and b.get("type") == "tool_result" for b in content or []
    )


def _extract_facts(messages: list[dict]) -> list[str]:
    """Committed facts worth surviving compression."""
    facts: list[str] = []
    for msg in messages:
        content = msg.get("content")
        if not isinstance(content, list):
            continue
        for block in content:
            if not isinstance(block, dict) or block.get("type") != "tool_result":
                continue
            raw = block.get("content")
            if not isinstance(raw, str):
                continue
            try:
                result = json.loads(raw)
            except (ValueError, TypeError):
                continue
            if not isinstance(result, dict):
                continue
            amount = result.get("amount")
            amount_part = f" بمبلغ {amount}" if amount is not None else ""
            if result.get("declined"):
                risk = result.get("risk", {})
                facts.append(
                    f"عملية {result.get('operation', '?')}{amount_part} رُفضت نهائياً من بوابة المخاطر "
                    f"(الأسباب: {', '.join(risk.get('reasons', []) or ['غير محدد'])})"
                )
            elif result.get("prepared"):
                facts.append(
                    f"عملية {result.get('operation', '?')}{amount_part} جُهزت وأُرسلت لمراجعة المستخدم "
                    f"({result.get('envelope_type')})"
                )
    return facts


def build_window(
    history: list[dict],
    token_budget: int = 12_000,
    verbatim_turns: int = 20,
) -> tuple[list[dict], bool]:
    """Return (window_messages, compressed)."""
    turn_starts = [i for i, m in enumerate(history) if _is_turn_start(m)]

    if estimate_tokens(history) <= token_budget and len(turn_starts) <= verbatim_turns:
        return list(history), False

    # Keep the most recent turns verbatim; never fewer than the current turn.
    keep_from = turn_starts[-verbatim_turns] if len(turn_starts) > verbatim_turns else 0
    recent = history[keep_from:]

    # Shrink further if the recent window alone still exceeds the budget —
    # but always keep at least the current (last) turn intact.
    starts_in_recent = [i for i, m in enumerate(recent) if _is_turn_start(m)]
    while estimate_tokens(recent) > token_budget and len(starts_in_recent) > 1:
        recent = recent[starts_in_recent[1]:]
        starts_in_recent = [i for i, m in enumerate(recent) if _is_turn_start(m)]

    dropped = history[: len(history) - len(recent)]
    if not dropped:
        return list(history), False

    facts = _extract_facts(dropped)
    summary = "سياق سابق: " + ("؛ ".join(facts) if facts else "دار حديث سابق مع المستخدم دون عمليات مؤكدة.")
    summary = summary[:2000]

    # The API requires the first message to be user-role, so the assistant-side
    # summary is preceded by a tiny synthetic user marker.
    window = [
        {"role": "user", "content": "(استئناف جلسة سابقة)"},
        {"role": "assistant", "content": summary},
        *recent,
    ]
    return window, True
