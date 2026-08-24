"""TRAIN-V2 attribution protocol gates (V2-C1/C2/S20/S40/AB/BLIND).

Evidence_class=HARNESS. Not BOARD_PASS. Not §14 SoC.
"""

from __future__ import annotations

import json
from pathlib import Path

from python.native_graph.train_v2_harness import (
    FORBIDDEN_BLIND,
    OUT,
    run_experiment,
    sha256_bytes,
    verify_frozen_bits,
)

ROOT = Path(__file__).resolve().parents[2]


def _summary():
    # Idempotent: re-run writes same structure; control SHA must remain stable content-wise
    return run_experiment()


def test_preregistered_metrics_exist_before_claim():
    s = _summary()
    pre = json.loads((OUT / "METRICS_PREREGISTERED.json").read_text(encoding="utf-8"))
    assert pre["declared_before_run"] is True
    assert pre["board_pass"] is False
    assert pre["evidence_class"] == "HARNESS"
    assert "top1_accuracy" in pre["metrics"]
    assert s["result"] in ("PASS", "FAIL")


def test_v2_c1_old_model_frozen_not_deleted():
    s = _summary()
    dump = OUT / "control" / "old_model_dump.json"
    assert dump.is_file()
    assert s["gates"]["V2-C1_control_present"] is True
    assert s["gates"]["control_sha_unchanged"] is True
    # NG-08 curriculum archive still present (old lane evidence)
    assert (ROOT / "results/A7-NATIVE-GRAPH/NG-08/kidi20_curriculum.json").is_file()


def test_v2_c2_reset_clears_learned_not_bits():
    s = _summary()
    forget = json.loads((OUT / "run_b" / "forget_a.json").read_text(encoding="utf-8"))
    assert forget["generation_after_reset"] >= 2
    frozen = verify_frozen_bits()
    assert frozen["all_match"] is True
    assert s["gates"]["frozen_bits_match"] is True


def test_v2_s20_teacher_off_bag():
    s = _summary()
    assert s["gates"]["V2-S20_v2_top1"] is True
    assert s["gates"]["V2-S20_v2_topk"] is True
    assert s["gates"]["V2-S20_hn_fp"] is True
    assert s["gates"]["V2-S20_paraphrase"] is True
    tel = json.loads((OUT / "run_a" / "teacher_off_telemetry.json").read_text(encoding="utf-8"))
    assert tel["teacher_present"] is False
    assert tel["learn_enabled"] is False
    assert tel["freeze"] is True
    assert tel["external_LLM"] is False


def test_v2_s40_after_s20():
    s = _summary()
    assert s["gates"]["V2-S40_v2_top1"] is True
    assert s["gates"]["V2-S40_hn_fp"] is True
    c20 = json.loads((OUT / "corpus_20.json").read_text(encoding="utf-8"))
    c40 = json.loads((OUT / "corpus_40.json").read_text(encoding="utf-8"))
    assert c20["n_facts"] == 20 and c40["n_facts"] == 40
    # Same first 20 facts (curriculum not changed when scaling)
    assert [f["id"] for f in c20["facts"]] == [f["id"] for f in c40["facts"][:20]]


def test_v2_ab_run_b_forgets_a():
    s = _summary()
    assert s["gates"]["V2-AB_forgets_a"] is True
    assert s["gates"]["V2-AB_acquires_b"] is True


def test_v2_beats_warm_and_ge_control():
    s = _summary()
    assert s["gates"]["V2_beats_warm"] is True
    assert s["gates"]["V2_ge_control_top1"] is True
    m = s["metrics_20"]
    assert m["train_v2_run_a"]["top1_accuracy"] > m["warm_new_law_no_reset"]["top1_accuracy"]


def test_v2_blind_no_attention_leak():
    _summary()
    packets = json.loads((OUT / "run_a" / "blind_packets.json").read_text(encoding="utf-8"))
    for pkt in packets:
        assert pkt["phase"] == "BLIND_EXAM"
        leaked = FORBIDDEN_BLIND.intersection(pkt.keys())
        assert not leaked
        assert "query" in pkt
        assert pkt["supervision"] == []


def test_no_host_gradient_answer_path():
    s = _summary()
    # Summary and dumps must not encode host-computed winners as authority fields
    dump = json.loads((OUT / "control" / "old_model_dump.json").read_text(encoding="utf-8"))
    assert "gradient" not in dump
    assert "winner" not in dump
    assert "address" not in dump
    assert s["board_pass"] is False
    assert s["evidence_class"] == "HARNESS"


def test_marker():
    s = _summary()
    assert s["result"] == "PASS"
    print(s["marker"])
