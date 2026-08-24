"""A7-LM-04 R3 confirmation ladder. Host compares only.

R2 evidence is immutable. This script writes only candidate_r3/.
K=257 once → K=511 once → K=513 once. No retry, no warm-up, no reprogram.
HELDOUT-R3 is evaluated once against the frozen recipe. No CE-based retry.
"""
from __future__ import annotations

import json
import math
import os
import sys
import time
from collections import Counter
from datetime import datetime, timezone
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT))
sys.path.insert(0, str(ROOT / "tools"))

import a7lm04_close_ladder as L  # noqa: E402
from python.ref.a7lm04_fixed_ref import (  # noqa: E402
    HEAD_EPOCHS,
    HEAD_LR,
    HELDOUT,
    HELDOUT_R3,
    HELDOUT_R3_SHA256,
    INIT_SEEDS_R3,
    PARAM_COUNT,
    RECIPE_R3,
    RECIPE_R3_SHA256,
    TinyGPT100k,
    corpus_sha256,
    recipe_sha256,
)
from python.ref.fixed_gemm import SEED0, run_explicit  # noqa: E402
from python.uart_frames import lm04_payload_frame  # noqa: E402
import serial  # noqa: E402

NPARAM = L.NPARAM
FAIL_BIT_SHA = L.FAIL_BIT_SHA
R2_BIT_SHA = "6BED0DE83922B45BABBD8D2DD0F46F0F469474CB9F0A8A1DF96D1421817EF6B9"
R3_BIT_NAME = "arty_a7_lm04r3.bit"
_REPLAY_ROOT = os.environ.get("A7_REPLAY_ROOT")
OUT_REL = (
    Path(_REPLAY_ROOT) / "A7-LM-04-R3"
    if _REPLAY_ROOT
    else Path("results") / "A7-LM-04" / "candidate_r3"
)
SEEDS = INIT_SEEDS_R3
CONSTANT_CLASS = 0.125
CE_DROP_MIN = 0.20
PRED_SHARE_MAX = 0.50
MIN_CLASSES_HIT = 6


def wilson_lb(k: int, n: int, z: float = 1.96) -> float:
    if n <= 0:
        return 0.0
    p = k / float(n)
    z2 = z * z
    denom = 1.0 + z2 / n
    centre = p + z2 / (2.0 * n)
    adj = z * math.sqrt((p * (1.0 - p) + z2 / (4.0 * n)) / n)
    return (centre - adj) / denom


def collapse_guard(pairs: list[dict]) -> dict:
    n = len(pairs)
    hits = [r for r in pairs if r.get("pred") is not None and r.get("pred") == r.get("t")]
    acc = (len(hits) / n) if n else 0.0
    preds = [r.get("pred") for r in pairs if r.get("pred") is not None]
    pred_counts = Counter(preds)
    top_share = (max(pred_counts.values()) / len(preds)) if preds else 1.0
    hit_tgts = {r["t"] for r in hits}
    all_tgts = {32 + k - 1 for k in range(1, 9)}
    classes_hit = len(hit_tgts & all_tgts)
    lb = wilson_lb(len(hits), n)
    ok = bool(
        acc > CONSTANT_CLASS
        and lb > CONSTANT_CLASS
        and classes_hit >= MIN_CLASSES_HIT
        and top_share <= PRED_SHARE_MAX
    )
    return {
        "n": n,
        "correct": len(hits),
        "acc": acc,
        "wilson_lb_95": lb,
        "classes_hit": classes_hit,
        "pred_counts": {str(k): int(v) for k, v in sorted(pred_counts.items())},
        "top_pred_share": top_share,
        "constant_class": CONSTANT_CLASS,
        "ok": ok,
    }


def k_issue_once(port, stream, k: int, cmd_log: list) -> dict:
    body = bytes([0x59, k & 0xFF, (k >> 8) & 0xFF]) + SEED0.to_bytes(4, "little") + bytes(5)
    L.send(port, lm04_payload_frame(body))
    cmd_log.append({"op": "0x59", "k": k})
    ts = L.wait_tensor(port, stream, 90.0)
    return ts or {}


