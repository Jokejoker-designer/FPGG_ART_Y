#!/usr/bin/env python3
"""Capture COM12 UART for Gate 4 — accept only ASCII pred=664 (not hex 298)."""
import argparse, re, sys, time
try:
    import serial
except ImportError:
    print("NEED: pip install pyserial", file=sys.stderr)
    sys.exit(2)

def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--port", default="COM12")
    ap.add_argument("--baud", type=int, default=115200)
    ap.add_argument("--seconds", type=float, default=90.0)
    ap.add_argument("--out", default="uart_capture.txt")
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
        if b"pred=" in buf and b"\n" in buf[buf.find(b"pred="):]:
            break
    ser.close()
    text = buf.decode("ascii", errors="replace")
    open(args.out, "w", encoding="utf-8").write(text)
    m = re.search(r"NATIVE_V1_EXIST_ROW,pred=(\d+)", text)
    if not m:
        print("\nRESULT: NO_MARKER", flush=True)
        sys.exit(3)
    pred = int(m.group(1))
    print(f"\nRESULT: pred={pred}", flush=True)
    if pred == 664:
        print("ACCEPT: NATIVE_V1_EXISTENCE_BOARD_PASS", flush=True)
        sys.exit(0)
    if pred == 298:
        print("REJECT: F2 hex false-fail pattern (664 as nibbles)", flush=True)
        sys.exit(4)
    print("REJECT: pred!=664", flush=True)
    sys.exit(5)

if __name__ == "__main__":
    main()
