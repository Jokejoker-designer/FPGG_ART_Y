#!/usr/bin/env python3
"""Arm COM12 BEFORE program. Do not run in P2-GATE14-BOARD-PREFLIGHT-00.
This file is a prepared path only. Opening the port is forbidden until a
human named token authorizes the program step.
"""
from __future__ import annotations
import argparse, hashlib, sys, time
from datetime import datetime, timezone, timedelta
from pathlib import Path

TZ = timezone(timedelta(hours=7))
HERE = Path(__file__).resolve().parent
CAND = HERE.parent / "P2-WDMA-RELEASE-CDC-AUDIT-03"
BIT_PATH = CAND / "arty_a7_ng_native_v1_grok_orch_p2_wdma_release_cdc_audit_03.bit"
SHA_PATH = CAND / "BIT_SHA256.txt"
WANT = "6975AB757FE592DBD0EAB68FBDC7463559A3712CAA9A8BD1E429C9A6BDF8B39A"
GOLDEN = "3B392B291B190B09"
ACCEPT_PRED = "pred=249"
REFUSE_PRED = "pred=664"


def open_com(port, baud):
    import serial
    ser = serial.Serial()
    ser.port, ser.baudrate, ser.timeout = port, baud, 0.25
    ser.dtr = False
    ser.rts = False
    ser.open()
    ser.dtr = False
    ser.rts = False
    return ser


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--port", default="COM12")
    ap.add_argument("--baud", type=int, default=115200)
    ap.add_argument("--max-seconds", type=float, default=240.0)
    ap.add_argument("--i-have-human-token", action="store_true")
    args = ap.parse_args()
    if not args.i_have_human_token:
        print("REFUSE: capture opens COM12; preflight forbids it without human token", file=sys.stderr)
        return 3
    h = hashlib.sha256(BIT_PATH.read_bytes()).hexdigest().upper()
    expect = SHA_PATH.read_text(encoding="utf-8").strip().upper()
    if h != expect or h != WANT:
        print("REFUSE SHA", h, file=sys.stderr)
        return 3
    ser = open_com(args.port, args.baud)
    (HERE / "LISTEN_START.txt").write_text(
        "gate=P2-GATE14-BOARD-PREFLIGHT-00\n"
        "mode=ARMED_BEFORE_PROGRAM\n"
        f"port={args.port}\n"
        f"bit_sha256={h}\n"
        f"started_local={datetime.now(TZ).isoformat(timespec='seconds')}\n"
        "accept_pred=249\n"
        "historical_664=refuse\n"
        "TEACHER_OFF=not_claimed\n"
        "BOARD_PASS=not_claimed\n"
        "GATE14=not_closed\n",
        encoding="utf-8",
    )
    print("GATE14_LISTEN ARMED", flush=True)
    t0 = time.monotonic()
    buf = bytearray()
    stop = "max_seconds"
    try:
        while True:
            chunk = ser.read(256)
            if chunk:
                buf.extend(chunk)
                sys.stdout.write(chunk.decode("ascii", errors="replace"))
                sys.stdout.flush()
            text = buf.decode("ascii", errors="replace")
            if REFUSE_PRED in text:
                stop = "pred=664_historical"
                print("\nSTOP_EARLY: historical pred=664 (wrong core)", flush=True)
                break
            if ACCEPT_PRED in text:
                stop = "pred=249"
                print("\nSTOP_EARLY: pred=249", flush=True)
                break
            if "NATIVE_V1_EXIST_ROW" in text:
                stop = "EXIST_ROW"
                print("\nSTOP_EARLY: EXIST_ROW", flush=True)
                break
            if time.monotonic() - t0 >= args.max_seconds:
                break
    finally:
        ser.close()
    text = buf.decode("ascii", errors="replace")
    (HERE / "uart_gate14_preflight.txt").write_text(text, encoding="utf-8")
    lines = [ln.strip() for ln in text.splitlines() if ln.strip()]
    print(f"STOP_REASON: {stop}", flush=True)
    print(f"PRED_LINES: {[ln for ln in lines if 'pred=' in ln] or 'NONE'}", flush=True)
    print(f"PACK_LINES: {[ln for ln in lines if 'PACK=' in ln] or 'NONE'}", flush=True)
    print(f"TOPK_LINES: {[ln for ln in lines if 'TOPK=' in ln] or 'NONE'}", flush=True)
    print("TEACHER_OFF: not_claimed", flush=True)
    print("BOARD_PASS: not_claimed", flush=True)
    print("GATE14: not_closed", flush=True)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
