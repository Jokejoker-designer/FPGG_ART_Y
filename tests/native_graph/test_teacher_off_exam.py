"""Teacher-off exam shape gate (freeze=1, teacher=0, external_LLM=0, learn=0)."""

from __future__ import annotations

import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
TEL_SCHEMA = json.loads(
    (ROOT / "docs/contracts/native_graph/telemetry.schema.json").read_text(encoding="utf-8")
)
EXAM = json.loads(
    (ROOT / "results/A7-NATIVE-GRAPH/NG-08/kidi20_blind_exam.json").read_text(encoding="utf-8")
)


def test_teacher_off_telemetry_shape():
    tel = {
        "interaction_id": "blind-1",
        "cycle": 1,
        "phase": "OUTPUT",
        "teacher_present": False,
        "learn_enabled": False,
        "freeze": True,
        "external_LLM": False,
        "physical_lanes_active": 16,
        "logical_agents_active": 256,
    }
    for k in TEL_SCHEMA["required"]:
        assert k in tel
    assert tel["teacher_present"] is False
    assert tel["learn_enabled"] is False
    assert tel["freeze"] is True
    assert tel["external_LLM"] is False


def test_blind_exam_held_out_and_unrelated():
    assert EXAM["phase"] == "BLIND_EXAM"
    for item in EXAM["held_out"]:
        assert "unrelated" in item and "contradiction" in item
        assert "entity" not in item and "intent" not in item


def test_marker():
    print("A7NG_TEACHER_OFF_HARNESS_PASS")
