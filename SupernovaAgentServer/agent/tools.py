"""
Supernova Agent tools.

The tools prepare and manage child tasks.
"""

from __future__ import annotations

from typing import Any
from uuid import uuid4


# ============================================================
# TOOL SCHEMAS
# ============================================================

TOOLS: list[dict] = [
    {
        "name": "add_task",
        "description": (
            "Add a prepared task to the child's task list. "
            "This tool must ONLY be called after the parent gives explicit "
            "confirmation to add the task."
        ),
        "input_schema": {
            "type": "object",
            "properties": {
                "title": {
                    "type": "string",
                    "description": "Task title.",
                },
                "child_age": {
                    "type": "integer",
                    "description": "Child age (6 through 12).",
                },
                "scope": {
                    "type": "string",
                    "description": "The exact part of the main task covered by the subtasks.",
                },
                "focus_duration": {
                    "type": "integer",
                    "description": "Focus duration in minutes.",
                },
                "break_duration": {
                    "type": "integer",
                    "description": "Break duration in minutes.",
                },
                "validity_days": {
                    "type": "integer",
                    "description": "Number of days the task remains valid.",
                },
                "subtasks": {
                    "type": "array",
                    "items": {
                        "type": "object",
                        "properties": {
                            "title": {"type": "string"},
                            "duration": {"type": "integer"},
                        },
                        "required": ["title", "duration"],
                    },
                    "description": "Small, independently completable parts of the original task, each with a duration in minutes.",
                },
                "requires_code": {
                    "type": "boolean",
                    "description": "Whether the task requires a parent verification code.",
                },
            },
            "required": [
                "title",
                "scope",
                "focus_duration",
                "break_duration",
                "validity_days",
                "subtasks",
                "requires_code",
            ],
        },
    },
    {
        "name": "prepare_task",
        "description": (
            "Prepare a homework task preview without adding it to the database. "
            "Returns a structured task breakdown."
        ),
        "input_schema": {
            "type": "object",
            "properties": {
                "title": {
                    "type": "string",
                    "description": "Task title.",
                },
                "child_age": {
                    "type": "integer",
                    "description": "Child age (6 through 12).",
                },
                "scope": {
                    "type": "string",
                    "description": "The exact part of the main task covered by the subtasks.",
                },
                "focus_duration": {
                    "type": "integer",
                    "description": "Focus duration in minutes.",
                },
                "break_duration": {
                    "type": "integer",
                    "description": "Break duration in minutes.",
                },
                "validity_days": {
                    "type": "integer",
                    "description": "Number of days the task remains valid.",
                },
                "subtasks": {
                    "type": "array",
                    "description": "List of subtasks with titles and durations.",
                    "items": {
                        "type": "object",
                        "properties": {
                            "title": {
                                "type": "string",
                                "description": "Subtask title.",
                            },
                            "duration": {
                                "type": "integer",
                                "description": "Subtask duration in minutes.",
                            },
                        },
                        "required": ["title", "duration"],
                    },
                },
                "requires_code": {
                    "type": "boolean",
                    "description": "True if completion requires a PIN.",
                },
            },
            "required": [
                "title",
                "scope",
                "focus_duration",
                "break_duration",
                "validity_days",
                "subtasks",
                "requires_code",
            ],
        },
    },
]


TOOL_SCHEMAS = {
    tool["name"]: tool["input_schema"]
    for tool in TOOLS
}


# ============================================================
# VALIDATION
# ============================================================

