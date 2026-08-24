"""A7-LM-01 board ladder. Does not claim PASS unless every contract gate is met."""
from __future__ import annotations

import argparse
import json
import time
from datetime import datetime, timezone
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
import sys

sys.path.insert(0, str(ROOT))
from python.uart_stream import FrameStream
from tools.ddr_bist import MEM_BYTES, counters, run_bist, soft_reset, status, wait_calib
import serial

MODE_NAME = {
    0: "all",
    1: "walk",
    2: "addr",
    3: "prbs",
    4: "seq",
    5: "rand",
    6: "bound",
}
SIZE_BYTES = {0: 0x0010_0000, 1: 0x0100_0000, 2: 0x1000_0000}


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--port", default="COM12")
    ap.add_argument("--quick", action="store_true", help="1MB patterns only; skip 256MB and 100-recal")
    ap.add_argument("--recal", type=int, default=100)
    args = ap.parse_args()

    out_dir = ROOT / "results" / "A7-LM-01"
    out_dir.mkdir(parents=True, exist_ok=True)

    port = serial.Serial(args.port, 115200, timeout=0.05)
    time.sleep(0.4)
    stream = FrameStream(port)

    summary: dict = {
        "started_utc": datetime.now(timezone.utc).isoformat(),
        "port": args.port,
        "quick": args.quick,
        "runs": [],
        "recal": None,
        "bytes_written": 0,
        "bytes_read": 0,
        "gates": {},
        "pass": False,
    }

    st0 = wait_calib(port, stream, 10.0)
    summary["status0"] = st0
    if not st0 or not st0["calib"]:
        summary["reason"] = "no_calib"
        (out_dir / "ladder.json").write_text(json.dumps(summary, indent=2), encoding="utf-8")
        print(json.dumps(summary, indent=2))
        port.close()
        return 2

    plan = [
        ("walk_1mb", 1, 0, 60.0),
        ("walk0_via_all_1mb", 0, 0, 180.0),
        ("addr_1mb", 2, 0, 60.0),
        ("prbs_1mb", 3, 0, 60.0),
        ("seq_1mb", 4, 0, 60.0),
        ("rand_1mb", 5, 0, 60.0),
        ("bound_1mb", 6, 0, 60.0),
    ]
    if not args.quick:
        plan.extend(
            [
                ("seq_16mb", 4, 1, 180.0),
                ("seq_256mb", 4, 2, 600.0),
                ("seq_256mb_b", 4, 2, 600.0),
                ("rand_16mb", 5, 1, 180.0),
                ("all_16mb", 0, 1, 900.0),
            ]
        )

    all_ok = True
    bw_seq = None
    bw_wr = None
    bw_mix = None
    bw_rand = None
    for name, mode, size, wait_s in plan:
        print(f"=== {name} mode={mode} size={size} ===", flush=True)
        rec = run_bist(port, stream, mode, size, wait_s)
        rec["name"] = name
        rec["mode"] = mode
        rec["mode_name"] = MODE_NAME.get(mode, str(mode))
        rec["size_code"] = size
        rec["size_bytes"] = SIZE_BYTES[size]
        summary["runs"].append(rec)
        print(json.dumps(rec, indent=2), flush=True)
        (out_dir / f"{name}.json").write_text(json.dumps(rec, indent=2), encoding="utf-8")
        if not rec.get("pass"):
            all_ok = False
            break
        cnt = rec.get("counters") or {}
        summary["bytes_written"] += int(cnt.get("wr_bytes") or 0)
        summary["bytes_read"] += int(cnt.get("rd_bytes") or 0)
        if mode == 4:
            bw_seq = cnt.get("rd_gbps")
            bw_wr = cnt.get("wr_gbps")
            bw_mix = cnt.get("mix_gbps")
        if mode == 5:
            bw_rand = cnt.get("rd_gbps")

    equiv = (summary["bytes_written"] + summary["bytes_read"]) / MEM_BYTES
    summary["whole_memory_equivalents"] = equiv
    summary["bw"] = {
        "seq_rd_gbps": bw_seq,
        "seq_wr_gbps": bw_wr,
        "mixed_gbps": bw_mix,
        "rand_rd_gbps": bw_rand,
    }

    recal_ok = 0
    recal_fail = 0
    if all_ok and not args.quick and args.recal > 0:
        print(f"=== soft-reset recal {args.recal} ===", flush=True)
        for i in range(args.recal):
            r = soft_reset(port, stream, 8.0)
            if r.get("ok"):
                recal_ok += 1
            else:
                recal_fail += 1
                print(f"recal fail at {i}: {r}", flush=True)
                break
            if (i + 1) % 10 == 0:
                print(f"recal {i+1}/{args.recal} ok", flush=True)
        summary["recal"] = {"ok": recal_ok, "fail": recal_fail, "target": args.recal}
        if recal_ok == args.recal:
            print("=== post_recal_seq_1mb ===", flush=True)
            rec = run_bist(port, stream, 4, 0, 60.0)
            rec["name"] = "post_recal_seq_1mb"
            summary["runs"].append(rec)
            (out_dir / "post_recal_seq_1mb.json").write_text(json.dumps(rec, indent=2), encoding="utf-8")
            print(json.dumps(rec, indent=2), flush=True)
            if not rec.get("pass"):
                all_ok = False

    names = {r["name"] for r in summary["runs"] if r.get("pass")}
    gates = {
        "calib_first": bool(st0 and st0["calib"]),
        "walk": "walk_1mb" in names,
        "walk0_via_all": "walk0_via_all_1mb" in names,
        "addr": "addr_1mb" in names,
        "prbs": "prbs_1mb" in names,
        "seq": "seq_1mb" in names,
        "rand": "rand_1mb" in names,
        "bound": "bound_1mb" in names,
        "whole_memory_ge_4": equiv >= 4.0,
        "seq_rd_ge_0p85": bool(bw_seq is not None and bw_seq >= 0.85),
        "wr_bw_recorded": bw_wr is not None,
        "mix_bw_recorded": bw_mix is not None,
        "rand_bw_recorded": bw_rand is not None,
        "recal_100": bool(summary["recal"] and summary["recal"]["ok"] == args.recal and args.recal >= 100),
    }
    if args.quick:
        for k in ("whole_memory_ge_4", "seq_rd_ge_0p85", "recal_100"):
            gates[k] = False
    summary["gates"] = gates
    summary["pass"] = all(gates.values()) and all_ok
    summary["ended_utc"] = datetime.now(timezone.utc).isoformat()
    (out_dir / "ladder.json").write_text(json.dumps(summary, indent=2), encoding="utf-8")
    print(json.dumps(summary, indent=2))
    port.close()
    return 0 if summary["pass"] else 1


if __name__ == "__main__":
    raise SystemExit(main())
