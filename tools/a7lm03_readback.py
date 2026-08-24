"""A7-LM-03 0x31 -> 0xA4 weight readback. Host compares only."""
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


def read8(port, stream, addr: int):
    body = bytes([0x31, addr & 0xFF, (addr >> 8) & 0x7F]) + bytes(9)
    send(port, lm03_payload_frame(body))
    rec = wait_kind(stream, 0xA4, 1.5)
    if not rec:
        return None
    return rec


def dump_all(port, stream, n: int = 25088) -> list[int] | None:
    blob: list[int] = []
    for addr in range(0, n, 8):
        rec = read8(port, stream, addr)
        if rec is None:
            return None
        take = min(8, n - addr)
        blob.extend(int(b) & 0xFF for b in rec["data"][:take])
        if (addr & 0x3FF) == 0:
            print(f"dump {addr}/{n}", flush=True)
    return blob


def main() -> int:
    port_name = sys.argv[1] if len(sys.argv) > 1 else "COM12"
    mode = sys.argv[2] if len(sys.argv) > 2 else "spot"
    port = serial.Serial(port_name, 115200, timeout=0.05)
    time.sleep(0.3)
    stream = FrameStream(port)
    ref = TinyGPT25k(2).flat_i8()
    spots = [0, 1, 8, 4096, 4608, 8704, 20992, 25080]
    out: dict = {"mode": mode, "spots": []}
    ok = True
    if mode == "spot":
        for a in spots:
            rec = read8(port, stream, a)
            exp = [ref[a + i] & 0xFF for i in range(min(8, 25088 - a))]
            got = None if rec is None else rec.get("data", [])[: len(exp)]
            match = got == exp
            ok = ok and match
            out["spots"].append({"addr": a, "exp": exp, "got": got, "match": match})
            print(f"spot {a} match={match} got={got} exp={exp}", flush=True)
    else:
        blob = dump_all(port, stream)
        if blob is None:
            out["error"] = "dump timeout"
            ok = False
        else:
            bf = bank_folds(blob)
            rf = bank_folds(ref)
            out["fold"] = fold_bytes(blob)
            out["ref_fold"] = fold_bytes(ref)
            out["banks"] = {}
            for name, off, _n in bank_slices():
                m = bf[name] == rf[name]
                out["banks"][name] = {"board": bf[name], "ref": rf[name], "match": m, "off": off}
                if not m:
                    ok = False
                    print(f"BANK_MISMATCH {name} board={bf[name]} ref={rf[name]}", flush=True)
            out["fold_match"] = out["fold"] == out["ref_fold"]
            ok = ok and out["fold_match"]
    out["ok"] = ok
    print(json.dumps(out, indent=2))
    port.close()
    return 0 if ok else 1


if __name__ == "__main__":
    raise SystemExit(main())
