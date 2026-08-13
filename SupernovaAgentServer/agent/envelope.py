"""Envelope contract consumed verbatim by the Flutter EnvelopeRouter.

{
  "type": REVIEW_TRANSFER | REVIEW_BILL | REVIEW_ACCOUNT | REVIEW_CARD
        | STEP_UP_VERIFY | DECLINED,
  "operation": "transfer" | "bill" | "card" | "account",
  "payload": {...},                    # exactly what the target screen needs
  "risk": {action, tier, fraud_probability, reasons},
  "llm_may_proceed": bool
}
"""

from __future__ import annotations

REVIEW_TYPE_BY_OPERATION = {
    "transfer": "REVIEW_TRANSFER",
    "bill": "REVIEW_BILL",
    "account": "REVIEW_ACCOUNT",
    "card": "REVIEW_CARD",
    "product": "REVIEW_PRODUCT",
}


def _risk_block(decision: dict) -> dict:
    return {
        "action": decision["action"],
        "tier": decision["tier"],
        "fraud_probability": decision["fraud_probability"],
        "reasons": decision["reasons"],
    }


def route_from_decision(operation: str, payload: dict, decision: dict) -> dict:
    """Map a DecisionAgent verdict to the envelope Flutter routes on.

    ALLOW -> REVIEW_*        (user reviews, then OTP executes — never the LLM)
    STEP_UP -> STEP_UP_VERIFY (extra confirmation before the review screen)
    DECLINE -> DECLINED       (blocked; llm_may_proceed=False, no override)
    """
    if operation not in REVIEW_TYPE_BY_OPERATION:
        raise ValueError(f"unknown operation: {operation}")
    action = decision["action"]
    if action == "ALLOW":
        env_type, may_proceed = REVIEW_TYPE_BY_OPERATION[operation], True
    elif action == "STEP_UP":
        env_type, may_proceed = "STEP_UP_VERIFY", True
    elif action == "DECLINE":
        env_type, may_proceed = "DECLINED", False
    else:
        raise ValueError(f"unknown decision action: {action}")
    return {
        "type": env_type,
        "operation": operation,
        "payload": payload,
        "risk": _risk_block(decision),
        "llm_may_proceed": may_proceed,
    }


def non_monetary_envelope(operation: str, payload: dict) -> dict:
    """Account/card applications: no money moves, no ML gate — static low risk."""
    return {
        "type": REVIEW_TYPE_BY_OPERATION[operation],
        "operation": operation,
        "payload": payload,
        "risk": {
            "action": "ALLOW",
            "tier": "LOW",
            "fraud_probability": 0.0,
            "reasons": ["non_monetary_operation"],
        },
        "llm_may_proceed": True,
    }
