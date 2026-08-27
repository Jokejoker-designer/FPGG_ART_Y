#!/usr/bin/env python3
"""Capture COM12 for E2R-UART-MGO-HB-FIX-00-EXCL — F1w exclusive MGO after RPATH_IDLE."""
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
    ap.add_argument("--max-lines", type=int, default=5000)
    args = ap.parse_args()
    ser = serial.Serial(args.port, args.baud, timeout=0.2)
    t0 = time.time()
    buf = bytearray()
    print(f"listening {args.port} @ {args.baud} for {args.seconds}s (max_lines={args.max_lines})", flush=True)
    stop = False
    while time.time() - t0 < args.seconds and not stop:
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
        if b"pred=" in buf and b"\n" in buf[buf.find(b"pred="):]:
            break
        f1v_keys = ("WDMA_OWNER=", "WDMA_GRANT=", "RPATH_IDLE=", "MGO=")
        if all(any(x.startswith(k) for x in lines) for k in f1v_keys):
            mgo_i = next(i for i, x in enumerate(lines) if x.startswith("MGO="))
            if len(lines) > mgo_i + 8:
                print("\nSTOP: probe block complete (MGO+trail)", flush=True)
                break
            if (time.time() - t0) > 150.0:
                break
        if any(x.startswith("RPATH_IDLE=") for x in lines):
            boot_after = 0
            seen_rpath = False
            for x in lines:
                if x.startswith("RPATH_IDLE="):
                    seen_rpath = True
                elif seen_rpath and x == "BOOT":
                    boot_after += 1
            if boot_after > 50:
                print(f"\nSTOP: BOOT flood after RPATH_IDLE count={boot_after}", flush=True)
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
    w_stall_line = find_line("W_STALL=")
    phase_line = find_line("PHASE=")

    pred = None
    m = re.search(r"NATIVE_V1_EXIST_ROW,pred=(\d+)", text)
    if not m:
        m = re.search(r"pred=(\d+)", text)
    if m:
        pred = int(m.group(1))

    boot_flood = False
    if rpath_idle_line is not None:
        seen_rpath = False
        boot_after = 0
        for x in lines:
            if x.startswith("RPATH_IDLE="):
                seen_rpath = True
            elif seen_rpath and x == "BOOT":
                boot_after += 1
        boot_flood = boot_after > 5

    probe_pass = (
        mgo_line is not None
        and wdma_owner_line is not None
        and wdma_grant_line is not None
        and rpath_idle_line is not None
        and not boot_flood
    )

    print(f"WDMA_OWNER: {wdma_owner_line if wdma_owner_line else 'NO'}", flush=True)
    print(f"WDMA_GRANT: {wdma_grant_line if wdma_grant_line else 'NO'}", flush=True)
    print(f"RPATH_IDLE: {rpath_idle_line if rpath_idle_line else 'NO'}", flush=True)
    print(f"MGO: {mgo_line if mgo_line else 'NO'}", flush=True)
    print(f"DMA_ST: {dma_st_line if dma_st_line else 'NO'}", flush=True)
    print(f"SGO: {sgo_line if sgo_line else 'NO'}", flush=True)
    print(f"TILE_DST: {tile_dst_line if tile_dst_line else 'NO'}", flush=True)
    print(f"W_STALL: {w_stall_line if w_stall_line else 'NO'}", flush=True)
    print(f"PHASE: {phase_line if phase_line else 'NO'}", flush=True)
    print(f"BOOT_FLOOD: {'YES' if boot_flood else 'NO'}", flush=True)
    print(f"pred: {pred if pred is not None else 'NO'}", flush=True)
    print(f"PROBE_PASS: {'YES' if probe_pass else 'NO'}", flush=True)
    print(f"EXISTENCE_PASS: {'YES' if pred == 664 else 'NO'}", flush=True)
    sys.exit(0 if probe_pass else 3)


if __name__ == "__main__":
    main()
