"""Pre-register the golden bag for law `eam03e-a03-signed-h-v1` BEFORE RTL exists.

The A0.1-T goldens belong to `eam03e-a0-signsgd-v1` and must never be edited.
A signed `h` update is a different numerical law and therefore needs its own
integers. Those integers are *predicted here from the reference twin* and frozen
in `docs/contracts/A7-EAM-03E-A03.md`, so that when the RTL is written it has to
reproduce a number that was published before it existed.

If RTL and this prediction disagree, one of the two models of the change is
wrong. Investigate both. Do not edit the number to match the RTL — that is the
exact failure mode the pre-registration exists to prevent.

The only change under test is the signedness of the state update. Everything
else — seed schedule, string set, step count, d1 shift and saturation, SignSGD,
projection, the rotated embedding read, the unsigned cue compare — is identical
to A0.1-T.
"""
from __future__ import annotations

import json
import sys
from datetime import datetime, timezone
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT))

import python.eam.eam03e_twin as tw  # noqa: E402
from python.eam.eam03e_twin import (  # noqa: E402
    E3_SH,
    Eam03eTwin,
    golden_check,
    sat16,
)

LAW_A03 = "eam03e-a03-signed-h-v1"
SA, SB, SC = "ALPHA", "BETA.", "OMEGA"
SEED = 0x11111111
STEPS = 32


def h_update_signed(acc_k: int, e_k: int) -> int:
    """`e3_sat16($signed({{8{e[7]}}, e, 8'd0}) + acc) >>> E3_SH` done properly.

    Signed add, arithmetic shift right. Python's `>>` on a negative int already
    floors, which is what an arithmetic shift does, so no correction is applied:
    matching the RTL means matching `>>>`, not matching round-toward-zero.
    """
    return sat16((acc_k + (e_k << 8)) >> E3_SH)


def replay(rule) -> dict:
    """Replay the exact tb_a7eam03e.sv sequence under a given h rule."""
    keep = tw.h_update
    tw.h_update = rule
    try:
        t = Eam03eTwin(SEED)
        got: dict[str, int] = {}

        t.mode(learn=False, freeze=False)
        t.measure(SA, SB, True)                     # prime after seed
        got["init_AB"] = t.measure(SA, SB, True).d1
        got["init_AC"] = t.measure(SA, SC, False).d1

        t.mode(learn=True, freeze=False)
        for _ in range(STEPS):
            t.measure(SA, SB, True)
            t.measure(SA, SC, False)
        t.teacher_off()
        got["train_AB"] = t.measure(SA, SB, True).d1
        got["train_AC"] = t.measure(SA, SC, False).d1

        t.reseed(SEED)
        t.mode(learn=False, freeze=False)
        got["reset_AB"] = t.measure(SA, SB, True).d1

        t.mode(learn=True, freeze=False)
        for _ in range(STEPS):
            t.measure(SA, SC, True)
            t.measure(SA, SB, False)
        t.teacher_off()
        got["swap_AC"] = t.measure(SA, SC, True).d1
        got["swap_AB"] = t.measure(SA, SB, False).d1

        state = {
            "h_saturated_final": t.measure(SA, SB, True).a.h_saturated,
            "weight_stats": t.weight_stats(),
            "update_count": t.update_count,
        }
        return {"integers": got, "state": state}
    finally:
        tw.h_update = keep


def main() -> int:
    gc = golden_check()
    if not gc["pass"]:
        print("REFUSE: twin no longer reproduces A0.1-T goldens; cannot predict "
              "a new law from a drifted oracle.", gc["mismatch"])
        return 2

    asis = replay(tw.h_update)
    signed = replay(h_update_signed)

    print("A0.1-T law  eam03e-a0-signsgd-v1   (frozen, regression authority)")
    for k, v in asis["integers"].items():
        print(f"  {k:<10} {v}")
    print()
    print(f"PREDICTED   {LAW_A03}   (pre-registered, RTL must reproduce)")
    for k, v in signed["integers"].items():
        print(f"  {k:<10} {v}")
    print()
    print("h saturated coords in final A forward:",
          f"as-is {asis['state']['h_saturated_final']}/32,",
          f"signed {signed['state']['h_saturated_final']}/32")

    rec = {
        "law": LAW_A03,
        "parent_law": "eam03e-a0-signsgd-v1",
        "status": "PRE-REGISTERED PREDICTION, no RTL exists yet",
        "evidence_class": "REFERENCE_MODEL",
        "change_under_test": "signedness of the h update only",
        "seed": f"0x{SEED:08X}",
        "steps": STEPS,
        "strings": [SA, SB, SC],
        "a01t_reference": asis,
        "a03_predicted": signed,
        "twin_golden_check": gc["pass"],
        "rule": "h = e3_sat16((acc + $signed(e << 8)) >>> E3_SH), arithmetic shift",
        "ts": datetime.now(timezone.utc).isoformat(),
    }
    out = ROOT / "results" / "A7-EAM-03E" / "A03_SIGNED"
    out.mkdir(parents=True, exist_ok=True)
    path = out / "golden_a03_predicted.json"
    path.write_text(json.dumps(rec, indent=2), encoding="utf-8")
    print()
    print(path)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
