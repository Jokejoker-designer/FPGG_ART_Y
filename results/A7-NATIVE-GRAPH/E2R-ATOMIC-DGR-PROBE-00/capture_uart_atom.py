#!/usr/bin/env python3
"""Capture COM12 for E2R-ATOMIC-DGR-PROBE-00. Classify from ATOM rows only."""
import argparse
import re
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
    ("drain", 6, 1),
    ("fifo_ne", 7, 1),
    ("c_rvalid", 8, 1),
    ("tr_nz", 9, 1),
    ("mgo_sticky", 10, 1),
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
    hi = v >> 11
    d["hi_ok"] = hi == 0
    return d


def classify(a0, a1):
    if a0 is None and a1 is None:
        return "NO_DST4", "NONE"
    atoms = [a for a in (a0, a1) if a is not None]
    dst4_busy = [a for a in atoms if a["dest"] == 4 and a["idle"] == 0]
    if dst4_busy:
        cons = []
        for name in ("drain", "fifo_ne", "c_rvalid", "tr_nz"):
            if dst4_busy[0][name]:
                cons.append(name)
        if len(cons) > 1:
            return "SET", ",".join(cons)
        occ = [a for a in dst4_busy if a["grant"] == 0]
        if occ and len(cons) == 1:
            return "OCC_400", cons[0]
        if occ:
            return "OCC_400", "NONE"
    dst4 = [a for a in atoms if a["dest"] == 4]
    if dst4 and a1 is not None and a1["dest"] == 4 and a1["idle"] == 1 and a1["grant"] == 1:
        return "SKEW_IDLE1", "NONE"
    if dst4 and a1 is not None and a1["dest"] == 4 and a1["idle"] == 1 and a1["grant"] == 0:
        return "GRANT_STUCK", "NONE"
    if any(a["dest"] == 4 for a in atoms):
        return "INDETERMINATE", "NONE"
    return "NO_DST4", "NONE"


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
        if any(x == "BOOT" for x in lines[20:]) and has0 and has1:
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
    klass, wire = classify(a0, a1)

    print(f"ATOM0: {a0_line if a0_line else 'NO'}", flush=True)
    print(f"ATOM1: {a1_line if a1_line else 'NO'}", flush=True)
    if a0:
        print(
            f"ATOM0_DECODE dest={a0['dest']} owner={a0['owner']} grant={a0['grant']} "
            f"idle={a0['idle']} drain={a0['drain']} fifo_ne={a0['fifo_ne']} "
            f"c_rvalid={a0['c_rvalid']} tr_nz={a0['tr_nz']} mgo={a0['mgo_sticky']}",
            flush=True,
        )
    if a1:
        print(
            f"ATOM1_DECODE dest={a1['dest']} owner={a1['owner']} grant={a1['grant']} "
            f"idle={a1['idle']} drain={a1['drain']} fifo_ne={a1['fifo_ne']} "
            f"c_rvalid={a1['c_rvalid']} tr_nz={a1['tr_nz']} mgo={a1['mgo_sticky']}",
            flush=True,
        )
    print(f"CLASS: {klass}", flush=True)
    print(f"WIRE: {wire}", flush=True)
    print("BOARD_PASS: not_claimed", flush=True)
    print("EXISTENCE: not_claimed", flush=True)
    print("C_FIX: NONE", flush=True)
    nbytes = len(buf)
    print(f"UART_BYTES: {nbytes}", flush=True)
    sys.exit(0 if nbytes > 0 and (a0_line or a1_line) else 1)


if __name__ == "__main__":
    main()