def k_run(port, stream, k: int, cmd_log: list) -> dict:
    """Exactly one 0x59. First fold is the scored fold."""
    ts = k_issue_once(port, stream, k, cmd_log)
    fd = L.tfold(port, stream)
    c2 = L.tcnt2(port, stream)
    ov = L.tovl(port, stream)
    exp = run_explicit(0, 1, 128, k, 0, SEED0)
    match = bool(fd and fd["xor32"] == exp["xor32"] and fd["add32"] == exp["add32"] and fd["macs"] == exp["macs"])
    issues = sum(1 for e in cmd_log if e.get("op") == "0x59" and e.get("k") == k)
    ok = bool(
        match
        and issues == 1
        and c2
        and c2["swaps"] > 0
        and c2["dma_under"] == 0
        and c2["bank_haz"] == 0
        and c2["axi_berr"] == 0
        and c2["axi_rerr"] == 0
        and ov
        and ov["overlap_cyc"] > 0
        and ov["ntile"] >= 2
    )
    rec = {
        "k": k,
        "issue_count": issues,
        "first_try": issues == 1,
        "match": match,
        "fold": fd,
        "expected": {"xor32": exp["xor32"], "add32": exp["add32"], "macs": exp["macs"]},
        "counters2": c2,
        "overlap": ov,
        "tstatus": {kk: ts.get(kk) for kk in ("t_busy", "cases", "phase") if kk in ts},
        "ok": ok,
    }
    L.log(f"K={k} first_try issue_count={issues} match={match} ok={ok}")
    return rec


def heldout_sum_r3(port, stream) -> dict:
    L.set_after(port, True)
    L.wait_idle(port, stream, 2.0)
    total = 0
    pairs = []
    for pref, tgt in HELDOUT_R3:
        L.load_ctx(port, pref)
        L.send(port, lm04_payload_frame(bytes([0x34, tgt & 0xFF, HEAD_LR]) + bytes(9)))
        st = L.wait_idle(port, stream, 30.0)
        loss = None if not st else st.get("loss")
        pred = None if not st else st.get("pred")
        if loss is None:
            pairs.append({"p": pref, "t": tgt, "loss": None, "pred": pred})
            continue
        total += int(loss)
        pairs.append({"p": pref, "t": tgt, "loss": int(loss), "pred": pred})
    L.set_after(port, False)
    n = len(HELDOUT_R3)
    ppl = None if any(r["loss"] is None for r in pairs) else math.exp(total / max(1, n))
    return {
        "ce": total if all(r["loss"] is not None for r in pairs) else None,
        "ppl": ppl,
        "pairs": pairs,
        "collapse": collapse_guard(pairs),
    }


def heldout_seeds(port, stream) -> dict:
    recs = []
    for seed in SEEDS:
        L.log(f"=== R3 held-out seed {seed} upload ===")
        L.set_after(port, False)
        L.upload(port, TinyGPT100k(seed).flat_i8())
        before = heldout_sum_r3(port, stream)
        L.log(f"  ce0={before['ce']} ppl0={before['ppl']}")
        L.send(port, lm04_payload_frame(bytes([0x3A, 8, HEAD_EPOCHS, HEAD_LR]) + bytes(8)))
        st = L.wait_idle(port, stream, 1200.0)
        train_ce = L.ce_page(port, stream)
        L.log(f"  train_status {st} train_ce {train_ce}")
        L.train_board_full(port, stream, epochs=2)
        after = heldout_sum_r3(port, stream)
        L.log(f"  ce1={after['ce']} ppl1={after['ppl']}")
        c0, c1 = before["ce"], after["ce"]
        drop = None if not c0 else (c0 - c1) / float(c0)
        ppl_down = bool(before["ppl"] is not None and after["ppl"] is not None and after["ppl"] < before["ppl"])
        degrade = None if c0 is None or c1 is None else (c1 - c0) / float(c0) if c0 else 0.0
        recs.append(
            {
                "seed": seed,
                "ce0": c0,
                "ce1": c1,
                "drop": drop,
                "ppl0": before["ppl"],
                "ppl1": after["ppl"],
                "ppl_down": ppl_down,
                "degrade": degrade,
                "train_ce": train_ce,
                "train_status": st,
                "before": before,
                "after": after,
                "collapse": after.get("collapse"),
            }
        )
    drops = [r["drop"] for r in recs if r["drop"] is not None]
    med = None if len(drops) < 3 else sorted(drops)[1]
    collapse_ok = all((r.get("collapse") or {}).get("ok") for r in recs)
    ok = bool(
        med is not None
        and med >= CE_DROP_MIN
        and all(r["ppl_down"] for r in recs)
        and all(r["degrade"] is not None and r["degrade"] <= 0.02 for r in recs)
        and collapse_ok
    )
    return {
        "seeds": recs,
        "median_drop": med,
        "ce_drop_min": CE_DROP_MIN,
        "collapse_ok": collapse_ok,
        "ok": ok,
    }


