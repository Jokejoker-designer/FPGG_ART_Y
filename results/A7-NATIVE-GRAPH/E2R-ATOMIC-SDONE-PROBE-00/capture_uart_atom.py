#!/usr/bin/env python3
"""Capture COM12 for E2R-ATOMIC-SDONE-PROBE-00. Classify from ATOM rows only."""
import argparse
import sys
import time

try:
    import serial
except ImportError:
    print("NEED: pip install pyserial", file=sys.stderr)
    sys.exit(2)


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


def classify(a0, a1):
    """First match: NO_DST4 / SDONE_HIT / WSTALL / SDONE_MISS. ATOM0 UNIT."""
    if a0 is None:
        return "NO_DST4"
    if a0["dest"] != 4:
        return "NO_DST4"
    if (a0["sdone_latch"] == 1) or (a0["sdone_sticky"] == 1):
        return "SDONE_HIT"
    if a0["w_stall"] == 1:
        return "WSTALL"
    return "SDONE_MISS"


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--port", default="COM12")
    ap.add_argument("--baud", type=int, default=115200)
    ap.add_argument("--seconds", type=float, default=180.0)
    ap.add_argument("--out", default="uart_capture.txt")
    ap.add_argument("--max-lines", type=int, default=5000)
    args = ap.parse_args()
    ser = serial.Serial(args.port, args.baud, timeout=0.2)
    t0 = time.time()
    buf = bytearray()
    print(f"listening {args.port} @ {args.baud} for {args.seconds}s", flush=True)
    while time.time() - t0 < args.seconds:
        chunk = ser.read(256)
        if chunk:
            buf.extend(chunk)
            sys.stdout.write(chunk.decode("ascii", errors="replace"))
            sys.stdout.flush()
        text_so_far = buf.decode("ascii", errors="replace")
        lines = [ln for ln in text_so_far.splitlines() if ln.strip()]
        if len(lines) >= args.max_lines:
            print(f"\nSTOP: max_lines={args.max_lines}", flush=True)
            break
        has0 = any(x.startswith("ATOM0=") for x in lines)
        has1 = any(x.startswith("ATOM1=") for x in lines)
        if has0 and has1:
            print("\nSTOP: ATOM0+ATOM1 captured", flush=True)
            break
    ser.close()
    text = buf.decode("ascii", errors="replace")
    open(args.out, "w", encoding="utf-8").write(text)
    lines = [ln.strip() for ln in text.splitlines() if ln.strip()]

    def find_line(prefix):
        return next((ln for ln in lines if ln.startswith(prefix)), None)

    a0_line = find_line("ATOM0=")
    a1_line = find_line("ATOM1=")
    a0_s = a0_line.split("=", 1)[1] if a0_line else None
    a1_s = a1_line.split("=", 1)[1] if a1_line else None
    a0 = decode_atom(a0_s)
    a1 = decode_atom(a1_s)
    klass = classify(a0, a1)
    pred_present = any("pred=664" in ln or "PRED=664" in ln for ln in lines)
    sequential_sdone = find_line("SDONE=")
    sequential_grant = find_line("WDMA_GRANT=") or find_line("GRANT=")
    sequential_sgo = find_line("SGO=")

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
    print("BOARD_PASS: not_claimed", flush=True)
    print("EXISTENCE: not_claimed", flush=True)
    print(f"PRED_664: {pred_present}", flush=True)
    print("C_FIX: NONE", flush=True)
    nbytes = len(buf)
    print(f"UART_BYTES: {nbytes}", flush=True)
    sys.exit(0 if nbytes > 0 and (a0_line or a1_line) else 1)


if __name__ == "__main__":
    main()
