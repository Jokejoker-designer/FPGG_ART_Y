"""Tests for the A7-SIM-BENCH metric implementations.

The benchmark's conclusions are only worth as much as its arithmetic, and three of
these functions are easy to get subtly wrong: tie-aware AUC, non-interpolated
average precision, and the group split that is supposed to make the test set
actually held out.
"""
from __future__ import annotations

import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[2]))

from python.eam import eam03e_bench as B  # noqa: E402


# ------------------------------------------------------------------ AUC / AP

def test_auc_perfect_and_inverted():
    scores = [3.0, 2.0, 1.0, 0.0]
    labels = [1, 1, 0, 0]
    assert B.auc_midrank(scores, labels) == 1.0
    assert B.auc_midrank([-s for s in scores], labels) == 0.0


def test_auc_all_ties_is_half():
    """Every d1 identical is the degenerate case the >>5 quantisation invites."""
    assert B.auc_midrank([5.0] * 6, [1, 1, 1, 0, 0, 0]) == 0.5


def test_auc_partial_tie_gets_half_credit():
    """positives {2.0, 1.0}, negatives {1.0, 0.0}: three outright wins and one tie."""
    auc = B.auc_midrank([2.0, 1.0, 1.0, 0.0], [1, 1, 0, 0])
    assert auc == (1.0 + 1.0 + 0.5 + 1.0) / 4.0 == 0.875


def test_auc_missing_class_is_nan():
    v = B.auc_midrank([1.0, 2.0], [1, 1])
    assert v != v


def test_auc_matches_brute_force_wmw():
    import random
    rng = random.Random(7)
    for _ in range(30):
        n = rng.randrange(4, 40)
        scores = [float(rng.randrange(5)) for _ in range(n)]   # heavy ties on purpose
        labels = [rng.randrange(2) for _ in range(n)]
        if not (0 < sum(labels) < n):
            continue
        pos = [scores[i] for i in range(n) if labels[i] == 1]
        neg = [scores[i] for i in range(n) if labels[i] == 0]
        brute = sum(1.0 if p > q else (0.5 if p == q else 0.0)
                    for p in pos for q in neg) / (len(pos) * len(neg))
        assert abs(B.auc_midrank(scores, labels) - brute) < 1e-9


def test_average_precision_perfect_and_floor():
    assert B.average_precision([3.0, 2.0, 1.0, 0.0], [1, 1, 0, 0]) == 1.0
    ap = B.average_precision([1.0] * 4, [1, 1, 0, 0])
    assert abs(ap - 0.5) < 1e-9        # all tied -> precision equals the positive rate


def test_tie_mass_bounds():
    assert B.tie_mass([1.0, 1.0], [1, 0]) == 1.0
    assert B.tie_mass([2.0, 1.0], [1, 0]) == 0.0


def test_quantisation_ceiling_is_above_actual():
    scores = [1.0, 1.0, 0.0, 0.0]
    labels = [1, 0, 1, 0]
    assert B.quantisation_ceiling(scores, labels) >= B.auc_midrank(scores, labels)


def test_triplet_accuracy_tie_is_half():
    assert B.triplet_accuracy([(1, 2), (2, 1), (3, 3)]) == (1.0 + 0.0 + 0.5) / 3.0


def test_spearman_monotone():
    assert abs(B.spearman([1, 2, 3, 4], [10, 20, 30, 40]) - 1.0) < 1e-9
    assert abs(B.spearman([1, 2, 3, 4], [40, 30, 20, 10]) + 1.0) < 1e-9


# ------------------------------------------------------------------ baselines

def test_string_distances_against_known_values():
    assert B.levenshtein(b"kitten", b"sitting") == 3
    assert B.levenshtein(b"", b"abc") == 3
    assert B.osa_distance(b"ca", b"ac") == 1          # one transposition
    assert B.levenshtein(b"ca", b"ac") == 2           # Levenshtein needs two edits
    assert abs(B.jaro(b"MARTHA", b"MARHTA") - 0.944444) < 1e-5
    assert abs(B.b7_jaro_winkler(b"MARTHA", b"MARHTA") - 0.961111) < 1e-5
    assert abs(B.b7_jaro_winkler(b"DWAYNE", b"DUANE") - 0.840000) < 1e-5


