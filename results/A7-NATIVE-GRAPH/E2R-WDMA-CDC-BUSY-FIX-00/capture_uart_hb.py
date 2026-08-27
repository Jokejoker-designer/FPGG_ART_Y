#!/usr/bin/env python3
"""Capture COM12 for E2R-WDMA-CDC-BUSY-FIX-00 — F1s WDMA CDC busy deassert fix."""
import argparse
import re
import sys
import time

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
    "BIND_BUSY", "WDMA_BUSY", "WDMA_DONE", "CORE_BUSY",
    "TILE_MISS", "W_STALL", "PRED_NZ", "CORE_DONE",
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
        text_so_far = buf.decode("ascii", errors="replace")
        lines = text_so_far.splitlines()
        if "CORE_BUSY" in lines and (time.time() - t0) > 90.0:
            if any(x.startswith("WDMA_OWN_UI=") for x in lines):
                if (time.time() - t0) > 120.0:
                    break
            elif any(x.startswith("SDMA_BUSY=") for x in lines) and (time.time() - t0) > 150.0:
                break
            elif (time.time() - t0) > 150.0:
                break
    ser.close()
    text = buf.decode("ascii", errors="replace")
    open(args.out, "w", encoding="utf-8").write(text)
    lines = [ln.strip() for ln in text.splitlines() if ln.strip()]
    seen = []
    for s in STAGES:
        if s in lines and s not in seen:
            seen.append(s)

    def find_line(prefix):
        return next((ln for ln in lines if ln.startswith(prefix)), None)

    phase_line = find_line("PHASE=")
    tile_dst_line = find_line("TILE_DST=")
    tile_bst_line = find_line("TILE_BST=")
    tile_req_line = find_line("TILE_REQ=")
    sdma_busy_line = find_line("SDMA_BUSY=")
    wdma_busy_line = find_line("WDMA_BUSY=")
    wdma_own_ui_line = find_line("WDMA_OWN_UI=")

    last = seen[-1] if seen else "NONE"
    for candidate in (
        wdma_own_ui_line, wdma_busy_line, sdma_busy_line,
        tile_req_line, tile_bst_line, tile_dst_line, phase_line,
    ):
        if candidate:
            last = candidate
            break

    print(f"\nHEARTBEATS_SEEN: {','.join(seen) if seen else '(none)'}", flush=True)
    print(f"LAST_STAGE: {last}", flush=True)
    for k in (
        "BIND", "BIND_BUSY", "WDMA_BUSY", "WDMA_DONE", "CORE_BUSY",
        "TILE_MISS", "W_STALL", "PRED_NZ", "CORE_DONE", "FWD", "LM", "PACK",
    ):
        print(f"{k}: {'YES' if k in seen else 'NO'}", flush=True)
    print(f"PHASE: {phase_line if phase_line else 'NO'}", flush=True)
    print(f"TILE_DST: {tile_dst_line if tile_dst_line else 'NO'}", flush=True)
    print(f"TILE_BST: {tile_bst_line if tile_bst_line else 'NO'}", flush=True)
    print(f"TILE_REQ: {tile_req_line if tile_req_line else 'NO'}", flush=True)
    print(f"SDMA_BUSY: {sdma_busy_line if sdma_busy_line else 'NO'}", flush=True)
    print(f"WDMA_BUSY: {wdma_busy_line if wdma_busy_line else 'NO'}", flush=True)
    print(f"WDMA_OWN_UI: {wdma_own_ui_line if wdma_own_ui_line else 'NO'}", flush=True)

    wdma_busy_at_req = False
    if wdma_busy_line:
        m = re.search(r"WDMA_BUSY=(\d+)", wdma_busy_line)
        if m:
            wdma_busy_at_req = int(m.group(1)) == 0

    tile_dst_nonzero = False
    if tile_dst_line:
        m = re.search(r"TILE_DST=(\d+)", tile_dst_line)
        if m:
            tile_dst_nonzero = int(m.group(1)) != 0

    w_stall_cleared = "W_STALL" not in seen
    pred = None
    m = re.search(r"NATIVE_V1_EXIST_ROW,pred=(\d+)", text)
    if not m:
        m = re.search(r"pred=(\d+)", text)
    if m:
        pred = int(m.group(1))
        print(f"RESULT: pred={pred}", flush=True)
    else:
        print("RESULT: NO_PRED", flush=True)

    fix_pass = wdma_busy_at_req and (tile_dst_nonzero or pred is not None or w_stall_cleared)
    print(f"FIX_PASS: {'YES' if fix_pass else 'NO'}", flush=True)

    if pred == 664:
        print("EXISTENCE_PASS: YES", flush=True)
        sys.exit(0)
    print("EXISTENCE_PASS: NO", flush=True)
    sys.exit(0 if fix_pass else 3)


if __name__ == "__main__":
    main()
