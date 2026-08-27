#!/usr/bin/env python3
"""Capture COM12 for E2R-TILE-DMA-REQ-PROBE-00 — F1q TILE_REQ/dma_busy/dma_owner probe."""
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
            if any(x.startswith("TILE_DMA_OWN=") for x in lines):
                if (time.time() - t0) > 120.0:
                    break
            elif any(x.startswith("TILE_BST=") for x in lines) and (time.time() - t0) > 150.0:
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
    phase_line = next((ln for ln in lines if ln.startswith("PHASE=")), None)
    tile_dst_line = next((ln for ln in lines if ln.startswith("TILE_DST=")), None)
    tile_bst_line = next((ln for ln in lines if ln.startswith("TILE_BST=")), None)
    tile_req_line = next((ln for ln in lines if ln.startswith("TILE_REQ=")), None)
    tile_dma_busy_line = next((ln for ln in lines if ln.startswith("TILE_DMA_BUSY=")), None)
    tile_dma_own_line = next((ln for ln in lines if ln.startswith("TILE_DMA_OWN=")), None)
    last = seen[-1] if seen else "NONE"
    if tile_dma_own_line:
        last = tile_dma_own_line
    elif tile_dma_busy_line:
        last = tile_dma_busy_line
    elif tile_req_line:
        last = tile_req_line
    elif tile_bst_line:
        last = tile_bst_line
    elif tile_dst_line:
        last = tile_dst_line
    elif phase_line:
        last = phase_line
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
    print(f"TILE_DMA_BUSY: {tile_dma_busy_line if tile_dma_busy_line else 'NO'}", flush=True)
    print(f"TILE_DMA_OWN: {tile_dma_own_line if tile_dma_own_line else 'NO'}", flush=True)
    probe_pass = (
        tile_req_line is not None
        and tile_dma_busy_line is not None
        and tile_dma_own_line is not None
    )
    print(f"PROBE_PASS: {'YES' if probe_pass else 'NO'}", flush=True)
    print(f"BYTES: {len(buf)}", flush=True)
    m = re.search(r"NATIVE_V1_EXIST_ROW,pred=(\d+)", text)
    if not m:
        m = re.search(r"pred=(\d+)", text)
    if not m:
        print("RESULT: NO_PRED", flush=True)
        print("EXISTENCE_PASS: NO", flush=True)
        sys.exit(3 if probe_pass else 4)
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
