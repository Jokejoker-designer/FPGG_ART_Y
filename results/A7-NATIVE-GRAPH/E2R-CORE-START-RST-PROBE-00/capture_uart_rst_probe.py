#!/usr/bin/env python3
"""COM12 capture for E2R-CORE-START-RST-PROBE-00.

Writes the raw UART byte stream unedited. Optional DONE_UNIX sidecar so
analysis can drop any pre-DONE tail (old bitstream).
"""
from __future__ import annotations

import argparse
import sys
import time
from pathlib import Path

try:
    import serial
except ImportError:
    print("NEED: pip install pyserial", file=sys.stderr)
    sys.exit(2)


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--port", default="COM12")
    ap.add_argument("--baud", type=int, default=115200)
    ap.add_argument("--seconds", type=float, default=180.0)
    ap.add_argument("--out-bin", required=True)
    ap.add_argument("--out-txt", required=True)
    ap.add_argument("--done-unix", type=float, default=0.0,
                    help="Wall-clock Unix time of JTAG DONE; bytes before this are pre-DONE")
    ap.add_argument("--clear-input", action="store_true",
                    help="Discard UART RX buffer once at open (does not stop the board)")
    args = ap.parse_args()

    out_bin = Path(args.out_bin)
    out_txt = Path(args.out_txt)
    out_bin.parent.mkdir(parents=True, exist_ok=True)

    ser = serial.Serial(args.port, args.baud, timeout=0.2)
    t_open = time.time()
    if args.clear_input:
        ser.reset_input_buffer()
    print(
        f"listening {args.port} @ {args.baud} for {args.seconds}s "
        f"open_unix={t_open:.3f} done_unix={args.done_unix:.3f}",
        flush=True,
    )

    raw = bytearray()
    stamps: list[tuple[float, int]] = []  # (unix, cumulative bytes)
    t_end = t_open + args.seconds
    while time.time() < t_end:
        chunk = ser.read(256)
        if chunk:
            now = time.time()
            raw.extend(chunk)
            stamps.append((now, len(raw)))
            sys.stdout.buffer.write(chunk)
            sys.stdout.buffer.flush()
    ser.close()
    t_close = time.time()

    out_bin.write_bytes(bytes(raw))
    # Text decode is a view of the same bytes; never hand-edit.
    text = bytes(raw).decode("ascii", errors="replace")
    out_txt.write_text(text, encoding="utf-8", newline="\n")

    meta = out_bin.with_suffix(".meta.txt")
    lines = [
        f"port={args.port}",
        f"baud={args.baud}",
        f"open_unix={t_open:.6f}",
        f"close_unix={t_close:.6f}",
        f"done_unix={args.done_unix:.6f}",
        f"bytes_total={len(raw)}",
    ]
    if args.done_unix > 0:
        post = 0
        for ts, cum in stamps:
            if ts >= args.done_unix:
                # first stamp at/after DONE: bytes before that chunk are pre-DONE
                prev = 0
                for ts2, cum2 in stamps:
                    if ts2 < args.done_unix:
                        prev = cum2
                post = len(raw) - prev
                lines.append(f"bytes_before_done={prev}")
                lines.append(f"bytes_after_done={post}")
                break
        else:
            lines.append("bytes_before_done=ALL_BEFORE_DONE_OR_NO_RX")
            lines.append("bytes_after_done=0")
    meta.write_text("\n".join(lines) + "\n", encoding="ascii")
    print(f"\nWROTE {out_bin} bytes={len(raw)} meta={meta}", flush=True)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