def static_checks() -> dict:
    out_dir = ROOT / "build" / "out"
    bits = {}
    ok_frozen = True
    for name, exp in L.FROZEN.items():
        got = L.sha256_file(out_dir / name)
        bits[name] = {"exp": exp, "got": got, "match": got == exp}
        ok_frozen = ok_frozen and got == exp
    fail_bit = L.sha256_file(out_dir / "arty_a7_lm04.bit")
    r2 = L.sha256_file(out_dir / "arty_a7_lm04r.bit")
    r3_path = out_dir / R3_BIT_NAME
    r3 = L.sha256_file(r3_path) if r3_path.exists() else ""
    mig = L.sha256_file(ROOT / "third_party" / "digilent" / "arty-a7-100" / "E.0" / "1.0" / "mig.prj")
    hsha = corpus_sha256(HELDOUT_R3)
    wns, tns = L.parse_timing(out_dir / "a7lm04r3_timing_route.rpt")
    fail_ok = fail_bit == FAIL_BIT_SHA
    r2_ok = r2 == R2_BIT_SHA
    r3_ok = bool(r3) and r3 != FAIL_BIT_SHA and r3 != R2_BIT_SHA
    rec_ok = recipe_sha256(RECIPE_R3) == RECIPE_R3_SHA256
    r2_overlap = {tuple(p) for p, _ in HELDOUT} & {tuple(p) for p, _ in HELDOUT_R3}
    return {
        "param_count": PARAM_COUNT,
        "param_ok": PARAM_COUNT == 100352,
        "frozen_bits": bits,
        "frozen_ok": ok_frozen,
        "fail_candidate_bit": {"got": fail_bit, "exp": FAIL_BIT_SHA, "match": fail_ok},
        "r2_bit_preserved": {"got": r2, "exp": R2_BIT_SHA, "match": r2_ok},
        "lm04_bit": {"got": r3, "name": R3_BIT_NAME, "ne_fail": r3_ok, "match": r3_ok},
        "mig_prj": {"got": mig, "exp": L.MIG_SHA, "match": mig == L.MIG_SHA},
        "heldout_r3_sha": {
            "got": hsha,
            "exp": HELDOUT_R3_SHA256,
            "match": hsha == HELDOUT_R3_SHA256,
            "disjoint_r2": len(r2_overlap) == 0,
        },
        "recipe": {"sha": RECIPE_R3_SHA256, "match": rec_ok, "body": RECIPE_R3},
        "init_seeds": list(SEEDS),
        "wns": wns,
        "tns": tns,
        "wns_close_ok": wns is not None and tns is not None and wns >= 0.0 and tns == 0.0,
        "wns_lm05_ok": bool(wns is not None and wns >= 0.20 and tns == 0.0),
        "fail_bit_preserved": fail_ok,
        "r2_preserved": r2_ok,
    }


