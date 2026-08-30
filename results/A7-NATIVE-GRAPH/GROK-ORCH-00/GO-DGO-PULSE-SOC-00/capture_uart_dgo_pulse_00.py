#!/usr/bin/env python3
"""Arm COM12 then listen for D_GO-pulse existence UART. DTR/RTS false.
Stop early only on exact pred=664. Never stamp BOARD_PASS.
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
BIT_PATH = HERE / "arty_a7_ng_native_v1_grok_orch_dgo_pulse_00.bit"
EXPECTED_BIT_SHA = "125978D315B33E2F3E476919886B3DCA9868814F1F04E9C07D31D007A6B86072"
PRED_EXACT = "pred=664"


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


def bit_sha256() -> str:
    if not BIT_PATH.is_file():
        return "MISSING"
    h = hashlib.sha256()
    with BIT_PATH.open("rb") as fh:
        for chunk in iter(lambda: fh.read(1024 * 1024), b""):
            h.update(chunk)
    return h.hexdigest().upper()


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--port", default="COM12")
    ap.add_argument("--baud", type=int, default=115200)
    ap.add_argument("--max-seconds", type=float, default=600.0)
    ap.add_argument("--out", default=str(HERE / "uart_dgo_pulse_00.txt"))
    ap.add_argument("--stamp", default=str(HERE / "LISTEN_START.txt"))
    args = ap.parse_args()

    sha = bit_sha256()
    if sha != EXPECTED_BIT_SHA:
        print(f"REFUSE bit SHA {sha} want {EXPECTED_BIT_SHA}", file=sys.stderr)
        return 3

    started = datetime.now(TZ).isoformat(timespec="seconds")
    ser = open_com_no_reset(args.port, args.baud)
    Path(args.stamp).write_text(
        "\n".join(
            [
                "gate=GO-DGO-PULSE-SOC-00",
                "mode=ARMED_BEFORE_PROGRAM",
                "token=human Cursor-returned-COM12",
                "branch=research/native-ai-v1-grok-orch-00",
                f"port={args.port}",
                f"baud={args.baud}",
                f"window_s={int(args.max_seconds)}",
                "stop_early=pred=664_only",
                f"bit_sha256={sha}",
                f"dtr={str(ser.dtr).lower()}",
                f"rts={str(ser.rts).lower()}",
                f"started_local={started}",
                "BOARD_PASS=not_claimed",
                "",
            ]
        ),
        encoding="utf-8",
        newline="\n",
    )
    print(
        f"DGO_PULSE_LISTEN {args.port} @{args.baud} max_s={args.max_seconds} "
        f"start={started} dtr={ser.dtr} rts={ser.rts} ARMED",
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
            text_so_far = buf.decode("ascii", errors="replace")
            if PRED_EXACT in text_so_far:
                stop_reason = PRED_EXACT
                print(f"\nSTOP_EARLY: {PRED_EXACT}", flush=True)
                break
            if (time.monotonic() - t0) >= args.max_seconds:
                break
    finally:
        ser.close()

    elapsed = time.monotonic() - t0
    text = buf.decode("ascii", errors="replace")
    Path(args.out).write_text(text, encoding="utf-8", newline="\n")
    lines = [ln.strip() for ln in text.splitlines() if ln.strip()]
    pred_lines = [ln for ln in lines if "pred=" in ln]
    exist_row = [ln for ln in lines if "NATIVE_V1_EXIST_ROW" in ln]
    print(f"STOP_REASON: {stop_reason}", flush=True)
    print(f"ELAPSED_S: {elapsed:.3f}", flush=True)
    print(f"UART_BYTES: {len(buf)}", flush=True)
    print(f"UART_LINES: {len(lines)}", flush=True)
    print(f"PRED_LINES: {pred_lines if pred_lines else 'NONE'}", flush=True)
    print(f"EXIST_ROW: {exist_row if exist_row else 'NONE'}", flush=True)
    print("BOARD_PASS: not_claimed", flush=True)
    if PRED_EXACT in text:
        print(f"UART_OBSERVED: {PRED_EXACT}", flush=True)
    else:
        print("UART_OBSERVED: no pred=664", flush=True)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
