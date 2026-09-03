#!/usr/bin/env python3
"""Arm COM12 BEFORE program. Continuous capture. DTR/RTS off.
Does not stop on first pred= (preserve full UART/CFRAME). Stop on max-seconds
or STOP.txt. Never programs.
"""
from __future__ import annotations
import argparse, hashlib, sys, time
from datetime import datetime, timezone, timedelta
from pathlib import Path

TZ = timezone(timedelta(hours=7))
HERE = Path(__file__).resolve().parent
CAND = HERE.parent / "P2-WDMA-RELEASE-CDC-AUDIT-03"
BIT_PATH = CAND / "arty_a7_ng_native_v1_grok_orch_p2_wdma_release_cdc_audit_03.bit"
WANT = "6975AB757FE592DBD0EAB68FBDC7463559A3712CAA9A8BD1E429C9A6BDF8B39A"


def open_com(port, baud):
    import serial
    ser = serial.Serial()
    ser.port = port
    ser.baudrate = baud
    ser.timeout = 0.25
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
    ap.add_argument("--max-seconds", type=float, default=300.0)
    ap.add_argument("--tag", default="pass1")
    args = ap.parse_args()
    h = hashlib.sha256(BIT_PATH.read_bytes()).hexdigest().upper()
    if h != WANT:
        print("REFUSE SHA", h, file=sys.stderr)
        return 3
    raw_path = HERE / f"uart_raw_{args.tag}.bin"
    txt_path = HERE / f"uart_raw_{args.tag}.txt"
    stop_path = HERE / "STOP.txt"
    ser = open_com(args.port, args.baud)
    started = datetime.now(TZ).isoformat(timespec="seconds")
    (HERE / "LISTEN_START.txt").write_text(
        "gate=P2-GATE14-BOARD-PROGRAM-20-00\n"
        "mode=ARMED_BEFORE_PROGRAM_CONTINUOUS\n"
        f"port={args.port}\n"
        f"baud={args.baud}\n"
        "dtr=0 rts=0\n"
        f"bit_sha256={h}\n"
        f"tag={args.tag}\n"
        f"started_local={started}\n"
        "accept_pred=249\n"
        "historical_664=observe_not_accept\n"
        "TEACHER_OFF=not_claimed\n"
        "BOARD_PASS=not_claimed\n",
        encoding="utf-8",
    )
    print("GATE14_LISTEN ARMED", flush=True)
    t0 = time.monotonic()
    n = 0
    raw_f = open(raw_path, "wb")
    try:
        while True:
            if stop_path.exists():
                print("STOP_FILE", flush=True)
                break
            chunk = ser.read(256)
            if chunk:
                n += len(chunk)
                raw_f.write(chunk)
                raw_f.flush()
                sys.stdout.write(chunk.decode("ascii", errors="replace"))
                sys.stdout.flush()
            if time.monotonic() - t0 >= args.max_seconds:
                print("\nMAX_SECONDS", flush=True)
                break
    finally:
        ser.close()
        raw_f.close()
    data = raw_path.read_bytes() if raw_path.exists() else b""
    text = data.decode("ascii", errors="replace")
    txt_path.write_text(text, encoding="utf-8")
    print(f"\nCAPTURE_DONE tag={args.tag} bytes={len(data)} file={raw_path}", flush=True)
    print("TEACHER_OFF: not_claimed", flush=True)
    print("BOARD_PASS: not_claimed", flush=True)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
