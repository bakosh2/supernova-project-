"""
Supernova specialist configuration.

Each specialist represents one responsibility of the Supernova agent.

Specialists:
- task: create a new child task
- edit: edit the currently prepared task
- routine: create a routine as a task
- focus: manage focus duration
- break: manage break duration

The add_task tool is available to the specialists, but the prompt rules
require explicit parent confirmation before the tool can be used.
"""

from __future__ import annotations

import copy
from dataclasses import dataclass

from agent.prompts import (
    SHARED_PREAMBLE,
    TASK_SECTION,
    CONFIRMATION_SECTION,
    EDIT_SECTION,
    ROUTINE_SECTION,
    FOCUS_BREAK_SECTION,
)

from agent.tools import HANDLERS, TOOLS


# ============================================================
# SPECIALIST MODEL
# ============================================================

@dataclass(frozen=True)
class Specialist:
    """
    Configuration for one Supernova specialist.

    A specialist contains:
    - its name
    - system prompt blocks
    - the tools it is allowed to use
    - matching handlers
    - allowed envelopes
    """

    name: str
    system_blocks: list
    tools: list
    handlers: dict
    allowed_envelopes: frozenset


# ============================================================
# SPECIALIST BUILDER
# ============================================================

def _build(
    name: str,
    sections: list[str],
    tool_names: list[str],
) -> Specialist:
    """
    Build a specialist configuration.

    Only the tools listed in tool_names are available to this specialist.
    """

    tools = [
        copy.deepcopy(tool)
        for tool in TOOLS
        if tool["name"] in tool_names
    ]

    # Make sure every requested tool actually exists.
    assert len(tools) == len(tool_names), (
        f"Unknown tool in '{name}' specialist"
    )

    # Add prompt-cache marker to the last tool.
    if tools:
        tools[-1]["cache_control"] = {
            "type": "ephemeral"
        }

    # --------------------------------------------------------
    # System prompt blocks
    # --------------------------------------------------------

    system_blocks = [
        {
            "type": "text",
            "text": SHARED_PREAMBLE,
            "cache_control": {
                "type": "ephemeral"
            },
        }
    ]

    for section in sections:
        system_blocks.append(
            {
                "type": "text",
                "text": section,
            }
        )

    # --------------------------------------------------------
    # Specialist
    # --------------------------------------------------------

    return Specialist(
        name=name,
        system_blocks=system_blocks,
        tools=tools,
        handlers={
            tool_name: HANDLERS[tool_name]
            for tool_name in tool_names
        },
        allowed_envelopes=frozenset(),
    )


SIRI_SECTION = "يجب عليك دائماً استدعاء أداة prepare_task لإعداد وإرجاع بيانات المهمة التقسيمية المحددة بدون كتابة نص حواري حر فقط."


# ============================================================
# SUPERNOVA SPECIALISTS
# ============================================================

SPECIALISTS: dict[str, Specialist] = {
    # --------------------------------------------------------
    # TASK
    # --------------------------------------------------------
    "task": _build(
        name="task",
        sections=[
            TASK_SECTION,
            CONFIRMATION_SECTION,
        ],
        tool_names=[
            "add_task",
        ],
    ),

    # --------------------------------------------------------
    # EDIT
    # --------------------------------------------------------
    "edit": _build(
        name="edit",
        sections=[
            TASK_SECTION,
            EDIT_SECTION,
            CONFIRMATION_SECTION,
        ],
        tool_names=[
            "add_task",
        ],
    ),

    # --------------------------------------------------------
    # ROUTINE
    # --------------------------------------------------------
    "routine": _build(
        name="routine",
        sections=[
            TASK_SECTION,
            ROUTINE_SECTION,
            CONFIRMATION_SECTION,
        ],
        tool_names=[
            "add_task",
        ],
    ),

    # --------------------------------------------------------
    # FOCUS
    # --------------------------------------------------------
    "focus": _build(
        name="focus",
        sections=[
            TASK_SECTION,
            FOCUS_BREAK_SECTION,
            CONFIRMATION_SECTION,
        ],
        tool_names=[
            "add_task",
        ],
    ),

    # --------------------------------------------------------
    # BREAK
    # --------------------------------------------------------
    "break": _build(
        name="break",
        sections=[
            TASK_SECTION,
            FOCUS_BREAK_SECTION,
            CONFIRMATION_SECTION,
        ],
        tool_names=[
            "add_task",
        ],
    ),

    # --------------------------------------------------------
    # SIRI HOMEWORK (Preview & Preparation only)
    # --------------------------------------------------------
    "siri_homework": _build(
        name="siri_homework",
        sections=[
            TASK_SECTION,
            SIRI_SECTION,
        ],
        tool_names=[
            "prepare_task",
        ],
    ),
}


# ============================================================
# SAFETY CHECKS
# ============================================================

# Every specialist must use a valid handler.
for specialist_name, specialist in SPECIALISTS.items():

    for tool_name in specialist.handlers:

        assert tool_name in HANDLERS, (
            f"{specialist_name} references unknown handler: "
            f"{tool_name}"
        )


# Every specialist's tools must have matching handlers.
for specialist_name, specialist in SPECIALISTS.items():

    specialist_tool_names = {
        tool["name"]
        for tool in specialist.tools
    }

    handler_names = set(
        specialist.handlers.keys()
    )

    assert specialist_tool_names == handler_names, (
        f"Tool/handler mismatch in specialist "
        f"'{specialist_name}'"
    )


# The Supernova agent currently has no envelope-based
# banking operations.
for specialist_name, specialist in SPECIALISTS.items():

    assert not specialist.allowed_envelopes, (
        f"Unexpected envelope configuration in "
        f"'{specialist_name}'"
    )
