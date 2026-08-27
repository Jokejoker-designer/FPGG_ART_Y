#!/usr/bin/env python3
"""Capture COM12 for E2R-WDMA-BFIX-00-EXCL — classify A/B/C/EXISTENCE."""
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
        keys = ("MGO=", "SGO=", "WDMA_GRANT=", "CMD_RD=")
        if all(any(x.startswith(k) for x in lines) for k in keys):
            grant_i = next(i for i, x in enumerate(lines) if x.startswith("WDMA_GRANT="))
            if len(lines) > grant_i + 8:
                print("\nSTOP: classify block complete", flush=True)
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

    def val_eq(prefix, want):
        ln = find_line(prefix)
        return ln == f"{prefix}{want}"

    mgo_line = find_line("MGO=")
    sgo_line = find_line("SGO=")
    grant_line = find_line("WDMA_GRANT=")
    own_ui_line = find_line("WDMA_OWN_UI=")
    dma_st_line = find_line("DMA_ST=")
    sdone_line = find_line("SDONE=")
    w_stall = any(ln == "W_STALL" for ln in lines)
    core_done = any(ln == "CORE_DONE" or ln.startswith("CORE_DONE=") for ln in lines)

    pred = None
    m = re.search(r"NATIVE_V1_EXIST_ROW,pred=(\d+)", text)
    if not m:
        m = re.search(r"pred=(\d+)", text)
    if m:
        pred = int(m.group(1))

    dma_st = None
    if dma_st_line and dma_st_line.startswith("DMA_ST="):
        try:
            dma_st = int(dma_st_line.split("=", 1)[1], 16 if dma_st_line.split("=", 1)[1][:1] in "ABCDEFabcdef" else 10)
        except ValueError:
            try:
                dma_st = int(dma_st_line.split("=", 1)[1], 16)
            except ValueError:
                dma_st = None

    chain = [
        ("MGO", mgo_line == "MGO=1"),
        ("SGO", sgo_line == "SGO=1"),
        ("GRANT", grant_line == "WDMA_GRANT=1"),
        ("OWN_UI", own_ui_line == "WDMA_OWN_UI=1"),
        ("DMA_ST", dma_st is not None and dma_st != 0),
        ("SDONE", sdone_line == "SDONE=1"),
        ("W_STALL", not w_stall),
        ("CORE_DONE", core_done),
        ("pred", pred == 664),
    ]
    first_missing = "NONE"
    for name, ok in chain:
        if not ok:
            first_missing = name
            break

    if pred == 664:
        klass = "EXISTENCE"
    elif mgo_line == "MGO=0":
        klass = "A"
    elif mgo_line == "MGO=1" and sgo_line == "SGO=0":
        klass = "B"
    elif mgo_line == "MGO=1" and sgo_line == "SGO=1" and grant_line == "WDMA_GRANT=0":
        klass = "C"
    elif mgo_line is None:
        klass = "INCOMPLETE"
    else:
        klass = "INCOMPLETE"

    print(f"MGO: {mgo_line if mgo_line else 'NO'}", flush=True)
    print(f"SGO: {sgo_line if sgo_line else 'NO'}", flush=True)
    print(f"GRANT: {grant_line if grant_line else 'NO'}", flush=True)
    print(f"OWN_UI: {own_ui_line if own_ui_line else 'NO'}", flush=True)
    print(f"DMA_ST: {dma_st_line if dma_st_line else 'NO'}", flush=True)
    print(f"SDONE: {sdone_line if sdone_line else 'NO'}", flush=True)
    print(f"W_STALL: {'YES' if w_stall else 'NO'}", flush=True)
    print(f"CORE_DONE: {'YES' if core_done else 'NO'}", flush=True)
    print(f"FIRST_MISSING_MARKER: {first_missing}", flush=True)
    print(f"pred: {pred if pred is not None else 'NO'}", flush=True)
    print(f"CLASS: {klass}", flush=True)
    print(f"EXISTENCE_PASS: {'YES' if pred == 664 else 'NO'}", flush=True)
    sys.exit(0)


if __name__ == "__main__":
    main()
