#!/usr/bin/env python3
"""Capture COM12 for E2R-WDMA-OWNER-GRANT-PROBE-00 — F1v owner/grant/rpath/m_go probes."""
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
        f1v_keys = ("WDMA_OWNER=", "WDMA_GRANT=", "RPATH_IDLE=", "MGO=")
        if "CORE_BUSY" in lines and (time.time() - t0) > 90.0:
            if all(any(x.startswith(k) for x in lines) for k in f1v_keys):
                if (time.time() - t0) > 120.0:
                    break
            elif (time.time() - t0) > 150.0:
                break
    ser.close()
    text = buf.decode("ascii", errors="replace")
    open(args.out, "w", encoding="utf-8").write(text)
    lines = [ln.strip() for ln in text.splitlines() if ln.strip()]

    def find_line(prefix):
        return next((ln for ln in lines if ln.startswith(prefix)), None)

    wdma_owner_line = find_line("WDMA_OWNER=")
    wdma_grant_line = find_line("WDMA_GRANT=")
    rpath_idle_line = find_line("RPATH_IDLE=")
    mgo_line = find_line("MGO=")
    dma_st_line = find_line("DMA_ST=")
    sgo_line = find_line("SGO=")
    tile_dst_line = find_line("TILE_DST=")
    wdma_own_ui_line = find_line("WDMA_OWN_UI=")
    tile_dma_own_line = find_line("TILE_DMA_OWN=")
    w_stall_line = "W_STALL" if "W_STALL" in lines else None
    phase_line = find_line("PHASE=")

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
        if m2:
            return int(m2.group(1))
        m3 = re.search(r"=([0-9A-Fa-f])$", line)
        return int(m3.group(1), 16) if m3 else None

    probe_pass = all(
        ln is not None
        for ln in (wdma_owner_line, wdma_grant_line, rpath_idle_line, mgo_line)
    )

    print(f"WDMA_OWNER: {wdma_owner_line if wdma_owner_line else 'NO'}", flush=True)
    print(f"WDMA_GRANT: {wdma_grant_line if wdma_grant_line else 'NO'}", flush=True)
    print(f"RPATH_IDLE: {rpath_idle_line if rpath_idle_line else 'NO'}", flush=True)
    print(f"MGO: {mgo_line if mgo_line else 'NO'}", flush=True)
    print(f"DMA_ST: {dma_st_line if dma_st_line else 'NO'}", flush=True)
    print(f"SGO: {sgo_line if sgo_line else 'NO'}", flush=True)
    print(f"TILE_DST: {tile_dst_line if tile_dst_line else 'NO'}", flush=True)
    print(f"WDMA_OWN_UI: {wdma_own_ui_line if wdma_own_ui_line else 'NO'}", flush=True)
    print(f"TILE_DMA_OWN: {tile_dma_own_line if tile_dma_own_line else 'NO'}", flush=True)
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
