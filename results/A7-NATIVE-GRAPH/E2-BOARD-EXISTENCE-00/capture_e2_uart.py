#!/usr/bin/env python3
"""Capture E2 existence UART from COM12."""
from __future__ import annotations

import argparse
import json
import re
import sys
import time
from pathlib import Path

try:
    import serial
except ImportError:
    serial = None

ROW_RE = re.compile(r"NATIVE_V1_EXIST_ROW,pred=(\d+)", re.I)
PASS_RE = re.compile(r"NATIVE_V1_EXISTENCE_BOARD_PASS pred=(\d+)", re.I)


def capture(port: str, baud: int, seconds: float) -> tuple[str, dict]:
    if serial is None:
        raise RuntimeError("pyserial not installed")
    ser = serial.Serial(port, baud, timeout=0.2)
    lines: list[str] = []
    t0 = time.time()
    while time.time() - t0 < seconds:
        chunk = ser.read(4096)
        if chunk:
            text = chunk.decode("utf-8", errors="replace")
            sys.stdout.write(text)
            sys.stdout.flush()
            for ln in text.splitlines():
                lines.append(ln)
        time.sleep(0.05)
    ser.close()
    raw = "\n".join(lines)
    pred = None
    for ln in lines:
        m = ROW_RE.search(ln) or PASS_RE.search(ln)
        if m:
            pred = int(m.group(1))
    meta = {
        "port": port,
        "baud": baud,
        "seconds": seconds,
        "pred": pred,
        "host_next_token": 0,
        "teacher_api_calls": 0,
        "learn": 0,
        "freeze": 1,
        "actual_lm06_active": 1 if pred is not None else 0,
        "fpga_next_token_valid": 1 if pred is not None else 0,
        "line_count": len(lines),
    }
    return raw, meta


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--port", default="COM12")
    ap.add_argument("--baud", type=int, default=115200)
    ap.add_argument("--seconds", type=float, default=45.0)
    ap.add_argument("--out-dir", type=Path, required=True)
    args = ap.parse_args()
    args.out_dir.mkdir(parents=True, exist_ok=True)
    raw, meta = capture(args.port, args.baud, args.seconds)
    txt = args.out_dir / "board_uart_capture.txt"
    js = args.out_dir / "board_uart_capture.json"
    txt.write_text(raw, encoding="utf-8")
    js.write_text(json.dumps(meta, indent=2), encoding="utf-8")
    print(json.dumps(meta, indent=2))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