def write_manifest(out_dir: Path, summary: dict) -> None:
    gates = summary.get("gates") or {}
    ho = summary.get("heldout") or {}
    ping = summary.get("pingpong") or {}
    k513 = ping.get("513") or {}
    static = summary.get("static") or {}
    manifest = {
        "all_gates": bool(summary.get("pass")),
        "k513_first_try": bool(k513.get("first_try") and k513.get("match") and k513.get("issue_count") == 1),
        "heldout_used_for_tuning": False,
        "class_collapse_guard": bool(ho.get("collapse_ok")),
        "wns_lm05_ok": bool(static.get("wns_lm05_ok") and summary.get("pass")),
        "claim": summary.get("claim"),
        "recipe_sha256": RECIPE_R3_SHA256,
        "heldout_r3_sha256": HELDOUT_R3_SHA256,
        "bit_name": R3_BIT_NAME,
        "bit_sha256": (static.get("lm04_bit") or {}).get("got"),
        "r2_bit_sha256": R2_BIT_SHA,
        "fail_bit_sha256": FAIL_BIT_SHA,
        "gates": gates,
        "written_utc": datetime.now(timezone.utc).isoformat(),
    }
    (out_dir / "MANIFEST.json").write_text(json.dumps(manifest, indent=2), encoding="utf-8")


