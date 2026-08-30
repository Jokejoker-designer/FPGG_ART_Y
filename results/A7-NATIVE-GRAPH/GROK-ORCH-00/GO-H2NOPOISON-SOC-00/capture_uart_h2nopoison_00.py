#!/usr/bin/env python3
"""Arm COM12 then listen. Use only after PREBUILD_READY + matching BRIDGE token
that names GO-H2PACK-SOC-00. Stop on pred=664 or EXIST_ROW. Record PACK=.
Never stamp BOARD_PASS.
"""
from __future__ import annotations

import argparse
import hashlib
import sys
import time
from datetime import datetime, timezone, timedelta
from pathlib import Path

try:
    import serial
except ImportError:
    print("NEED: pip install pyserial", file=sys.stderr)
    sys.exit(2)

TZ = timezone(timedelta(hours=7))
HERE = Path(__file__).resolve().parent
BIT_PATH = HERE / "arty_a7_ng_native_v1_grok_orch_h2pack_00.bit"
SHA_PATH = HERE / "BIT_SHA256.txt"
PRED_664 = "pred=664"
EXIST_ROW = "NATIVE_V1_EXIST_ROW"
GOLDEN_PACK = "PACK=3B392B291B190B09"


def open_com_no_reset(port: str, baud: int) -> serial.Serial:
    ser = serial.Serial()
    ser.port = port
    ser.baudrate = baud
    ser.bytesize = serial.EIGHTBITS
    ser.parity = serial.PARITY_NONE
    ser.stopbits = serial.STOPBITS_ONE
    ser.timeout = 0.25
    ser.write_timeout = 0
    ser.xonxoff = False
    ser.rtscts = False
    ser.dsrdtr = False
    ser.dtr = False
    ser.rts = False
    ser.open()
    ser.dtr = False
    ser.rts = False
    return ser


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--port", default="COM12")
    ap.add_argument("--baud", type=int, default=115200)
    ap.add_argument("--max-seconds", type=float, default=90.0)
    args = ap.parse_args()

    if not BIT_PATH.is_file() or not SHA_PATH.is_file():
        print("REFUSE missing bit or BIT_SHA256.txt PREBUILD_READY=NO", file=sys.stderr)
        return 3
    want = SHA_PATH.read_text(encoding="utf-8").strip().upper()
    h = hashlib.sha256()
    with BIT_PATH.open("rb") as fh:
        for chunk in iter(lambda: fh.read(1024 * 1024), b""):
            h.update(chunk)
    got = h.hexdigest().upper()
    if got != want:
        print(f"REFUSE bit SHA {got} want {want}", file=sys.stderr)
        return 3

    started = datetime.now(TZ).isoformat(timespec="seconds")
    ser = open_com_no_reset(args.port, args.baud)
    (HERE / "LISTEN_START.txt").write_text(
        "\n".join(
            [
                "gate=GO-H2PACK-SOC-00",
                "mode=ARMED_BEFORE_PROGRAM",
                "policy=BIT_FIRST_COM12_SECOND",
                f"port={args.port}",
                f"bit_sha256={got}",
                f"dtr={str(ser.dtr).lower()}",
                f"rts={str(ser.rts).lower()}",
                f"window_s={int(args.max_seconds)}",
                f"started_local={started}",
                "stop_early=NATIVE_V1_EXIST_ROW or pred=664",
                "h2=PACK=16hex vs 3B392B291B190B09",
                "BOARD_PASS=not_claimed",
                "",
            ]
        ),
        encoding="utf-8",
        newline="\n",
    )
    print(
        f"H2PACK_LISTEN {args.port} @{args.baud} start={started} dtr={ser.dtr} rts={ser.rts} ARMED",
        flush=True,
    )
    t0 = time.monotonic()
    buf = bytearray()
    stop_reason = "max_seconds"
    try:
        while True:
            chunk = ser.read(256)
            if chunk:
                buf.extend(chunk)
                sys.stdout.write(chunk.decode("ascii", errors="replace"))
                sys.stdout.flush()
            text = buf.decode("ascii", errors="replace")
            if PRED_664 in text:
                stop_reason = PRED_664
                print(f"\nSTOP_EARLY: {PRED_664}", flush=True)
                break
            if EXIST_ROW in text:
                stop_reason = EXIST_ROW
                print(f"\nSTOP_EARLY: {EXIST_ROW}", flush=True)
                break
            if (time.monotonic() - t0) >= args.max_seconds:
                break
    finally:
        ser.close()

    text = buf.decode("ascii", errors="replace")
    (HERE / "uart_h2pack_00.txt").write_text(text, encoding="utf-8", newline="\n")
    lines = [ln.strip() for ln in text.splitlines() if ln.strip()]
    pred_lines = [ln for ln in lines if "pred=" in ln]
    exist_row = [ln for ln in lines if EXIST_ROW in ln]
    pack_lines = [ln for ln in lines if "PACK=" in ln]
    pack_match = any(GOLDEN_PACK in ln.upper() for ln in pack_lines)
    print(f"STOP_REASON: {stop_reason}", flush=True)
    print(f"ELAPSED_S: {time.monotonic() - t0:.3f}", flush=True)
    print(f"UART_BYTES: {len(buf)}", flush=True)
    print(f"PRED_LINES: {pred_lines if pred_lines else 'NONE'}", flush=True)
    print(f"EXIST_ROW: {exist_row if exist_row else 'NONE'}", flush=True)
    print(f"PACK_LINES: {pack_lines if pack_lines else 'NONE'}", flush=True)
    print(f"H2_PACK_MATCH_AFAST: {pack_match}", flush=True)
    print("BOARD_PASS: not_claimed", flush=True)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
