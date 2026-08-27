#!/usr/bin/env python3
"""Capture COM12 for E2R-HB-CORE-BIND-00 — A+ post-CORE heartbeats + optional pred=664."""
import argparse, re, sys, time
try:
    import serial
except ImportError:
    print("NEED: pip install pyserial", file=sys.stderr)
    sys.exit(2)

STAGES = [
    "BOOT", "MIG_OK", "WMEM_OK", "SOA_OK", "CORE_START",
    "OWNER_RDY", "Q_GO", "SOA_Q", "TOPK", "ACCEPT", "PACK",
    "BIND", "FWD", "LM",
]

def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--port", default="COM12")
    ap.add_argument("--baud", type=int, default=115200)
    ap.add_argument("--seconds", type=float, default=180.0)
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
    # Order-preserving seen list (first occurrence)
    seen = []
    for s in STAGES:
        if s in text and s not in seen:
            seen.append(s)
    last = seen[-1] if seen else "NONE"
    print(f"\nHEARTBEATS_SEEN: {','.join(seen) if seen else '(none)'}", flush=True)
    print(f"LAST_STAGE: {last}", flush=True)
    print(f"BYTES: {len(buf)}", flush=True)
    m = re.search(r"NATIVE_V1_EXIST_ROW,pred=(\d+)", text)
    if not m:
        print("RESULT: NO_PRED", flush=True)
        sys.exit(3)
    pred = int(m.group(1))
    print(f"RESULT: pred={pred}", flush=True)
    if pred == 664:
        print("ACCEPT: NATIVE_V1_EXISTENCE_BOARD_PASS", flush=True)
        sys.exit(0)
    if pred == 298:
        print("REJECT: F2 hex false-fail pattern", flush=True)
        sys.exit(4)
    print("REJECT: pred!=664", flush=True)
    sys.exit(5)

if __name__ == "__main__":
    main()
