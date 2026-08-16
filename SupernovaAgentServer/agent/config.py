"""Env-driven configuration (pydantic-settings).

ANTHROPIC_API_KEY, AMEEN_MODEL, REDIS_URL, DATABASE_URL, AMEEN_MOCK, ...
"""

import os
from dataclasses import dataclass
from functools import lru_cache

try:
    from pydantic_settings import BaseSettings, SettingsConfigDict
except ImportError:  # Allows the deterministic local demo to run dependency-free.
    BaseSettings = None


if BaseSettings is not None:
    class Settings(BaseSettings):
        model_config = SettingsConfigDict(env_file=".env", extra="ignore")

        anthropic_api_key: str = ""
        openrouter_api_key: str = ""
        ameen_provider: str = "anthropic"
        ameen_model: str = "claude-sonnet-5"
        redis_url: str = "redis://localhost:6379/0"
        database_url: str = ""
        ameen_mock: bool = False
        max_steps: int = 6
        history_token_budget: int = 12_000
        verbatim_turns: int = 20
        tool_result_max_bytes: int = 2_048
        rate_limit_per_min: int = 10
        session_ttl_seconds: int = 86_400
        max_inflight_llm: int = 50
else:
    @dataclass
    class Settings:
        anthropic_api_key: str = os.getenv("ANTHROPIC_API_KEY", "")
        openrouter_api_key: str = os.getenv("OPENROUTER_API_KEY", "")
        ameen_provider: str = os.getenv("AMEEN_PROVIDER", "anthropic")
        ameen_model: str = os.getenv("AMEEN_MODEL", "claude-sonnet-5")
        redis_url: str = os.getenv("REDIS_URL", "redis://localhost:6379/0")
        database_url: str = os.getenv("DATABASE_URL", "")
        ameen_mock: bool = os.getenv("AMEEN_MOCK", "").lower() in {"1", "true", "yes"}
        max_steps: int = 6
        history_token_budget: int = 12_000
        verbatim_turns: int = 20
        tool_result_max_bytes: int = 2_048
        rate_limit_per_min: int = 10
        session_ttl_seconds: int = 86_400
        max_inflight_llm: int = 50


if BaseSettings is not None:
    # Keep this block visually separate from the fallback so settings stay
    # discoverable in deployments that use pydantic-settings.
    pass


@lru_cache
def get_settings() -> Settings:
    return Settings()
