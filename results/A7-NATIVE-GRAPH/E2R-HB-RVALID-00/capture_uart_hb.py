#!/usr/bin/env python3
"""Capture COM12 for E2R-HB-RVALID-00 — D3 AXI-R sticky markers + D1 heartbeats + optional pred=664."""
import argparse, re, sys, time
try:
    import serial
except ImportError:
    print("NEED: pip install pyserial", file=sys.stderr)
    sys.exit(2)

STAGES = [
    "BOOT", "MIG_OK", "WMEM_OK", "SOA_OK", "CORE_START",
    "OWNER_RDY", "Q_GO",
    "SOA_RUN", "AR_BEAT", "R_BEAT", "R_BUSY", "R_IDLE",
    "RV_SEEN", "RREADY1", "RID_OK", "RID_BAD", "OUTST", "MIG_RV", "CDC_NE",
    "SOA_Q", "TOPK", "ACCEPT", "PACK",
    "BIND", "FWD", "LM",
]

def classify_stall(seen):
    if "SOA_Q" in seen:
        return "SOA_DONE_REACHED", "NONE"
    if "AR_BEAT" not in seen:
        return "START_CMD_PATH", "UNKNOWN"
    if "R_BEAT" in seen:
        return "WAVEFRONT_LOGIC", "NONE"
    # AR without R beat — D3 subclass
    if "RID_BAD" in seen:
        return "AXI_MIG_R_PATH", "RID_MISMATCH"
    if "MIG_RV" in seen and "RV_SEEN" not in seen:
        return "AXI_MIG_R_PATH", "CDC_DROP"
    if "RV_SEEN" in seen and "R_BEAT" not in seen:
        return "AXI_MIG_R_PATH", "RVALID_NO_READY"
    if "RV_SEEN" not in seen and "MIG_RV" not in seen:
        return "AXI_MIG_R_PATH", "NO_RVALID"
    return "AXI_MIG_R_PATH", "UNKNOWN"

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
    lines = [ln.strip() for ln in text.splitlines() if ln.strip()]
    seen = []
    for s in STAGES:
        if s in lines and s not in seen:
            seen.append(s)
    last = seen[-1] if seen else "NONE"
    stall, subclass = classify_stall(seen)
    print(f"\nHEARTBEATS_SEEN: {','.join(seen) if seen else '(none)'}", flush=True)
    print(f"LAST_STAGE: {last}", flush=True)
    print(f"STALL_CLASS: {stall}", flush=True)
    print(f"STALL_SUBCLASS: {subclass}", flush=True)
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
