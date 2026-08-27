#!/usr/bin/env python3
"""Capture COM12 for E2R-TILE-DMA-DONE-PROBE-00 — F1t s_done/m_done/busy_hold probes."""
import argparse
import re
import sys
import time

try:
    import serial
except ImportError:
    print("NEED: pip install pyserial", file=sys.stderr)
    sys.exit(2)


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
            if any(x.startswith("BUSY_HOLD=") for x in lines):
                if (time.time() - t0) > 120.0:
                    break
            elif any(x.startswith("SDONE=") for x in lines) and (time.time() - t0) > 150.0:
                break
            elif (time.time() - t0) > 150.0:
                break
    ser.close()
    text = buf.decode("ascii", errors="replace")
    open(args.out, "w", encoding="utf-8").write(text)
    lines = [ln.strip() for ln in text.splitlines() if ln.strip()]

    def find_line(prefix):
        return next((ln for ln in lines if ln.startswith(prefix)), None)

    tile_dst_line = find_line("TILE_DST=")
    sdma_busy_line = find_line("SDMA_BUSY=")
    wdma_busy_line = find_line("WDMA_BUSY=")
    tile_dma_own_line = find_line("TILE_DMA_OWN=")
    tile_miss_line = "TILE_MISS" if "TILE_MISS" in lines else None
    w_stall_line = "W_STALL" if "W_STALL" in lines else None
    phase_line = find_line("PHASE=")
    sdone_line = find_line("SDONE=")
    mdone_line = find_line("MDONE=")
    busy_hold_line = find_line("BUSY_HOLD=")

    pred = None
    m = re.search(r"NATIVE_V1_EXIST_ROW,pred=(\d+)", text)
    if not m:
        m = re.search(r"pred=(\d+)", text)
    if m:
        pred = int(m.group(1))

    def parse_val(line):
        if not line:
            return None
        m2 = re.search(r"=(\d+)$", line)
        return int(m2.group(1)) if m2 else None

    sdone = parse_val(sdone_line)
    mdone = parse_val(mdone_line)
    busy_hold = parse_val(busy_hold_line)
    tile_dst = parse_val(tile_dst_line)
    sdma_busy = parse_val(sdma_busy_line)
    wdma_busy = parse_val(wdma_busy_line)
    tile_dma_own = parse_val(tile_dma_own_line)

    probe_pass = sdone_line is not None and mdone_line is not None and busy_hold_line is not None

    print(f"SDONE: {sdone_line if sdone_line else 'NO'}", flush=True)
    print(f"MDONE: {mdone_line if mdone_line else 'NO'}", flush=True)
    print(f"BUSY_HOLD: {busy_hold_line if busy_hold_line else 'NO'}", flush=True)
    print(f"TILE_DST: {tile_dst_line if tile_dst_line else 'NO'}", flush=True)
    print(f"SDMA_BUSY: {sdma_busy_line if sdma_busy_line else 'NO'}", flush=True)
    print(f"WDMA_BUSY: {wdma_busy_line if wdma_busy_line else 'NO'}", flush=True)
    print(f"TILE_DMA_OWN: {tile_dma_own_line if tile_dma_own_line else 'NO'}", flush=True)
    print(f"TILE_MISS: {'YES' if tile_miss_line else 'NO'}", flush=True)
    print(f"W_STALL: {'YES' if w_stall_line else 'NO'}", flush=True)
    print(f"PHASE: {phase_line if phase_line else 'NO'}", flush=True)
    print(f"pred: {pred if pred is not None else 'NO'}", flush=True)
    print(f"PROBE_PASS: {'YES' if probe_pass else 'NO'}", flush=True)

    if pred == 664:
        print("EXISTENCE_PASS: YES", flush=True)
        sys.exit(0)
    print("EXISTENCE_PASS: NO", flush=True)
    sys.exit(0 if probe_pass else 3)


if __name__ == "__main__":
    main()
