#!/usr/bin/env python3
"""Capture COM12 for E2R-BIND-PRED-PROBE-00 — F1l BIND/PRED/CORE_DONE probe."""
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
    "MIG_AR", "OWN_WDMA", "CDC_AR", "MUX_CDC",
    "CDC_M_ARF", "CDC_S_ARV", "CDC_S_ARR", "AR_FIFO_NE",
    "M_RST_LO", "S_RST_LO",
    "CDC_S_ARF", "CDC_HOLD",
    "SOA_Q", "TOPK", "ACCEPT", "PACK",
    "BIND", "FWD", "LM",
    "BIND_BUSY", "PRED_NZ", "CORE_DONE",
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
        # F1l: also stop shortly after LM+probes if no PRED row (pred_ready needs BIND)
        text_so_far = buf.decode("ascii", errors="replace")
        if "LM" in text_so_far.splitlines() and (time.time() - t0) > 90.0:
            if any(x in text_so_far for x in ("BIND_BUSY", "PRED_NZ", "CORE_DONE")) or \
               ("PACK" in text_so_far and "FWD" in text_so_far):
                # give 20s more after LM for late probes
                if (time.time() - t0) > 120.0:
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
    print(f"\nHEARTBEATS_SEEN: {','.join(seen) if seen else '(none)'}", flush=True)
    print(f"LAST_STAGE: {last}", flush=True)
    for k in ("BIND", "BIND_BUSY", "PRED_NZ", "CORE_DONE", "FWD", "LM", "PACK"):
        print(f"{k}: {'YES' if k in seen else 'NO'}", flush=True)
    print(f"BYTES: {len(buf)}", flush=True)
    m = re.search(r"NATIVE_V1_EXIST_ROW,pred=(\d+)", text)
    if not m:
        print("RESULT: NO_PRED", flush=True)
        print("EXISTENCE_PASS: NO", flush=True)
        sys.exit(3)
    pred = int(m.group(1))
    print(f"RESULT: pred={pred}", flush=True)
    if pred == 664:
        print("ACCEPT: NATIVE_V1_EXISTENCE_BOARD_PASS", flush=True)
        print("EXISTENCE_PASS: YES", flush=True)
        sys.exit(0)
    print("REJECT: pred!=664", flush=True)
    print("EXISTENCE_PASS: NO", flush=True)
    sys.exit(5)

if __name__ == "__main__":
    main()
