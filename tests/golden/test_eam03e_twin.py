"""Golden tests for the A7-EAM-03E-A0 host twin.

Two independent sources pin the twin:
  * ``tests/xsim/tb_a7eam03e.sv`` — seven d1 integers for seed 0x11111111.
  * ``docs/contracts/A7-EAM-03E-A02.md`` — the seed 0x22222222 inversion
    (d_pos 1487, d_neg 229, M_L1 -1258).

If either drifts, the twin no longer mirrors ``rtl/eam/eam03e_core.sv`` and the
UI must stop presenting twin numbers as a model of silicon.
"""
from __future__ import annotations

import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[2]))

from python.eam.eam03e_twin import (  # noqa: E402
    Eam03eTwin,
    GOLDEN_A01T,
    LAW,
    golden_check,
    h_update,
    triplet_report,
)


def test_law_id_unchanged():
    assert LAW == "eam03e-a0-signsgd-v1"


def test_xsim_goldens():
    res = golden_check()
    assert res["pass"], res["mismatch"]
    for key in ("init_AB", "init_AC", "train_AB", "train_AC",
                "reset_AB", "swap_AC", "swap_AB"):
        assert res["got"][key] == GOLDEN_A01T[key]


def test_a02_contract_seed_inversion():
    """Seed 0x22222222 must still invert, with the contract's exact integers."""
    r = triplet_report(0x22222222, "ALPHA", "BETA.", "OMEGA", steps=32)
    assert r["post"]["d1_pos"] == 1487
    assert r["post"]["d1_neg"] == 229
    assert r["post"]["M_L1"] == -1258
    assert r["gates"]["M_L1_post_positive"] is False


def test_state_update_is_unsigned_and_never_negative():
    """Quirk 2: the SV concat is unsigned, so a negative embedding saturates high."""
    assert h_update(0, 50) == 50
    assert h_update(0, -22) == 32767
    assert h_update(-1000000, 0) == 32767   # logical shift of a negative acc
    for acc in (-(1 << 20), -1, 0, 1, 1 << 20):
        for e in range(-128, 128):
            assert 0 <= h_update(acc, e) <= 32767


def test_forward_state_is_non_negative():
    t = Eam03eTwin()
    t.reseed(0x11111111)
    t.buf(0, "ALPHA")
    tr = t.encode(0)
    assert all(0 <= v <= 32767 for v in tr.h_final)
    assert tr.h_saturated >= 1


def test_cue_is_degenerate_and_dh_is_zero():
    """Quirk 3: unsigned compare collapses the cue to all-ones, so dH is 0."""
    t = Eam03eTwin()
    t.reseed(0x11111111)
    t.buf(0, "ALPHA")
    t.buf(1, "OMEGA")
    tr = t.pair(same=False, prime=True)
    assert tr.a.cue == (1 << 64) - 1
    assert tr.b.cue == (1 << 64) - 1
    assert tr.dH == 0


def test_reseed_erases_learned_geometry():
    t = Eam03eTwin()
    t.reseed(0x11111111)
    t.mode(learn=False, freeze=False)
    t.measure("ALPHA", "BETA.", True)          # prime
    before = t.measure("ALPHA", "BETA.", True).d1

    t.mode(learn=True, freeze=False)
    for _ in range(32):
        t.measure("ALPHA", "BETA.", True)
    t.mode(learn=False, freeze=True)
    trained = t.measure("ALPHA", "BETA.", True).d1
    assert trained < before

    t.reseed(0x11111111)
    t.mode(learn=False, freeze=False)
    assert t.measure("ALPHA", "BETA.", True).d1 == before


def test_freeze_blocks_updates():
    t = Eam03eTwin()
    t.reseed(0x11111111)
    t.mode(learn=True, freeze=True)
    tr = t.measure("ALPHA", "BETA.", True)
    assert tr.updated is False
    assert tr.e_writes == 0 and tr.wh_writes == 0


def test_diff_gate_closes_above_margin():
    """DIFF with d1 >= E3_MARG produces no gradient at all."""
    t = Eam03eTwin()
    t.reseed(0x11111111)
    t.mode(learn=True, freeze=False)
    t.measure("ALPHA", "OMEGA", False)         # prime
    tr = t.measure("ALPHA", "OMEGA", False)
    if tr.d1 >= 4096:
        assert tr.diff_gate_open is False
        assert all(v == 0 for v in tr.gA)
        assert tr.e_writes == 0


def test_buf_truncates_at_tmax():
    t = Eam03eTwin()
    assert t.buf(0, "x" * 80) == 46
