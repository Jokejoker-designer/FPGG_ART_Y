"""One-shot conjunctive A7-LM-04 R5 board close ladder.

Run only after programming the frozen R5 bit:
  python tools/a7lm04_close_ladder_r5.py COM12

The script writes only results/A7-LM-04/candidate_r5/board/. It refuses a
second scored run. Host code supplies stimuli and compares against the frozen
oracle; all parameter updates are executed by opcode 0x34 on the FPGA.
"""
from __future__ import annotations

import hashlib
import json
import math
import sys
import time
from collections import Counter
from datetime import datetime, timezone
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT))
sys.path.insert(0, str(ROOT / "tools"))

import serial  # noqa: E402
import a7lm04_close_ladder as L  # noqa: E402
import a7lm04_close_ladder_r3 as R3  # noqa: E402
from python.ref.a7lm04_fixed_ref import TinyGPT100k, fold_bytes  # noqa: E402
from python.uart_frames import lm04_payload_frame  # noqa: E402
from tools._r5_dev_target_switch import wilson_lb  # noqa: E402

R5_ROOT = ROOT / "results" / "A7-LM-04" / "candidate_r5"
BOARD_OUT = R5_ROOT / "board"
PREREG_PATH = R5_ROOT / "preregister.json"
ORACLE_PATH = R5_ROOT / "oracle_confirmation.json"
BUILD_PATH = R5_ROOT / "build_manifest.json"
EXPECTED_PREREG_SHA = "28073459CAC369E0FBC73A7B93CA1D79A983E2CDF481B57B76CBB532F0A595A2"
EXPECTED_ORACLE_SHA = "CB4DE357C7D5CAD596F07466959AC3AE2F9EF55890462BA830BF7CFAEB4C0DBB"
EXPECTED_SOURCES = {
    "rtl/control/tensor_microseq.sv": "2C3A3EF52FB8C7DDC2B2CF4808A62EB0B0BBFB0ECAF46B72BE260F6AA370C996",
    "rtl/lm/tiny_gpt100k_core.sv": "D5B23E12772A95B36759AB90123B555B11100B50103F49234FAA56DCAF91706C",
}


def sha(path: Path) -> str:
    h = hashlib.sha256()
    with path.open("rb") as handle:
        for chunk in iter(lambda: handle.read(1 << 20), b""):
            h.update(chunk)
    return h.hexdigest().upper()


def board_eval(port, stream, prefixes: list[list[int]], target: int) -> dict:
    L.set_after(port, True)
    L.wait_idle(port, stream, 2.0)
    pairs = []
    for prefix in prefixes:
        L.load_ctx(port, prefix)
        L.send(port, lm04_payload_frame(bytes([0x34, target & 0xFF, 3]) + bytes(9)))
        st = L.wait_idle(port, stream, 60.0)
        pairs.append({
            "prefix": prefix,
            "pred": None if st is None else st.get("pred"),
            "loss": None if st is None else st.get("loss"),
        })
    L.set_after(port, False)
    valid = [row for row in pairs if row["pred"] is not None and row["loss"] is not None]
    counts = Counter(row["pred"] for row in valid)
    correct = sum(row["pred"] == target for row in valid)
    ce = sum(int(row["loss"]) for row in valid) if len(valid) == len(prefixes) else None
    return {
        "n": len(prefixes),
        "ce": ce,
        "mean_last_loss": None if ce is None else ce / len(prefixes),
        "correct": correct,
        "accuracy": correct / len(prefixes),
        "wilson_lb_95": wilson_lb(correct, len(prefixes)),
        "target_share": counts.get(target, 0) / len(prefixes),
        "dominant_pred": None if not counts else counts.most_common(1)[0][0],
        "pred_counts": {str(k): v for k, v in sorted(counts.items())},
        "pairs": pairs,
    }


def ref_eval(model: TinyGPT100k, prefixes: list[list[int]], target: int) -> dict:
    pairs = []
    for prefix in prefixes:
        _, pred = model.forward(prefix)
        pairs.append({"prefix": prefix, "pred": pred, "loss": model.last_loss(prefix, target)})
    return {"pairs": pairs}


def exact_pairs(board: dict, reference: dict) -> bool:
    return board.get("pairs") == reference.get("pairs")


def train_target(port, stream, prefixes: list[list[int]], target: int) -> dict:
    L.set_after(port, False)
    statuses = []
    for prefix in prefixes:
        L.load_ctx(port, prefix)
        L.send(port, lm04_payload_frame(bytes([0x34, target & 0xFF, 3]) + bytes(9)))
        st = L.wait_idle(port, stream, 180.0)
        statuses.append({
            "prefix": prefix,
            "pred": None if st is None else st.get("pred"),
            "loss": None if st is None else st.get("loss"),
            "wr_n": None if st is None else st.get("wr_n"),
            "busy": None if st is None else st.get("busy"),
        })
    return {"updates": len(statuses), "all_completed": all(row["busy"] is False for row in statuses), "statuses": statuses}


