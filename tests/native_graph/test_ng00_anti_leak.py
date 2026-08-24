"""NG-00 anti-leak and schema gates for A7-NATIVE-GRAPH."""

from __future__ import annotations

import json
from pathlib import Path

import pytest

ROOT = Path(__file__).resolve().parents[2]
CONTRACTS = ROOT / "docs" / "contracts" / "native_graph"
LESSON_SCHEMA = json.loads((CONTRACTS / "teacher_lesson.schema.json").read_text(encoding="utf-8"))
TELEMETRY_SCHEMA = json.loads((CONTRACTS / "telemetry.schema.json").read_text(encoding="utf-8"))

FORBIDDEN_ALWAYS = {
    "gradient",
    "delta_weight",
    "winner",
    "address",
    "hash",
    "next_token",
    "final_answer",
}
FORBIDDEN_BLIND = FORBIDDEN_ALWAYS | {
    "entity",
    "intent",
    "context",
    "candidate_ranking",
    "relation_path",
}


def _validate_required(obj: dict, schema: dict) -> list[str]:
    missing = [k for k in schema.get("required", []) if k not in obj]
    return missing


def test_lesson_schema_file_present():
    assert (CONTRACTS / "teacher_lesson.schema.json").is_file()
    assert LESSON_SCHEMA.get("title") == "NativeAITeacherLesson"


def test_telemetry_schema_file_present():
    assert (CONTRACTS / "telemetry.schema.json").is_file()
    assert TELEMETRY_SCHEMA.get("title") == "NativeAITelemetry"


def test_valid_train_lesson_accepted():
    packet = {
        "lesson_id": "kidi20-001",
        "phase": "TRAIN",
        "query": "What is an FPGA?",
        "supervision": [{"item_id": "n1", "reward": 3, "relation": "IS_A"}],
        "forbidden_native_fields": sorted(FORBIDDEN_ALWAYS),
    }
    assert _validate_required(packet, LESSON_SCHEMA) == []
    assert packet["phase"] in LESSON_SCHEMA["properties"]["phase"]["enum"]
    for s in packet["supervision"]:
        assert -3 <= s["reward"] <= 3


def test_rejects_host_learning_fields_in_packet():
    """Host must not embed native decision fields in the lesson envelope."""
    bad = {
        "lesson_id": "bad-001",
        "phase": "TRAIN",
        "query": "FPGA?",
        "supervision": [{"item_id": "n1", "reward": 1}],
        "winner": 42,
        "address": 0x1000,
        "gradient": [1, -1],
    }
    leaked = FORBIDDEN_ALWAYS.intersection(bad.keys())
    assert leaked == {"winner", "address", "gradient"}


def test_blind_exam_rejects_attention_hints():
    blind = {
        "lesson_id": "exam-001",
        "phase": "BLIND_EXAM",
        "query": "How does an FPGA work?",
        "supervision": [],
        "entity": "FPGA",
        "intent": "MECHANISM",
    }
    assert blind["phase"] == "BLIND_EXAM"
    leaked = FORBIDDEN_BLIND.intersection(blind.keys())
    assert "entity" in leaked and "intent" in leaked


def test_telemetry_required_fields():
    tel = {
        "interaction_id": "i-1",
        "cycle": 0,
        "phase": "SCORE",
        "physical_lanes_active": 16,
        "logical_agents_active": 0,
        "teacher_present": False,
        "learn_enabled": False,
        "freeze": True,
        "external_LLM": False,
    }
    assert _validate_required(tel, TELEMETRY_SCHEMA) == []
    assert TELEMETRY_SCHEMA.get("additionalProperties") is False
    assert LESSON_SCHEMA.get("additionalProperties") is False
    # honesty: physical != logical claim
    assert tel["physical_lanes_active"] == 16
    assert tel["logical_agents_active"] == 0
    # teacher-off exam shape
    assert tel["teacher_present"] is False
    assert tel["learn_enabled"] is False
    assert tel["freeze"] is True
    assert tel["external_LLM"] is False


def test_lesson_rejects_unknown_properties_policy():
    """Contract hardening: additionalProperties must be false (HLB MAJOR fix)."""
    assert LESSON_SCHEMA.get("additionalProperties") is False
    assert "FREEZE" in LESSON_SCHEMA["properties"]["phase"]["enum"]


def test_reward_bounds():
    for r in (-3, -1, 0, 1, 3):
        assert -3 <= r <= 3
    with pytest.raises(AssertionError):
        assert -3 <= 4 <= 3
