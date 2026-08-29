#!/usr/bin/env python3
"""Hold-past-ATOM COM12 capture for E2R-UART-HOLD-LONGBOOT-00.

Open style copied from E2R-UART-HOLD-REARM-00/capture_uart_rearm.py
(DTR/RTS false). Never treat ATOM rows as a stop. Hold >=2400 s after
ATOM1 or until pred=664. Absolute max >=2700 s. Stop early only on
pred=664. Sequential SDONE=/SGO=/GRANT= are CONTROL, not class.

This PREP gate writes the vehicle only. Do not open COM12 here.
CONTROL vehicle is capture_uart_rearm.py (hold 300 / max 600).
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

FIELDS = (
    ("dest", 0, 3),
    ("owner", 3, 1),
    ("grant", 4, 1),
    ("idle", 5, 1),
    ("sdone_latch", 6, 1),
    ("sdone_sticky", 7, 1),
    ("w_stall", 8, 1),
    ("core_done", 9, 1),
    ("mgo", 10, 1),
)


def decode_atom(hex_s):
    if hex_s is None or hex_s == "NONE":
        return None
    v = int(hex_s, 16)
    d = {}
    for name, bit, width in FIELDS:
        d[name] = (v >> bit) & ((1 << width) - 1)
    d["raw"] = v
    d["hex"] = f"{v:08X}"
    d["reserved_12_11"] = (v >> 11) & 0x3
    d["hi_ok"] = (v >> 13) == 0 and d["reserved_12_11"] == 0
    return d


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


def _has_pred_664(text: str) -> bool:
    return ("pred=664" in text) or ("PRED=664" in text)


def _atom1_seen(text: str) -> bool:
    return any(ln.startswith("ATOM1=") for ln in text.splitlines())


def classify(text: str, nbytes: int) -> str:
    lines = [ln.strip() for ln in text.splitlines() if ln.strip()]
    pred_exact = any(("pred=664" in ln) or ("PRED=664" in ln) for ln in lines)
    if pred_exact:
        return "PRED_LATER"
    core_done = any(ln == "CORE_DONE" or ln.startswith("CORE_DONE") for ln in lines)
    if core_done:
        return "CORE_DONE_LATER"
    has_atom = any(ln.startswith("ATOM0=") or ln.startswith("ATOM1=") for ln in lines)
    if not has_atom:
        return "NO_ATOM"
    stallish = any(
        ln == "W_STALL"
        or ln.startswith("PHASE=")
        or ln.startswith("W_STALL")
        for ln in lines
    )
    if stallish:
        return "STILL_STALL"
    if nbytes == 0 or not lines:
        return "SILENT"
    return "SILENT"


def capture_longboot(
    port: str,
    baud: int,
    max_seconds: float,
    hold_after_atom: float,
    out_path: str,
) -> dict:
    t_wall0 = datetime.now(TZ).isoformat(timespec="seconds")
    ser = open_com_no_reset(port, baud)
    t0 = time.monotonic()
    t_atom1 = None
    buf = bytearray()
    stop_reason = "max_seconds"
    print(
        f"LONGBOOT_HOLD {port} @{baud} max_s={max_seconds} hold_after_atom_s={hold_after_atom} "
        f"start={t_wall0} dtr={ser.dtr} rts={ser.rts} program=NO",
        flush=True,
    )
    try:
        while True:
            elapsed = time.monotonic() - t0
            chunk = ser.read(256)
            if chunk:
                buf.extend(chunk)
                sys.stdout.write(chunk.decode("ascii", errors="replace"))
                sys.stdout.flush()
            text_so_far = buf.decode("ascii", errors="replace")
            if _has_pred_664(text_so_far):
                stop_reason = "pred=664"
                print("\nSTOP_EARLY: pred=664", flush=True)
                break
            if t_atom1 is None and _atom1_seen(text_so_far):
                t_atom1 = time.monotonic()
                print(
                    f"\nATOM1_SEEN elapsed_s={t_atom1 - t0:.3f} "
                    f"holding {hold_after_atom:.0f}s more (not a stop)",
                    flush=True,
                )
            elapsed = time.monotonic() - t0
            if elapsed >= max_seconds:
                stop_reason = "max_seconds"
                break
            if t_atom1 is not None and (time.monotonic() - t_atom1) >= hold_after_atom:
                stop_reason = "hold_after_atom"
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

    def find_line(prefix):
        return next((ln for ln in lines if ln.startswith(prefix)), None)

    a0_line = find_line("ATOM0=")
    a1_line = find_line("ATOM1=")
    a0_s = a0_line.split("=", 1)[1] if a0_line else None
    a1_s = a1_line.split("=", 1)[1] if a1_line else None
    a0 = decode_atom(a0_s)
    a1 = decode_atom(a1_s)
    sequential_sdone = find_line("SDONE=")
    sequential_grant = find_line("WDMA_GRANT=") or find_line("GRANT=")
    sequential_sgo = find_line("SGO=")
    pred_present = any(("pred=664" in ln) or ("PRED=664" in ln) for ln in lines)
    core_done = any(ln == "CORE_DONE" or ln.startswith("CORE_DONE") for ln in lines)
    pred_lines = [ln for ln in lines if "pred=" in ln.lower()]

    print(f"STOP_REASON: {stop_reason}", flush=True)
    print(f"ELAPSED_S: {elapsed:.3f}", flush=True)
    print(f"END: {t_wall1}", flush=True)
    print(f"UART_BYTES: {len(buf)}", flush=True)
    print(f"UART_LINES: {len(lines)}", flush=True)
    print(f"ATOM0: {a0_line if a0_line else 'NO'}", flush=True)
    print(f"ATOM1: {a1_line if a1_line else 'NO'}", flush=True)
    if a0:
        print(
            f"ATOM0_DECODE dest={a0['dest']} owner={a0['owner']} grant={a0['grant']} "
            f"idle={a0['idle']} sdone_latch={a0['sdone_latch']} sdone_sticky={a0['sdone_sticky']} "
            f"w_stall={a0['w_stall']} core_done={a0['core_done']} mgo={a0['mgo']} "
            f"hi_ok={a0['hi_ok']}",
            flush=True,
        )
    if a1:
        print(
            f"ATOM1_DECODE dest={a1['dest']} owner={a1['owner']} grant={a1['grant']} "
            f"idle={a1['idle']} sdone_latch={a1['sdone_latch']} sdone_sticky={a1['sdone_sticky']} "
            f"w_stall={a1['w_stall']} core_done={a1['core_done']} mgo={a1['mgo']} "
            f"hi_ok={a1['hi_ok']}",
            flush=True,
        )
    print(f"CLASS: {klass}", flush=True)
    print(
        f"SEQUENTIAL_NOT_CLASS SDONE={sequential_sdone} GRANT={sequential_grant} SGO={sequential_sgo}",
        flush=True,
    )
    print(f"CORE_DONE: {core_done}", flush=True)
    print(f"PRED_LINES: {pred_lines if pred_lines else 'NONE'}", flush=True)
    print("C_FIX: NONE", flush=True)
    print("PROGRAM: NO", flush=True)
    print("BOARD_PASS: not_claimed", flush=True)
    if pred_present:
        print("EXISTENCE: pred=664", flush=True)
    else:
        print("EXISTENCE: not_claimed", flush=True)
    return {
        "bytes": len(buf),
        "lines": len(lines),
        "elapsed_s": elapsed,
        "class": klass,
        "stop_reason": stop_reason,
        "start": t_wall0,
        "end": t_wall1,
        "core_done": core_done,
        "pred_present": pred_present,
        "out": out_path,
    }


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--port", default="COM12")
    ap.add_argument("--baud", type=int, default=115200)
    ap.add_argument("--max-seconds", type=float, default=2700.0)
    ap.add_argument("--hold-after-atom", type=float, default=2400.0)
    ap.add_argument("--out", default="uart_longboot.txt")
    args = ap.parse_args()
    if args.max_seconds < 2700.0:
        print("REFUSE: --max-seconds must be >= 2700", file=sys.stderr)
        return 2
    if args.hold_after_atom < 2400.0:
        print("REFUSE: --hold-after-atom must be >= 2400", file=sys.stderr)
        return 2
    rec = capture_longboot(
        args.port,
        args.baud,
        args.max_seconds,
        args.hold_after_atom,
        args.out,
    )
    print(f"OUT: {rec['out']}", flush=True)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
