#!/usr/bin/env python3
"""Single clean silicon run: arm UART, program unique bit once, capture after DONE.

Does not program a second time. Does not edit the UART log.
"""
from __future__ import annotations

import argparse
import os
import subprocess
import sys
import threading
import time
from pathlib import Path

try:
    import serial
except ImportError:
    print("NEED: pip install pyserial", file=sys.stderr)
    sys.exit(2)

ROOT = Path(__file__).resolve().parents[3]
BAG = Path(__file__).resolve().parent
BIT = BAG / "arty_a7_ng_native_v1_core_start_rst_probe_00.bit"
SHA = BAG / "BIT_SHA256.txt"
PROG = ROOT / "vivado" / "tcl" / "program_e2r_core_start_rst_probe_00.tcl"
VIVADO = Path(r"C:\2026.1\Vivado\bin\vivado.bat")
FORBIDDEN = "A0B338E0"


def _sha256(path: Path) -> str:
    import hashlib
    h = hashlib.sha256()
    h.update(path.read_bytes())
    return h.hexdigest().upper()


class Capture:
    def __init__(self, port: str, baud: int):
        self.port = port
        self.baud = baud
        self.raw = bytearray()
        self.stamps: list[tuple[float, int]] = []
        self.t_open = 0.0
        self.stop = threading.Event()
        self.err: str | None = None

    def run(self) -> None:
        try:
            ser = serial.Serial(self.port, self.baud, timeout=0.2)
        except Exception as e:  # noqa: BLE001
            self.err = str(e)
            return
        ser.reset_input_buffer()
        self.t_open = time.time()
        print(f"UART_ARMED port={self.port} open_unix={self.t_open:.3f}", flush=True)
        while not self.stop.is_set():
            chunk = ser.read(256)
            if chunk:
                self.raw.extend(chunk)
                self.stamps.append((time.time(), len(self.raw)))
                sys.stdout.buffer.write(chunk)
                sys.stdout.buffer.flush()
        ser.close()


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--port", default="COM12")
    ap.add_argument("--baud", type=int, default=115200)
    ap.add_argument("--after-done-seconds", type=float, default=180.0)
    args = ap.parse_args()

    if not BIT.is_file():
        print(f"REFUSE: missing unique bit {BIT}", file=sys.stderr)
        return 2
    if not SHA.is_file():
        print(f"REFUSE: missing {SHA}", file=sys.stderr)
        return 2
    got = _sha256(BIT)
    want = SHA.read_text(encoding="ascii").strip().upper()
    if got != want:
        print(f"REFUSE: bit SHA {got} != {want}", file=sys.stderr)
        return 3
    if FORBIDDEN in got:
        print("REFUSE: SHA matches forbidden A0B338E0 family", file=sys.stderr)
        return 3
    print(f"BIT_SHA256={got}", flush=True)

    cap = Capture(args.port, args.baud)
    th = threading.Thread(target=cap.run, daemon=True)
    th.start()
    time.sleep(1.0)
    if cap.err:
        print(f"REFUSE: UART {cap.err}", file=sys.stderr)
        return 4

    env = os.environ.copy()
    env["XILINXD_LICENSE_FILE"] = r"D:\Xilinx\licenses\vivado_basic.lic"
    cmd = [str(VIVADO), "-mode", "batch", "-notrace", "-source", str(PROG)]
    print(f"PROGRAM_ONCE {cmd}", flush=True)
    proc = subprocess.run(
        cmd,
        cwd=str(ROOT),
        env=env,
        capture_output=True,
        text=True,
        check=False,
    )
    (BAG / "program_stdout.log").write_text(proc.stdout, encoding="utf-8")
    (BAG / "program_stderr.log").write_text(proc.stderr, encoding="utf-8")
    done_unix = 0.0
    for line in (proc.stdout or "").splitlines():
        if line.startswith("DONE_UNIX="):
            done_unix = float(line.split("=", 1)[1])
        print(line, flush=True)
    if proc.returncode != 0 or "CORE_START_RST_PROBE_BIT_PROGRAM_PASS" not in (proc.stdout or ""):
        print(f"PROGRAM_FAIL rc={proc.returncode}", file=sys.stderr)
        cap.stop.set()
        th.join(timeout=2)
        return 5
    if done_unix <= 0:
        done_unix = time.time()
        print(f"WARN no DONE_UNIX in log; using now={done_unix:.3f}", flush=True)
    print(f"DONE_BOUNDARY_UNIX={done_unix:.3f} — capture continues {args.after_done_seconds}s; no second program", flush=True)
    time.sleep(args.after_done_seconds)
    cap.stop.set()
    th.join(timeout=5)

    raw_path = BAG / "uart_raw.bin"
    txt_path = BAG / "uart_capture.txt"
    meta_path = BAG / "uart_capture.meta.txt"
    raw_path.write_bytes(bytes(cap.raw))
    txt_path.write_text(bytes(cap.raw).decode("ascii", errors="replace"), encoding="utf-8")
    prev = 0
    for ts, cum in cap.stamps:
        if ts < done_unix:
            prev = cum
    post = len(cap.raw) - prev
    meta = [
        f"port={args.port}",
        f"baud={args.baud}",
        f"open_unix={cap.t_open:.6f}",
        f"done_unix={done_unix:.6f}",
        f"close_unix={time.time():.6f}",
        f"bytes_total={len(cap.raw)}",
        f"bytes_before_done={prev}",
        f"bytes_after_done={post}",
        f"bit_sha256={got}",
        f"program_once=YES",
        f"second_program=NO",
    ]
    meta_path.write_text("\n".join(meta) + "\n", encoding="ascii")
    print(f"WROTE {raw_path} total={len(cap.raw)} after_done={post}", flush=True)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