def main() -> int:
    port_name = sys.argv[1] if len(sys.argv) > 1 else "COM12"
    out_dir = ROOT / OUT_REL
    out_dir.mkdir(parents=True, exist_ok=True)
    fail_ladder = ROOT / "results" / "A7-LM-04" / "ladder.json"
    r2_ladder = ROOT / "results" / "A7-LM-04" / "candidate_r2" / "ladder.json"
    if out_dir.resolve() == fail_ladder.parent.resolve():
        raise SystemExit("refuse to overwrite FAIL candidate ladder.json")
    if out_dir.resolve() == r2_ladder.parent.resolve():
        raise SystemExit("refuse to overwrite candidate_r2")
    if not r2_ladder.exists():
        raise SystemExit("R2 validation evidence missing; refuse to run R3")

    summary: dict = {
        "started_utc": datetime.now(timezone.utc).isoformat(),
        "port": port_name,
        "revision": "A7-LM-04-R3",
        "heldout_used_for_tuning": False,
        "recipe_sha256": RECIPE_R3_SHA256,
        "gates": {},
        "pass": False,
        "claim": None,
        "lm05_authorized": False,
        "cmd_log": [],
    }
    static = static_checks()
    summary["static"] = static
    L.log(json.dumps({"static_ok": {k: static[k] for k in (
        "param_ok", "frozen_ok", "lm04_bit", "mig_prj", "heldout_r3_sha", "recipe", "wns", "r2_bit_preserved"
    )}}, indent=2))
    if not static["lm04_bit"]["match"]:
        summary["reason"] = "missing_or_colliding_r3_bit"
        (out_dir / "ladder.json").write_text(json.dumps(summary, indent=2), encoding="utf-8")
        write_manifest(out_dir, summary)
        return 2

    port = serial.Serial(port_name, 115200, timeout=0.05)
    time.sleep(0.4)
    stream = L.FrameStream(port)
    cmd_log: list = []
    try:
        cal = L.wait_calib(port, stream)
        summary["calib"] = cal
        L.log(f"calib {cal}")
        if not cal or not cal.get("calib"):
            summary["reason"] = "no_calib"
            (out_dir / "ladder.json").write_text(json.dumps(summary, indent=2), encoding="utf-8")
            write_manifest(out_dir, summary)
            return 2

        ks = {}
        for k in (257, 511, 513):
            L.log(f"=== ping-pong K={k} FIRST TRY (same session, no reprogram, no retry) ===")
            ks[str(k)] = k_run(port, stream, k, cmd_log)
        summary["pingpong"] = ks
        summary["cmd_log"] = cmd_log
        k513_issues = sum(1 for e in cmd_log if e.get("op") == "0x59" and e.get("k") == 513)
        summary["consecutive_tensor"] = {
            "k257_511_513": all(ks[str(k)].get("ok") for k in (257, 511, 513)),
            "k513_first_try": bool(ks["513"].get("first_try") and ks["513"].get("match") and k513_issues == 1),
            "tensor_0x59_count": sum(1 for e in cmd_log if e.get("op") == "0x59"),
            "note": "one COM session after a single program of arty_a7_lm04r3.bit; before persist; one issue per K",
        }

        L.log("=== requant +sat/-sat/non-sat (same session) ===")
        summary["requant"] = L.requant_gate(port, stream)
        summary["one_full"] = L.one_full(port, stream)
        summary["after"] = L.after_gate(port, stream)

        L.log("=== R3 confirmation held-out 3 new seeds (once) ===")
        summary["heldout"] = heldout_seeds(port, stream)
        summary["status_end"] = L.status(port, stream)
    finally:
        port.close()

    of = summary.get("one_full") or {}
    rq = summary.get("requant") or {}
    ho = summary.get("heldout") or {}
    ct = summary.get("consecutive_tensor") or {}
    gates = {
        "param_count": bool(static["param_ok"]),
        "mig_prj_sha": bool(static["mig_prj"]["match"]),
        "frozen_00_03_sha": bool(static["frozen_ok"]),
        "lm04r3_bit_sha": bool(static["lm04_bit"]["match"]),
        "r2_bit_preserved": bool(static["r2_preserved"]),
        "fail_bit_preserved": bool(static.get("fail_bit_preserved")),
        "heldout_r3_sha_frozen": bool(static["heldout_r3_sha"]["match"] and static["heldout_r3_sha"]["disjoint_r2"]),
        "recipe_sha_frozen": bool(static["recipe"]["match"]),
        "wns_tns": bool(static["wns_close_ok"]),
        "spot_upload": bool(of.get("spot_ok")),
        "fold0": bool(of.get("match0")),
        "one_full_fold": bool(of.get("match1")),
        "one_full_ne_head_only": bool(of.get("ne_head_only")),
        "next_token_fpga": bool(of.get("pred_ok")),
        "persist_reload_fold": bool(of.get("match_persist")),
        "k257": bool((summary.get("pingpong") or {}).get("257", {}).get("ok")),
        "k511": bool((summary.get("pingpong") or {}).get("511", {}).get("ok")),
        "k513_first_try": bool(ct.get("k513_first_try")),
        "consecutive_tensor": bool(ct.get("k257_511_513")),
        "requant_counts": bool(rq.get("ok")),
        "after_zero_writes": bool((summary.get("after") or {}).get("ok")),
        "heldout_median_20pct": bool(ho.get("ok")),
        "class_collapse_guard": bool(ho.get("collapse_ok")),
        "heldout_used_for_tuning": False,
    }
    summary["gates"] = gates
    # heldout_used_for_tuning must stay false; every other gate must be true.
    summary["pass"] = all(
        (v is False) if k == "heldout_used_for_tuning" else bool(v)
        for k, v in gates.items()
    )
    summary["lm05_authorized"] = False
    if summary["pass"] and static.get("wns_lm05_ok"):
        summary["claim"] = "ARTY_A7_100K_DDR_ONLINE_LM_BOARD_VALIDATED"
        summary["lm05_authorized"] = True
    summary["ended_utc"] = datetime.now(timezone.utc).isoformat()
    (out_dir / "ladder.json").write_text(json.dumps(summary, indent=2), encoding="utf-8")
    write_manifest(out_dir, summary)
    L.log(json.dumps({
        "gates": gates,
        "pass": summary["pass"],
        "claim": summary["claim"],
        "k513_first_try": ct.get("k513_first_try"),
        "heldout_median": ho.get("median_drop"),
    }, indent=2))
    return 0 if summary["pass"] else 1


if __name__ == "__main__":
    raise SystemExit(main())