def multitoken_spot(port, stream) -> dict:
    L.set_after(port, False)
    model = TinyGPT100k(17)
    L.upload(port, model.flat_i8())
    before = L.status(port, stream) or {}
    L.set_after(port, True)
    L.load_ctx(port, [20, 7])
    L.send(port, lm04_payload_frame(bytes([0x34, 16, 3]) + bytes(9)))
    st = L.wait_idle(port, stream, 60.0) or {}
    L.set_after(port, False)
    return {
        "prefix": [20, 7],
        "target": 16,
        "pred": st.get("pred"),
        "loss": st.get("loss"),
        "wr_before": before.get("wr_n"),
        "wr_after": st.get("wr_n"),
        "expected_pred": 140,
        "expected_loss": 16,
        "ok": st.get("pred") == 140 and st.get("loss") == 16 and before.get("wr_n") == st.get("wr_n"),
    }


def quality_confirmation(port, stream, prereg: dict, oracle: dict) -> dict:
    oracle_rows = {(row["seed"], row["target"]): row for row in oracle["rows"]}
    rows = []
    for seed in prereg["init_seeds"]:
        final_folds = []
        for target in prereg["targets"]:
            L.log(f"=== R5 board confirmation seed={seed} target={target} ===")
            model = TinyGPT100k(seed)
            L.set_after(port, False)
            L.upload(port, model.flat_i8())
            initial_fold = L.fold(port, stream)
            expected_initial = fold_bytes(model.flat_i8())
            before = board_eval(port, stream, prereg["heldout_prefixes"], target)
            before_ref = ref_eval(model, prereg["heldout_prefixes"], target)
            train = train_target(port, stream, prereg["train_prefixes"], target)
            for prefix in prereg["train_prefixes"]:
                model.backward_full(prefix, target, lr=3, apply=True)
            after = board_eval(port, stream, prereg["heldout_prefixes"], target)
            after_ref = ref_eval(model, prereg["heldout_prefixes"], target)
            final_fold = L.fold(port, stream)
            oracle_row = oracle_rows[(seed, target)]
            expected_final = oracle_row["final_weight_fold"]
            c0, c1 = before.get("ce"), after.get("ce")
            drop = None if not c0 else (c0 - c1) / float(c0)
            parity = {
                "initial_fold": bool(initial_fold and initial_fold["xor32"] == expected_initial["xor32"] and initial_fold["add32"] == expected_initial["add32"]),
                "before_pairs": exact_pairs(before, before_ref),
                "after_pairs": exact_pairs(after, after_ref),
                "final_fold": bool(final_fold and final_fold["xor32"] == expected_final["xor32"] and final_fold["add32"] == expected_final["add32"]),
                "oracle_aggregate": bool(
                    before.get("ce") == oracle_row["before"]["ce"]
                    and after.get("ce") == oracle_row["after"]["ce"]
                    and after.get("correct") == oracle_row["after"]["correct"]
                ),
            }
            row = {
                "seed": seed,
                "target": target,
                "before": before,
                "after": after,
                "ce_drop": drop,
                "train": train,
                "initial_fold": initial_fold,
                "final_fold": final_fold,
                "expected_final_fold": expected_final,
                "parity": parity,
                "pass": bool(
                    train["updates"] == 16
                    and train["all_completed"]
                    and all(parity.values())
                    and after["accuracy"] >= prereg["gates"]["accuracy_each"]
                    and after["wilson_lb_95"] >= prereg["gates"]["wilson_lb_95_each"]
                    and after["dominant_pred"] == target
                ),
            }
            rows.append(row)
            final_folds.append((final_fold or {}).get("xor32", -1) << 32 | (final_fold or {}).get("add32", -1))
            L.log(f"seed={seed} target={target} CE={c0}->{c1} acc={after['accuracy']:.4f} parity={all(parity.values())}")
        if len(set(final_folds)) != len(prereg["targets"]):
            L.log(f"seed={seed} final board folds are not target-distinct")
    drops = sorted(row["ce_drop"] for row in rows if row["ce_drop"] is not None)
    median = None if len(drops) != len(rows) else (drops[len(drops) // 2 - 1] + drops[len(drops) // 2]) / 2.0
    distinct = all(
        len({((row["final_fold"] or {}).get("xor32"), (row["final_fold"] or {}).get("add32")) for row in rows if row["seed"] == seed})
        == len(prereg["targets"])
        for seed in prereg["init_seeds"]
    )
    return {
        "rows": rows,
        "median_ce_drop": median,
        "worst_accuracy": min(row["after"]["accuracy"] for row in rows),
        "worst_wilson_lb_95": min(row["after"]["wilson_lb_95"] for row in rows),
        "distinct_target_board_folds_per_seed": distinct,
        "all_exact_parity": all(all(row["parity"].values()) for row in rows),
        "pass": bool(
            all(row["pass"] for row in rows)
            and median is not None
            and median >= prereg["gates"]["median_ce_drop"]
            and distinct
        ),
    }


def main() -> int:
    port_name = sys.argv[1] if len(sys.argv) > 1 else "COM12"
    ladder_path = BOARD_OUT / "ladder.json"
    if ladder_path.exists():
        raise RuntimeError(f"R5 board confirmation already scored; refuse rerun: {ladder_path}")
    if sha(PREREG_PATH) != EXPECTED_PREREG_SHA or sha(ORACLE_PATH) != EXPECTED_ORACLE_SHA:
        raise RuntimeError("preregister or one-shot oracle evidence changed")
    for rel, expected in EXPECTED_SOURCES.items():
        if sha(ROOT / rel) != expected:
            raise RuntimeError(f"frozen R5 source changed: {rel}")
    prereg = json.loads(PREREG_PATH.read_text(encoding="utf-8"))
    oracle = json.loads(ORACLE_PATH.read_text(encoding="utf-8"))
    build = json.loads(BUILD_PATH.read_text(encoding="utf-8"))
    bit_sha = sha(ROOT / build["bit"])
    if bit_sha != build["bit_sha256"] or build["wns_ns"] < 0.0 or build["tns_ns"] != 0.0:
        raise RuntimeError("frozen build manifest does not match bit/timing gate")

    BOARD_OUT.mkdir(parents=True, exist_ok=True)
    summary = {
        "revision": "A7-LM-04-R5",
        "started_utc": datetime.now(timezone.utc).isoformat(),
        "port": port_name,
        "law_id": "lm05-signsgd-v1",
        "bit_sha256": bit_sha,
        "claim_scope": prereg["claim_scope"],
        "negative_claims": prereg["negative_claims"],
        "confirmation_used_for_tuning": False,
        "pass": False,
        "claim": None,
    }
    port = serial.Serial(port_name, 115200, timeout=0.05)
    time.sleep(0.5)
    stream = L.FrameStream(port)
    try:
        summary["calib"] = L.wait_calib(port, stream)
        if not summary["calib"] or not summary["calib"].get("calib"):
            raise RuntimeError("DDR calibration/status gate failed")
        command_log = []
        summary["pingpong"] = {}
        for k in (257, 511, 513):
            summary["pingpong"][str(k)] = R3.k_run(port, stream, k, command_log)
        summary["tensor_command_log"] = command_log
        summary["requant"] = L.requant_gate(port, stream)
        summary["one_full"] = L.one_full(port, stream)
        summary["after"] = L.after_gate(port, stream)
        summary["multitoken_forward"] = multitoken_spot(port, stream)
        summary["quality"] = quality_confirmation(port, stream, prereg, oracle)
        summary["status_end"] = L.status(port, stream)
    except Exception as exc:
        summary["runtime_error"] = f"{type(exc).__name__}: {exc}"
    finally:
        port.close()

    ping = summary.get("pingpong", {})
    one = summary.get("one_full", {})
    gates = {
        "frozen_build": bit_sha == build["bit_sha256"],
        "timing_wns_tns": build["wns_ns"] >= 0.0 and build["tns_ns"] == 0.0,
        "ddr_calibration": bool((summary.get("calib") or {}).get("calib")),
        "k257_first_try": bool((ping.get("257") or {}).get("ok") and (ping.get("257") or {}).get("issue_count") == 1),
        "k511_first_try": bool((ping.get("511") or {}).get("ok") and (ping.get("511") or {}).get("issue_count") == 1),
        "k513_first_try": bool((ping.get("513") or {}).get("ok") and (ping.get("513") or {}).get("issue_count") == 1),
        "requant": bool((summary.get("requant") or {}).get("ok")),
        "upload_spots_fold": bool(one.get("spot_ok") and one.get("match0")),
        "one_full_update": bool(one.get("match1") and one.get("ne_head_only") and one.get("pred_ok")),
        "ddr_persist_reload": bool(one.get("match_persist")),
        "after_zero_writes": bool((summary.get("after") or {}).get("ok")),
        "multitoken_forward_exact": bool((summary.get("multitoken_forward") or {}).get("ok")),
        "r5_quality_and_exact_parity": bool((summary.get("quality") or {}).get("pass")),
        "confirmation_used_for_tuning": False,
    }
    summary["gates"] = gates
    summary["pass"] = all((value is False) if key == "confirmation_used_for_tuning" else bool(value) for key, value in gates.items())
    if summary["pass"]:
        summary["claim"] = "ARTY_A7_100K_DDR_ONLINE_LM_BOARD_VALIDATED"
    summary["ended_utc"] = datetime.now(timezone.utc).isoformat()
    ladder_path.write_text(json.dumps(summary, indent=2) + "\n", encoding="utf-8")
    manifest = {
        "revision": summary["revision"],
        "all_gates": summary["pass"],
        "claim": summary["claim"],
        "claim_scope": summary["claim_scope"],
        "negative_claims": summary["negative_claims"],
        "law_id": summary["law_id"],
        "bit_sha256": bit_sha,
        "ladder_sha256": sha(ladder_path),
        "gates": gates,
        "written_utc": datetime.now(timezone.utc).isoformat(),
    }
    (BOARD_OUT / "MANIFEST.json").write_text(json.dumps(manifest, indent=2) + "\n", encoding="utf-8")
    L.log(json.dumps({"pass": summary["pass"], "claim": summary["claim"], "gates": gates}, indent=2))
    return 0 if summary["pass"] else 1


if __name__ == "__main__":
    raise SystemExit(main())