def validate_input(name: str, tool_input: dict) -> list[str]:
    schema = TOOL_SCHEMAS.get(name)

    if schema is None:
        return [f"unknown tool: {name}"]

    if not isinstance(tool_input, dict):
        return ["input must be a JSON object"]

    errors: list[str] = []

    properties = schema.get("properties", {})

    for required in schema.get("required", []):
        if required not in tool_input:
            errors.append(
                f"missing required field: {required}"
            )

    for key, value in tool_input.items():

        if key not in properties:
            errors.append(
                f"unexpected field: {key}"
            )
            continue

        field_type = properties[key].get("type")

        if field_type == "string" and not isinstance(value, str):
            errors.append(
                f"field '{key}' must be a string"
            )

        elif field_type == "integer":
            if isinstance(value, bool) or not isinstance(value, int):
                errors.append(
                    f"field '{key}' must be an integer"
                )
            elif key == "child_age" and not 6 <= value <= 12:
                errors.append("child_age must be between 6 and 12")

        elif field_type == "boolean":
            if not isinstance(value, bool):
                errors.append(
                    f"field '{key}' must be a boolean"
                )

        elif field_type == "array":
            if not isinstance(value, list):
                errors.append(
                    f"field '{key}' must be an array"
                )
            elif key == "subtasks":
                if not value:
                    errors.append("subtasks must not be empty")
                for index, subtask in enumerate(value):
                    if not isinstance(subtask, dict):
                        errors.append(f"subtasks[{index}] must be an object")
                    elif not isinstance(subtask.get("title"), str) or not subtask["title"].strip():
                        errors.append(f"subtasks[{index}].title must be a non-empty string")
                    elif isinstance(subtask.get("duration"), bool) or not isinstance(subtask.get("duration"), int) or subtask["duration"] <= 0:
                        errors.append(f"subtasks[{index}].duration must be a positive integer")

    return errors


# ============================================================
# IN-MEMORY TASK STORAGE
# ============================================================

# Development fallback only. Production should replace this tiny repository
# with the same task API/store used by the parent dashboard. Keeping tasks
# scoped by session prevents one family from seeing another family's draft.
TASKS_BY_SESSION: dict[str, list[dict[str, Any]]] = {}


# ============================================================
# TASK HANDLER
# ============================================================

def handle_add_task(
    tool_input: dict,
    ctx: dict,
) -> tuple[dict, None]:

    if not ctx.get("task_confirmed"):
        return {
            "error": {
                "code": "confirmation_required",
                "message": "يلزم تأكيد صريح من ولي الأمر قبل إضافة المهمة.",
            }
        }, None

    errors = validate_input(
        "add_task",
        tool_input,
    )

    if errors:
        return {
            "error": {
                "code": "invalid_input",
                "message": "Invalid task data.",
                "details": errors,
            }
        }, None

    session_id = str(ctx.get("session_id", "anonymous"))
    tasks = TASKS_BY_SESSION.setdefault(session_id, [])
    task = {
        "id": str(uuid4()),
        "title": tool_input["title"],
        "child_age": tool_input.get("child_age"),
        "scope": tool_input["scope"],
        "focus_duration": tool_input["focus_duration"],
        "break_duration": tool_input["break_duration"],
        "validity_days": tool_input["validity_days"],
        "subtasks": tool_input["subtasks"],
        "requires_code": tool_input["requires_code"],
    }

    tasks.append(task)

    return {
        "success": True,
        "message": "Task added successfully.",
        "task": task,
    }, None


def handle_prepare_task(
    tool_input: dict[str, Any],
    ctx: dict[str, Any],
) -> tuple[dict[str, Any], list[dict] | None]:
    task = {
        "id": str(uuid4()),
        "title": tool_input["title"],
        "child_age": tool_input.get("child_age"),
        "scope": tool_input["scope"],
        "focus_duration": tool_input["focus_duration"],
        "break_duration": tool_input["break_duration"],
        "validity_days": tool_input["validity_days"],
        "subtasks": tool_input["subtasks"],
        "requires_code": tool_input["requires_code"],
    }

    return {
        "success": True,
        "event": "task_preview",
        "message": "Task prepared.",
        "task": task,
    }, None


# ============================================================
# HANDLERS REGISTRY
# ============================================================

HANDLERS = {
    "add_task": handle_add_task,
    "prepare_task": handle_prepare_task,
}


assert set(HANDLERS) == {
    tool["name"]
    for tool in TOOLS
}
