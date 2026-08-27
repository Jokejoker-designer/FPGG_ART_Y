#!/usr/bin/env python3
"""Capture COM12 for E2R-WDMA-SBUSY-CMD-PROBE-00 — F1B2 UART stickies after MGO."""
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
        f1b2_keys = ("MGO=", "CMD_EMPTY=", "SBUSY_PEND=", "CMD_ST=", "CMD_RD=")
        if all(any(x.startswith(k) for x in lines) for k in f1b2_keys):
            cmd_rd_i = next(i for i, x in enumerate(lines) if x.startswith("CMD_RD="))
            if len(lines) > cmd_rd_i + 4:
                print("\nSTOP: probe block complete (CMD_RD+trail)", flush=True)
                break
            if (time.time() - t0) > 150.0:
                break
        if any(x.startswith("CMD_RD=") for x in lines):
            boot_after = 0
            seen_cmd = False
            for x in lines:
                if x.startswith("CMD_RD="):
                    seen_cmd = True
                elif seen_cmd and x == "BOOT":
                    boot_after += 1
            if boot_after > 50:
                print(f"\nSTOP: BOOT flood after CMD_RD count={boot_after}", flush=True)
                break
    ser.close()
    text = buf.decode("ascii", errors="replace")
    open(args.out, "w", encoding="utf-8").write(text)
    lines = [ln.strip() for ln in text.splitlines() if ln.strip()]

    def find_line(prefix):
        return next((ln for ln in lines if ln.startswith(prefix)), None)

    sgo_line = find_line("SGO=")
    mgo_line = find_line("MGO=")
    cmd_empty_line = find_line("CMD_EMPTY=")
    sbusy_line = find_line("SBUSY_PEND=")
    cmd_st_line = find_line("CMD_ST=")
    cmd_rd_line = find_line("CMD_RD=")
    tile_dst_line = find_line("TILE_DST=")
    dma_st_line = find_line("DMA_ST=")

    pred = None
    m = re.search(r"NATIVE_V1_EXIST_ROW,pred=(\d+)", text)
    if not m:
        m = re.search(r"pred=(\d+)", text)
    if m:
        pred = int(m.group(1))

    markers = [
        ("SGO", sgo_line),
        ("MGO", mgo_line),
        ("CMD_EMPTY", cmd_empty_line),
        ("SBUSY_PEND", sbusy_line),
        ("CMD_ST", cmd_st_line),
        ("CMD_RD", cmd_rd_line),
        ("TILE_DST", tile_dst_line),
    ]
    first_missing = "NONE"
    for name, ln in markers:
        if ln is None:
            first_missing = name
            break

    probe_pass = all(ln is not None for _, ln in markers)

    print(f"SGO: {sgo_line if sgo_line else 'NO'}", flush=True)
    print(f"MGO: {mgo_line if mgo_line else 'NO'}", flush=True)
    print(f"CMD_EMPTY: {cmd_empty_line if cmd_empty_line else 'NO'}", flush=True)
    print(f"SBUSY_PEND: {sbusy_line if sbusy_line else 'NO'}", flush=True)
    print(f"CMD_ST: {cmd_st_line if cmd_st_line else 'NO'}", flush=True)
    print(f"CMD_RD: {cmd_rd_line if cmd_rd_line else 'NO'}", flush=True)
    print(f"TILE_DST: {tile_dst_line if tile_dst_line else 'NO'}", flush=True)
    print(f"DMA_ST: {dma_st_line if dma_st_line else 'NO'}", flush=True)
    print(f"FIRST_MISSING_MARKER: {first_missing}", flush=True)
    print(f"pred: {pred if pred is not None else 'NO'}", flush=True)
    print(f"PROBE_PASS: {'YES' if probe_pass else 'NO'}", flush=True)
    print(f"EXISTENCE_PASS: {'YES' if pred == 664 else 'NO'}", flush=True)
    sys.exit(0 if probe_pass else 3)


if __name__ == "__main__":
    main()
