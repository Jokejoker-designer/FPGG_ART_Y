"""One isolated tensor command after a fresh FPGA reset.

The LM-04 UART CDC misses the 1-cycle t_done pulse, so only the first
tensor start after reset is accepted. Isolate K / requant cases one
program at a time. Host compares only.
"""
from __future__ import annotations

import json
import sys
import time
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT))

from python.ref.fixed_gemm import SEED0, requant_hw_fold, run_case, run_explicit
from python.uart_frames import lm04_payload_frame
from tools.a7lm04_close_ladder import (
    classify_requant,
    dump_psums,
    oracle_requant_counts,
    tcnt2,
    tfold,
    tovl,
    wait_calib,
    wait_kind,
    wait_tensor,
    send,
    status,
)
from python.uart_stream import FrameStream
import serial


def k_run(port, stream, k: int) -> dict:
    body = bytes([0x59, k & 0xFF, (k >> 8) & 0xFF]) + SEED0.to_bytes(4, "little") + bytes(5)
    send(port, lm04_payload_frame(body))
    st = wait_tensor(port, stream, 90.0)
    fd = tfold(port, stream)
    c2 = tcnt2(port, stream)
    ov = tovl(port, stream)
    exp = run_explicit(0, 1, 128, k, 0, SEED0)
    match = bool(fd and fd["xor32"] == exp["xor32"] and fd["add32"] == exp["add32"] and fd["macs"] == exp["macs"])
    ok = bool(
        match
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
    return {
        "k": k,
        "started": bool(st and not st.get("t_busy")),
        "match": match,
        "fold": fd,
        "expected": {"xor32": exp["xor32"], "add32": exp["add32"], "macs": exp["macs"]},
        "counters2": c2,
        "overlap": ov,
        "ok": ok,
        "tstat": st,
    }


def case_run(port, stream, case_i: int, do_requant: bool = False) -> dict:
    p = run_case(case_i)
    body = bytes(
        [0x50, p["mode"] & 1, p["M"] & 15, p["N"] & 255, p["K"] & 255, (p["K"] >> 8) & 255]
    )
    body += SEED0.to_bytes(4, "little") + int(case_i).to_bytes(2, "little")
    send(port, lm04_payload_frame(body))
    wait_tensor(port, stream, 60.0)
    fd = tfold(port, stream)
    psums = dump_psums(port, stream)
    board_c = None if psums is None else classify_requant(psums, 0)
    exp_c = oracle_requant_counts(case_i, 0)
    match = bool(fd and fd["xor32"] == p["xor32"] and fd["add32"] == p["add32"])
    rec = {
        "i": case_i,
        "sat": bool(p["sat"]),
        "corner": bool(p["corner"]),
        "fold": fd,
        "exp_xor": p["xor32"],
        "exp_add": p["add32"],
        "fold_ok": match,
        "board_counts": board_c,
        "oracle_counts": exp_c,
        "count_match": board_c == exp_c,
    }
    if do_requant:
        # Second tensor cmd is expected to be dropped by the CDC; record anyway.
        send(port, lm04_payload_frame(bytes([0x58, 0]) + bytes(10)))
        wait_tensor(port, stream, 8.0)
        rq = tfold(port, stream)
        exp_x, exp_a = requant_hw_fold(p["P"], p["mode"], p["M"], p["N"], 0)
        rec["requant_0x58"] = {
            "fold": rq,
            "exp_xor": exp_x,
            "exp_add": exp_a,
            "ok": bool(rq and rq["xor32"] == exp_x and rq["add32"] == exp_a),
        }
    rec["ok"] = bool(match and rec["count_match"])
    return rec


def main() -> int:
    port_name = sys.argv[1] if len(sys.argv) > 1 else "COM12"
    mode = sys.argv[2] if len(sys.argv) > 2 else "k257"
    port = serial.Serial(port_name, 115200, timeout=0.05)
    time.sleep(0.5)
    stream = FrameStream(port)
    cal = wait_calib(port, stream, 25.0)
    print("calib", cal, flush=True)
    if not cal or not cal.get("calib"):
        port.close()
        print(json.dumps({"ok": False, "reason": "no_calib"}))
        return 2
    if mode.startswith("k"):
        k = int(mode[1:])
        rec = k_run(port, stream, k)
    elif mode.startswith("c"):
        rec = case_run(port, stream, int(mode[1:]), do_requant=False)
    else:
        rec = {"ok": False, "reason": f"bad mode {mode}"}
    port.close()
    out_dir = ROOT / "results" / "A7-LM-04"
    out_dir.mkdir(parents=True, exist_ok=True)
    (out_dir / f"tensor_{mode}.json").write_text(json.dumps(rec, indent=2), encoding="utf-8")
    print(json.dumps(rec, indent=2), flush=True)
    return 0 if rec.get("ok") else 1


if __name__ == "__main__":
    raise SystemExit(main())
