#!/usr/bin/env python3
"""Capture COM12 for E2R-CDC-AR-POR-RST-00 — F1i POR-only AR FIFO reset."""
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
    "CDC_M_ARF", "CDC_S_ARV", "CDC_S_ARR", "M_RST_LO", "S_RST_LO",
    "CDC_S_ARF", "CDC_HOLD",
    "SOA_Q", "TOPK", "ACCEPT", "PACK",
    "BIND", "FWD", "LM",
]

def classify_e3(seen):
    m_arf = "CDC_M_ARF" in seen
    s_arv = "CDC_S_ARV" in seen
    s_arr = "CDC_S_ARR" in seen
    s_arf = "CDC_S_ARF" in seen
    mig_ar = "MIG_AR" in seen
    ar_beat = "AR_BEAT" in seen
    if ar_beat and not m_arf:
        return "AXI_MIG_AR_PATH", "AR_BEAT_PRE_QGO"
    if m_arf and not s_arv:
        return "AXI_MIG_AR_PATH", "CDC_INTERNAL_STUCK"
    if s_arv and not s_arr:
        return "AXI_MIG_AR_PATH", "CDC_READY_STARVE"
    if s_arf and not mig_ar:
        return "AXI_MIG_AR_PATH", "MUX_AFTER_CDC"
    if not m_arf and not ar_beat:
        return "START_CMD_PATH", "UNKNOWN"
    return "AXI_MIG_AR_PATH", "UNKNOWN"

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
    stall, subclass = classify_e3(seen)
    print(f"\nHEARTBEATS_SEEN: {','.join(seen) if seen else '(none)'}", flush=True)
    print(f"LAST_STAGE: {last}", flush=True)
    for k in ("AR_BEAT", "R_BEAT", "CDC_M_ARF", "CDC_S_ARV", "CDC_S_ARR",
              "M_RST_LO", "S_RST_LO", "CDC_S_ARF", "CDC_HOLD",
              "MIG_AR", "OWN_WDMA", "CDC_AR", "MUX_CDC"):
        print(f"{k}: {'YES' if k in seen else 'NO'}", flush=True)
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
