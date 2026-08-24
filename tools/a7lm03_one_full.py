"""One full last-token step on board vs oracle. Host compares only.

After a 0x31-capable bit: spot-read init, then optional full 25088 dump
and per-bank fold after the step. Does not compute board CE/pred/updates.
"""
from __future__ import annotations

import json
import sys
import time
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT))
from python.ref.a7lm03_fixed_ref import TinyGPT25k, bank_folds, bank_slices, fold_bytes
from python.uart_frames import lm03_payload_frame, parse_frame
from python.uart_stream import FrameStream
import serial


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
            rec.pop("raw", None)
            rec["hex"] = raw.data.hex()
            return rec
    return None


def status(port, stream):
    send(port, lm03_payload_frame(bytes([0x35]) + bytes(11)))
    rec = wait_kind(stream, 0xA1, 1.5)
    if not rec:
        return None
    raw = bytes.fromhex(rec["hex"])
    fl = raw[2]
    return {
        "after": bool(fl & 0x80),
        "busy": bool(fl & 0x40),
        "done": bool(fl & 0x20),
        "phase": raw[3],
        "wr_n": int.from_bytes(raw[4:8], "little"),
        "pred": raw[8],
        "loss": int.from_bytes(raw[9:11], "little"),
    }


def fold(port, stream):
    send(port, lm03_payload_frame(bytes([0x36]) + bytes(11)))
    rec = wait_kind(stream, 0xA2, 30.0)
    if not rec:
        return None
    raw = bytes.fromhex(rec["hex"])
    return {
        "xor32": int.from_bytes(raw[2:6], "little"),
        "add32": int.from_bytes(raw[6:10], "little"),
        "wr_n": int.from_bytes(raw[10:14], "little"),
    }


def read8(port, stream, addr: int):
    body = bytes([0x31, addr & 0xFF, (addr >> 8) & 0x7F]) + bytes(9)
    send(port, lm03_payload_frame(body))
    rec = wait_kind(stream, 0xA4, 1.5)
    if not rec:
        return None
    return rec.get("data")


def dump_all(port, stream, n: int = 25088) -> list[int] | None:
    blob: list[int] = []
    for addr in range(0, n, 8):
        got = read8(port, stream, addr)
        if got is None:
            return None
        take = min(8, n - addr)
        blob.extend(int(b) & 0xFF for b in got[:take])
        if (addr & 0x3FF) == 0:
            print(f"dump {addr}/{n}", flush=True)
    return blob


def wait_idle(port, stream, timeout_s: float):
    t0 = time.monotonic()
    last = None
    saw_busy = False
    while time.monotonic() - t0 < timeout_s:
        last = status(port, stream)
        if last and last["busy"]:
            saw_busy = True
        if last and saw_busy and not last["busy"]:
            return last
        if last and not last["busy"] and time.monotonic() - t0 > 0.4:
            return last
        time.sleep(0.05)
    return last


def main() -> int:
    port_name = sys.argv[1] if len(sys.argv) > 1 else "COM12"
    do_dump = "--dump" in sys.argv[2:]
    port = serial.Serial(port_name, 115200, timeout=0.05)
    time.sleep(0.3)
    stream = FrameStream(port)
    send(port, lm03_payload_frame(bytes([0x38, 0]) + bytes(10)))
    model0 = TinyGPT25k(2)
    blob0 = model0.flat_i8()
    print("upload", len(blob0), flush=True)
    for i, b in enumerate(blob0):
        addr = i & 0x7FFF
        send(port, lm03_payload_frame(bytes([0x30, addr & 0xFF, (addr >> 8) & 0x7F, b & 0xFF]) + bytes(8)))
        if (i & 0xFF) == 0xFF:
            time.sleep(0.002)
    spots = [0, 1, 4096, 4608, 20992]
    spot_ok = True
    spot_rec = []
    for a in spots:
        got = read8(port, stream, a)
        exp = [blob0[a + i] & 0xFF for i in range(min(8, 25088 - a))]
        match = got == exp
        spot_ok = spot_ok and match
        spot_rec.append({"addr": a, "exp": exp, "got": got, "match": match})
        print("spot", a, "match", match, flush=True)
    f0 = fold(port, stream)
    print("fold0", f0, flush=True)
    send(port, lm03_payload_frame(bytes([0x32, 0, 1, 1]) + bytes(8)))
    send(port, lm03_payload_frame(bytes([0x34, 16, 3]) + bytes(9)))
    st = wait_idle(port, stream, 60.0)
    print("after_train", st, flush=True)
    f1 = fold(port, stream)
    print("fold1", f1, flush=True)
    model1 = TinyGPT25k(2)
    model1.backward_full([1], 16, lr=3, apply=True)
    ref1 = model1.flat_i8()
    banks = None
    dump_fold = None
    if do_dump:
        dumped = dump_all(port, stream)
        if dumped is None:
            banks = {"error": "dump timeout"}
        else:
            bf = bank_folds(dumped)
            rf = bank_folds(ref1)
            dump_fold = fold_bytes(dumped)
            banks = {}
            for name, off, _n in bank_slices():
                banks[name] = {
                    "board": bf[name],
                    "oracle": rf[name],
                    "match": bf[name]["xor32"] == rf[name]["xor32"]
                    and bf[name]["add32"] == rf[name]["add32"],
                    "off": off,
                }
                print(f"bank {name} match={banks[name]['match']} board={bf[name]} oracle={rf[name]}", flush=True)
    out = {
        "spots": spot_rec,
        "spot_ok": spot_ok,
        "fold0": f0,
        "status": st,
        "fold1": f1,
        "expect_fold0": {"xor32": 0, "add32": 2958688},
        "expect_fold1": {"xor32": 255, "add32": 2943381},
        "expect_head_only": {"xor32": 173, "add32": 2962299},
        "match0": bool(f0 and f0["xor32"] == 0 and f0["add32"] == 2958688),
        "match1": bool(f1 and f1["xor32"] == 255 and f1["add32"] == 2943381),
        "banks": banks,
        "dump_fold": dump_fold,
    }
    print(json.dumps(out, indent=2))
    port.close()
    return 0 if out["match0"] and out["match1"] and spot_ok else 1


if __name__ == "__main__":
    raise SystemExit(main())