def test_identical_strings_are_maximally_similar():
    s = b"Nguyen Van Minh"
    for name, fn in B.BASELINES.items():
        if name in ("B0_constant", "B8_suffix"):
            continue
        assert fn(s, s) >= fn(s, b"Tran Thi Lan"), name


def test_hist_l1_is_order_blind():
    """B3 must not see order: that is the property that makes it the right control."""
    assert B.b3_hist_l1(b"abc", b"cba") == 0
    assert B.b3_hist_l1(b"abc", b"abd") < 0


# --------------------------------------------------------------- dataset split

def test_group_split_has_no_string_leakage():
    ds = B.build_name_dataset(n_entities=90, seed=3)
    info = B.assert_no_leakage(ds)
    assert info["train_strings"] > 0 and info["test_strings"] > 0
    assert ds.train and ds.test


def test_group_split_keeps_a_component_whole():
    pairs = [B.Pair("aa", "ab", True), B.Pair("ab", "ac", True),
             B.Pair("zz", "zy", True), B.Pair("qq", "qp", True)]
    out = B.group_split(pairs, fracs=(0.5, 0.25, 0.25), seed=1)
    where = {}
    for split, rows in out.items():
        for p in rows:
            for s in (p.a, p.b):
                where.setdefault(s, set()).add(split)
    assert all(len(v) == 1 for v in where.values())


def test_dataset_respects_the_46_byte_cap():
    for vn in (False, True):
        ds = B.build_name_dataset(n_entities=80, seed=5, vn=vn)
        for rows in (ds.train, ds.dev, ds.test):
            for p in rows:
                assert 2 <= len(p.a.encode("utf-8")) <= B.MAX_BYTES
                assert 2 <= len(p.b.encode("utf-8")) <= B.MAX_BYTES


def test_dataset_has_both_classes_in_test():
    ds = B.build_name_dataset(n_entities=200, seed=11)
    labels = {p.same for p in ds.test}
    assert labels == {True, False}


# ------------------------------------------------------------------- end to end

def test_bench_seed_runs_and_reports_the_control():
    ds = B.build_name_dataset(n_entities=60, seed=2)
    r = B.bench_seed(ds, 0x11111111, epochs=1, with_baselines=True)
    assert 0.0 <= r["untrained"]["auc"] <= 1.0
    assert 0.0 <= r["trained"]["auc"] <= 1.0
    assert r["delta_auc"] == round(r["trained"]["auc"] - r["untrained"]["auc"], 6)
    assert "B3_hist_l1" in r["baselines"]
    assert r["collapse"]["dims"] == 32


def test_collapse_report_detects_the_active_quirk2_defect():
    """While the unsigned-concat defect stands, h is never negative. That is the
    cheapest possible detector for whether a fix has landed."""
    ds = B.build_name_dataset(n_entities=40, seed=4)
    r = B.bench_seed(ds, 0x11111111, epochs=1, with_baselines=False)
    assert r["collapse"]["negativity_rate"] == 0.0
    assert r["collapse"]["defect_quirk2_active"] is True


def test_frozen_seeds_are_deterministic_and_include_the_known_bad_one():
    a = B.frozen_seeds(6)
    assert a == B.frozen_seeds(6)
    assert a[-1] == 0x22222222
    assert len(set(a)) == 6


def test_gates_report_shape():
    ds = B.build_name_dataset(n_entities=60, seed=6)
    rows = [B.bench_seed(ds, s, epochs=1) for s in B.frozen_seeds(2)]
    rep = B.evaluate_gates(rows)
    assert rep["screen_verdict"] in ("PROMISING", "PLASTIC_NOT_DISCRIMINATIVE",
                                     "DOES_NOT_WORK")
    assert "G1_delta_auc" in rep["gates"]
    assert "not a BOARD_PASS" in rep["authority"]
