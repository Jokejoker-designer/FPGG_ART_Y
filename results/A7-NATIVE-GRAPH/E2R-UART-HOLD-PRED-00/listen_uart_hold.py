#!/usr/bin/env python3
"""LISTEN-ONLY COM12 hold for E2R-UART-HOLD-PRED-00.

Do not program. Do not reset. Do not stop on ATOM0/ATOM1.
Stop early only on pred=664. Minimum window --seconds (default 180).
"""
from __future__ import annotations

import argparse
import sys
import time
from datetime import datetime, timezone, timedelta

try:
    import serial
except ImportError:
    print("NEED: pip install pyserial", file=sys.stderr)
    sys.exit(2)


TZ = timezone(timedelta(hours=7))


def classify(text: str, nbytes: int) -> str:
    lines = [ln.strip() for ln in text.splitlines() if ln.strip()]
    joined = "\n".join(lines)
    pred_exact = any(
        ("pred=664" in ln) or ("PRED=664" in ln) for ln in lines
    )
    if pred_exact:
        return "PRED_LATER"
    core_done = any(
        ln == "CORE_DONE" or ln.startswith("CORE_DONE") for ln in lines
    )
    if core_done:
        return "CORE_DONE_LATER"
    stallish = any(
        ln == "W_STALL"
        or ln.startswith("PHASE=")
        or ln.startswith("ATOM0=")
        or ln.startswith("ATOM1=")
        or ln.startswith("W_STALL")
        for ln in lines
    )
    if stallish:
        return "STILL_STALL"
    if nbytes == 0 or not lines:
        return "SILENT"
    # bytes present but no stall/done/pred banners
    useful = any(
        ("pred=" in ln.lower())
        or ln.startswith("CORE_")
        or ln.startswith("ATOM")
        or ln.startswith("PHASE")
        or "STALL" in ln
        for ln in lines
    )
    if useful:
        return "STILL_STALL"
    return "SILENT"


def open_com_no_reset(port: str, baud: int) -> serial.Serial:
    """Open UART without asserting DTR/RTS (no board reset)."""
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
    # Re-clear after open; some Windows FTDI stacks pulse then restore.
    ser.dtr = False
    ser.rts = False
    return ser


def listen_once(port: str, baud: int, seconds: float, out_path: str) -> dict:
    t_wall0 = datetime.now(TZ).isoformat(timespec="seconds")
    ser = open_com_no_reset(port, baud)
    t0 = time.monotonic()
    buf = bytearray()
    stopped_early = False
    stop_reason = "window_elapsed"
    print(
        f"LISTEN_ONLY {port} @{baud} seconds={seconds} start={t_wall0} "
        f"dtr={ser.dtr} rts={ser.rts} program=NO reset=NO",
        flush=True,
    )
    try:
        while (time.monotonic() - t0) < seconds:
            chunk = ser.read(256)
            if chunk:
                buf.extend(chunk)
                sys.stdout.write(chunk.decode("ascii", errors="replace"))
                sys.stdout.flush()
                text_so_far = buf.decode("ascii", errors="replace")
                if ("pred=664" in text_so_far) or ("PRED=664" in text_so_far):
                    stopped_early = True
                    stop_reason = "pred=664"
                    print("\nSTOP_EARLY: pred=664", flush=True)
                    break
    finally:
        ser.close()
    elapsed = time.monotonic() - t0
    t_wall1 = datetime.now(TZ).isoformat(timespec="seconds")
    text = buf.decode("ascii", errors="replace")
    with open(out_path, "w", encoding="utf-8", newline="\n") as fh:
        fh.write(text)
    klass = classify(text, len(buf))
    lines = [ln.strip() for ln in text.splitlines() if ln.strip()]
    pred_lines = [ln for ln in lines if "pred=" in ln.lower()]
    core_done = any(ln == "CORE_DONE" or ln.startswith("CORE_DONE") for ln in lines)
    boot_seen = any(ln == "BOOT" for ln in lines)
    print(f"STOP_REASON: {stop_reason}", flush=True)
    print(f"ELAPSED_S: {elapsed:.3f}", flush=True)
    print(f"END: {t_wall1}", flush=True)
    print(f"UART_BYTES: {len(buf)}", flush=True)
    print(f"UART_LINES: {len(lines)}", flush=True)
    print(f"CLASS: {klass}", flush=True)
    print(f"CORE_DONE: {core_done}", flush=True)
    print(f"PRED_LINES: {pred_lines if pred_lines else 'NONE'}", flush=True)
    print(f"BOOT_SEEN: {boot_seen}", flush=True)
    print("C_FIX: NONE", flush=True)
    print("PROGRAM: NO", flush=True)
    print("BOARD_PASS: not_claimed", flush=True)
    print("EXISTENCE: not_claimed" if klass != "PRED_LATER" else "EXISTENCE: pred=664", flush=True)
    return {
        "bytes": len(buf),
        "lines": len(lines),
        "elapsed_s": elapsed,
        "class": klass,
        "text": text,
        "stopped_early": stopped_early,
        "stop_reason": stop_reason,
        "start": t_wall0,
        "end": t_wall1,
        "boot_seen": boot_seen,
        "core_done": core_done,
        "pred_lines": pred_lines,
    }


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--port", default="COM12")
    ap.add_argument("--baud", type=int, default=115200)
    ap.add_argument("--seconds", type=float, default=180.0)
    ap.add_argument("--out", required=True)
    ap.add_argument("--attempt", default="1")
    args = ap.parse_args()
    rec = listen_once(args.port, args.baud, args.seconds, args.out)
    print(f"ATTEMPT: {args.attempt}", flush=True)
    print(f"OUT: {args.out}", flush=True)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
