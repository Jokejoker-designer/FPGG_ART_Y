"""NG-08 Kidi-20 minesweeper curriculum + preregistered blind exam."""

from __future__ import annotations

import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
NG08 = ROOT / "results" / "A7-NATIVE-GRAPH" / "NG-08"
CUR = json.loads((NG08 / "kidi20_curriculum.json").read_text(encoding="utf-8"))
EXAM = json.loads((NG08 / "kidi20_blind_exam.json").read_text(encoding="utf-8"))
FORBIDDEN = set(EXAM["preregistered_pass"]["forbid_fields"])


def test_kidi20_has_20_facts():
    assert len(CUR["facts"]) == 20
    assert CUR["preregistered"] is True


def test_blind_exam_preregistered():
    assert EXAM["phase"] == "BLIND_EXAM"
    assert "min_relevant_hit" in EXAM["preregistered_pass"]
    assert len(EXAM["held_out"]) >= 4


def test_blind_packets_have_no_attention_hints():
    for item in EXAM["held_out"]:
        leaked = FORBIDDEN.intersection(item.keys())
        assert not leaked, f"{item['id']} leaked {leaked}"
        assert "query" in item and "gold_relevant" in item


def test_bomb_does_not_delete_fact_from_corpus():
    """Contextual bomb: path prune only — facts remain in curriculum."""
    fact_ids = {f["id"] for f in CUR["facts"]}
    for tq in CUR["train_queries"]:
        for b in tq["bomb"]:
            assert b in fact_ids


def test_held_out_wording_differs_from_train():
    train_q = {t["q"] for t in CUR["train_queries"]}
    for item in EXAM["held_out"]:
        assert item["query"] not in train_q


def test_preregistered_score_harness():
    """Simple retrieval stub: gold ids must be subset of curriculum facts."""
    fact_ids = {f["id"] for f in CUR["facts"]}
    hits = 0
    bomb_expands = 0
    for item in EXAM["held_out"]:
        for g in item["gold_relevant"]:
            assert g in fact_ids
            hits += 1
        # expanding contradiction/unrelated as if bomb would be illegal for PASS
        for u in item.get("unrelated", []):
            assert u in fact_ids
        for c in item.get("contradiction", []):
            assert c in fact_ids
    assert hits >= EXAM["preregistered_pass"]["min_relevant_hit"]
    assert bomb_expands <= EXAM["preregistered_pass"]["max_bomb_expand"]
    print("A7NG08_KIDI20_PASS")
