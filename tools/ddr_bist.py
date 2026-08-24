"""A7-LM-01 BIST host. 15-byte A5 72/81/82/84 over COM12. Uses FrameStream."""
from __future__ import annotations

import argparse
import json
import sys
import time
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT))
from python.uart_frames import lm02_cmd_frame, parse_frame
from python.uart_stream import FrameStream
import serial

UI_HZ = 83_333_333.0
MEM_BYTES = 268_435_456


def send(port, f: bytes) -> None:
    port.write(f)
    port.flush()


def wait_kind(stream: FrameStream, kind: int, t: float):
    deadline = time.monotonic() + t
    while time.monotonic() < deadline:
        raw = stream.get_frame(min(0.4, max(0.05, deadline - time.monotonic())))
        if not raw:
            continue
        rec = parse_frame(raw.data)
        if rec.get("ok") and rec.get("kind") == kind:
            return rec
    return None


def status(port, stream: FrameStream):
    send(port, lm02_cmd_frame(0x14))
    rec = wait_kind(stream, 0x81, 1.5)
    if not rec:
        return None
    raw = rec["raw"]
    flags = raw[2]
    return {
        "calib": bool(flags & 1),
        "busy": bool(flags & 2),
        "pass": bool(flags & 4),
        "phase": raw[3],
        "err": int.from_bytes(raw[4:8], "little"),
    }


def counters(port, stream: FrameStream):
    send(port, lm02_cmd_frame(0x15))
    rec = wait_kind(stream, 0x82, 1.5)
    if not rec:
        return None
    raw = rec["raw"]
    rd_b = int.from_bytes(raw[2:6], "little")
    rd_c = int.from_bytes(raw[6:10], "little")
    wr_b = int.from_bytes(raw[10:14], "little")
    rd_gbps = 0.0 if rd_c == 0 else (rd_b / (rd_c / UI_HZ)) / 1e9
    wr = write_counters(port, stream)
    wr_c = wr["wr_cycles"] if wr else 0
    wr_gbps = 0.0 if wr_c == 0 else (wr_b / (wr_c / UI_HZ)) / 1e9
    mix_c = rd_c + wr_c
    mix_gbps = 0.0 if mix_c == 0 else ((rd_b + wr_b) / (mix_c / UI_HZ)) / 1e9
    return {
        "rd_bytes": rd_b,
        "rd_cycles": rd_c,
        "wr_bytes": wr_b,
        "wr_cycles": wr_c,
        "rd_gbps": rd_gbps,
        "wr_gbps": wr_gbps,
        "mix_gbps": mix_gbps,
    }


def write_counters(port, stream: FrameStream):
    send(port, lm02_cmd_frame(0x17))
    rec = wait_kind(stream, 0x84, 1.5)
    if not rec:
        return None
    raw = rec["raw"]
    return {
        "wr_cycles": int.from_bytes(raw[2:6], "little"),
        "wr_bytes": int.from_bytes(raw[6:10], "little"),
    }


def soft_reset(port, stream: FrameStream, timeout_s: float = 8.0):
    send(port, lm02_cmd_frame(0x16))
    t0 = time.monotonic()
    saw_low = False
    last = None
    while time.monotonic() - t0 < timeout_s:
        last = status(port, stream)
        if last is None:
            continue
        if not last["calib"]:
            saw_low = True
        elif saw_low and last["calib"]:
            return {"ok": True, "status": last, "saw_low": True, "seconds": time.monotonic() - t0}
    return {"ok": False, "status": last, "saw_low": saw_low, "seconds": time.monotonic() - t0}


def wait_calib(port, stream: FrameStream, timeout_s: float = 8.0):
    t0 = time.monotonic()
    last = None
    while time.monotonic() - t0 < timeout_s:
        last = status(port, stream)
        if last and last["calib"]:
            return last
        time.sleep(0.1)
    return last


def run_bist(port, stream: FrameStream, mode: int, size: int, wait_s: float):
    st0 = status(port, stream)
    if not st0 or not st0["calib"]:
        return {"pass": False, "reason": "no_calib", "status": st0}
    send(port, lm02_cmd_frame(0x13, mode, size))
    t0 = time.monotonic()
    last = st0
    saw_busy = False
    while time.monotonic() - t0 < wait_s:
        time.sleep(0.05)
        cur = status(port, stream)
        if cur:
            last = cur
            if last["busy"]:
                saw_busy = True
            if saw_busy and not last["busy"]:
                break
            if not last["busy"] and time.monotonic() - t0 > 2.0 and (last["pass"] or last["err"]):
                break
    cnt = counters(port, stream)
    expected = {0: 0x0010_0000, 1: 0x0100_0000, 2: 0x1000_0000}[size]
    rd_ok = bool(cnt and int(cnt.get("rd_bytes") or 0) >= expected)
    wr_ok = bool(cnt and int(cnt.get("wr_bytes") or 0) >= expected)
    ok = bool(
        last
        and last["err"] == 0
        and last["calib"]
        and not last["busy"]
        and (last["pass"] or (rd_ok and wr_ok))
        and rd_ok
        and wr_ok
    )
    return {
        "status": last,
        "counters": cnt,
        "expected_bytes": expected,
        "pass": ok,
        "seconds": time.monotonic() - t0,
    }


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--port", default="COM12")
    ap.add_argument("--mode", type=int, default=0)
    ap.add_argument("--size", type=int, default=0, help="0=1MB 1=16MB 2=256MB")
    ap.add_argument("--wait", type=float, default=120.0)
    args = ap.parse_args()
    port = serial.Serial(args.port, 115200, timeout=0.05)
    time.sleep(0.3)
    stream = FrameStream(port)
    st0 = wait_calib(port, stream, 8.0)
    print("status0", st0)
    if not st0 or not st0["calib"]:
        print(json.dumps({"pass": False, "reason": "no_calib", "status": st0}, indent=2))
        port.close()
        return 2
    out = run_bist(port, stream, args.mode, args.size, args.wait)
    print(json.dumps(out, indent=2))
    port.close()
    return 0 if out["pass"] else 1


if __name__ == "__main__":
    raise SystemExit(main())
