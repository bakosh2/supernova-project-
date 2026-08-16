"""Shared specialist engine: ONE Anthropic tool-use loop, many configurations.

A specialist (agent/specialists.py) is just a config — focused system prompt,
tool subset, envelope allowlist — running THIS loop. The orchestrator
(agent/orchestrator.py) owns the session, routing and persistence; this module
owns the step loop:

  window (view over full history) -> LLM (streamed) -> execute tool_use blocks
  (parallel, validated, structured errors) -> tool_results in ONE user message
  -> repeat, at most MAX_STEPS times -> graceful Arabic fallback.

Money envelopes are produced by the tool layer (DecisionAgent decides, never
the LLM); the loop transports them to the client and the audit trail, and
enforces the specialist's envelope allowlist structurally.
"""

from __future__ import annotations

import asyncio
import json
import logging

from agent import audit as audit_mod
from agent.config import get_settings
from agent.context import build_window, cap_tool_result
from agent.metrics import metrics
from agent.prompts import FALLBACK_MESSAGE
from agent.specialists import Specialist
from agent.tools import validate_input

log = logging.getLogger("ameen.agent")


async def _execute_tool(
    block: dict, ctx: dict, specialist: Specialist
) -> tuple[dict, dict, dict | None]:
    """Run one tool_use block -> (tool_result_block, result_dict, envelope|None).

    Never raises: schema violations, tools outside the specialist's subset and
    handler crashes all come back as structured {"error": {...}} results the
    model can recover from.
    """
    settings = get_settings()
    name = block.get("name", "")
    tool_input = block.get("input") or {}
    metrics.record_tool(name)

    envelope = None
    if name not in specialist.handlers:
        result = {
            "error": {
                "code": "unknown_tool",
                "message": f"tool '{name}' is not available to the {specialist.name} agent",
            }
        }
    else:
        problems = validate_input(name, tool_input)
        if problems:
            result = {
                "error": {
                    "code": "invalid_input",
                    "message": "; ".join(problems),
                    "hint": "fix the fields and call the tool again",
                }
            }
        else:
            try:
                # handlers are sync + CPU-light (~1ms incl. decide()) — running
                # them inline beats the queueing cost of a thread hop
                result, envelope = specialist.handlers[name](tool_input, ctx)
            except Exception as exc:  # noqa: BLE001
                log.exception("handler %s crashed", name)
                result = {"error": {"code": "tool_failed", "message": str(exc)}}

    if envelope is not None and envelope["type"] not in specialist.allowed_envelopes:
        # Structural guardrail: a specialist can never emit outside its mandate,
        # even if a handler misbehaves. Tool subsets make this unreachable in
        # normal operation; keep it as the last line of defence.
        log.error(
            "specialist %s produced disallowed envelope %s — dropped",
            specialist.name, envelope["type"],
        )
        metrics.inc("envelope_blocked_total")
        result = {
            "error": {
                "code": "envelope_not_permitted",
                "message": f"the {specialist.name} agent cannot prepare this operation",
            }
        }
        envelope = None

    result = cap_tool_result(result, settings.tool_result_max_bytes)
    tool_result_block = {
        "type": "tool_result",
        "tool_use_id": block.get("id", ""),
        "content": json.dumps(result, ensure_ascii=False),
        **({"is_error": True} if "error" in result else {}),
    }
    return tool_result_block, result, envelope


async def run_specialist(
    *,
    specialist: Specialist,
    session_id: str,
    history: list[dict],
    llm,
    audit,
    emit,
    trace: dict,
    llm_semaphore: asyncio.Semaphore | None = None,
    task_confirmed: bool = False,
    tool_choice: dict | None = None,
) -> bool:
    """Run one user turn through a specialist. Mutates `history` in place; the
    caller (orchestrator) owns session persistence.

    Returns False when the LLM call failed — the caller drops the un-answered
    user turn to keep history valid.
    """
    settings = get_settings()
    # Tool handlers receive server-derived facts only.  In particular, a model
    # cannot claim that the parent confirmed a task: that flag is calculated by
    # the router from the current parent message.
    ctx = {"session_id": session_id, "task_confirmed": task_confirmed}
    steps: list[dict] = trace.setdefault("steps", [])
    completed = False

    for step in range(settings.max_steps):
        window, compressed = build_window(
            history, settings.history_token_budget, settings.verbatim_turns
        )
        if compressed:
            metrics.inc("history_compressions_total")

        await emit({"type": "status", "message": "Supernova يفكر..." if step == 0 else "جاري التنفيذ..."})

        async def on_text(chunk: str) -> None:
            await emit({"type": "token", "text": chunk})

        try:
            current_tool_choice = tool_choice if step == 0 else None
            if llm_semaphore is not None:
                async with llm_semaphore:  # backpressure: bound in-flight LLM calls
                    assistant = await llm.complete(
                        specialist.system_blocks, specialist.tools, window, on_text, tool_choice=current_tool_choice
                    )
            else:
                assistant = await llm.complete(
                    specialist.system_blocks, specialist.tools, window, on_text, tool_choice=current_tool_choice
                )
        except Exception:  # noqa: BLE001
            log.exception("LLM call failed")
            metrics.inc("llm_errors_total")
            await emit({"type": "error", "code": "llm_error", "message": FALLBACK_MESSAGE})
            return False

        history.append({"role": "assistant", "content": assistant["content"]})
        tool_uses = [
            b for b in assistant["content"]
            if isinstance(b, dict) and b.get("type") == "tool_use"
        ]
        steps.append({
            "step": step,
            "tools": [t.get("name") for t in tool_uses],
            "stop_reason": assistant.get("stop_reason"),
        })

        if not tool_uses:
            completed = True
            break

        # Parallel tool_use blocks in one assistant turn are executed
        # concurrently; ALL results return in ONE user message, matched by id.
        executed = await asyncio.gather(
            *(_execute_tool(b, ctx, specialist) for b in tool_uses)
        )
        
        result_blocks = []

        for tool_result_block, result, envelope in executed:
            result_blocks.append(tool_result_block)

            if isinstance(result, dict) and result.get("event") == "task_preview":
                await emit(result)

            if "error" in result:
                metrics.inc("tool_errors_total")

            if envelope is not None:
                metrics.record_risk(envelope["risk"]["action"])
                await emit({
                    "type": "envelope",
                    "envelope": envelope
                })
            
                audit_mod.fire_and_forget(
                    audit.record(
                        audit_mod.make_entry(
                            session_id,
                            envelope,
                            trace
                        )
                    )
                )

            if result.get("success") and result.get("task"):
                print("🟢 [BACKEND] emitting task_added")

                await emit({
                    "type": "task_added",
                    "task": result["task"]
                })
                completed = True

        # Siri only needs the prepared preview, so stop after its tool call.
        if specialist.name == "siri_homework":
            completed = True

        # A real task was successfully added, or Siri finished its preview.
        # Do not make another Claude call.
        if completed:
            break


        # Otherwise give the tool result back to Claude for the next step.
        history.append({
            "role": "user",
            "content": result_blocks
        })

    # Only use the fallback if the loop genuinely ran out of steps.
    if not completed:
        metrics.inc("max_steps_exhausted_total")
        await emit({
            "type": "token",
            "text": FALLBACK_MESSAGE
        })
        history.append({
            "role": "assistant",
            "content": FALLBACK_MESSAGE
        })

    return True


