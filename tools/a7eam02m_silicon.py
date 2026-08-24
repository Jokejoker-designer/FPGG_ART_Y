"""A7-EAM-02M silicon ladder. Multi-cue bind, not paraphrase.

Host sends OPEN value + BIND/PROBE cues (or UTF-8 for fold). Never a winner address.
"""
from __future__ import annotations

import hashlib
import json
import sys
import time
from datetime import datetime, timezone
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT))

import serial  # noqa: E402

from python.eam.fold02m import fold_bytes  # noqa: E402

BIT = ROOT / "build" / "out" / "arty_a7_eam02m.bit"
OUT = ROOT / "results" / "A7-EAM-02M" / "ladder_02m.json"
PORT = "COM12"
BAUD = 115200
RLEN = 20

FROZEN = {
    "arty_a7_lm00.bit": "449A330BD2E23E1D9714ECF94142A0555914D6C76EDE6310EF347A3596534783",
    "arty_a7_lm05.bit": "1AA0B5C481B0ADF3CAA599F081B430AF3C28A26FB4715DC56A0D25D940548F51",
    "arty_a7_lm06c3.bit": "222F804351261B5878D73E5501E4E34A28D330B09BB4BC3E1590EE79402884C6",
    "arty_a7_eam00b.bit": "7CBB0CFCC9F3A05D7EF2993AF3F7283CD63508D0C1806A3074560B511E292C8D",
    "arty_a7_eam01r.bit": "57D1DF1BF86338A896876F6FBE204B1705128FFEC0A96F0582CF7EF90E9EF6CF",
}

CUE_A = "FPGA nào đang dùng?".encode("utf-8")
CUE_B = "Board hiện tại dùng chip gì?".encode("utf-8")
CUE_UNREL = "xin chao the gioi!!!!!".encode("utf-8")


def sha256(path: Path) -> str:
    h = hashlib.sha256()
    with path.open("rb") as handle:
        for chunk in iter(lambda: handle.read(1 << 20), b""):
            h.update(chunk)
    return h.hexdigest().upper()


def xor_bytes(data: bytes) -> int:
    x = 0
    for b in data:
        x ^= b
    return x & 0xFF


def pack(cmd: int, payload: bytes = b"") -> bytes:
    if any(k in payload for k in (b"WAY", b"BRAM")):
        raise ValueError("forbidden field")
    head = bytes([0xA5, cmd & 0xFF, len(payload) & 0xFF]) + payload
    return head + bytes([xor_bytes(head)])


def parse(rep: bytes) -> dict:
    if len(rep) != RLEN or rep[0] != 0x5A or xor_bytes(rep[:19]) != rep[19]:
        raise RuntimeError(f"bad reply {rep.hex()}")
    flags = rep[2]
    return {
        "kind": rep[1],
        "hit": bool(flags & 1),
        "collide": bool(flags & 8),
        "teacher_off": bool(flags & 16),
        "value_token": rep[3],
        "hamming": rep[4],
        "second_or_nack": rep[5],
        "episode_id": rep[14],
        "cue_n": rep[15],
        "epoch": rep[18],
    }


def xfer(ser: serial.Serial, cmd: int, payload: bytes = b"", timeout: float = 8.0) -> dict:
    ser.reset_input_buffer()
    ser.write(pack(cmd, payload))
    ser.flush()
    t0 = time.time()
    buf = bytearray()
    while len(buf) < RLEN:
        if time.time() - t0 > timeout:
            raise TimeoutError(f"cmd=0x{cmd:02x} got {buf.hex()}")
        chunk = ser.read(RLEN - len(buf))
        if chunk:
            buf.extend(chunk)
    return parse(bytes(buf))


def open_ep(ser, token: int = 0xA7) -> dict:
    vec = bytes([token]) * 16
    return xfer(ser, 0x10, vec + bytes([token]))


def bind_txt(ser, epid: int, text: bytes) -> dict:
    return xfer(ser, 0x14, bytes([epid, len(text)]) + text)


def probe_txt(ser, text: bytes) -> dict:
    return xfer(ser, 0x15, bytes([len(text)]) + text)


def probe_key(ser, key: int) -> dict:
    return xfer(ser, 0x12, key.to_bytes(8, "little"))


def main() -> int:
    frozen_ok = {}
    for name, expect in FROZEN.items():
        p = ROOT / "build" / "out" / name
        frozen_ok[name] = sha256(p) == expect if p.exists() else None

    ping = None
    steps = []
    ser = serial.Serial(PORT, BAUD, timeout=0.2)
    time.sleep(0.3)
    try:
        ping = xfer(ser, 0x01)
        if ping["kind"] != 0x81 or ping["value_token"] != 0x4D:
            raise RuntimeError(f"bad ping {ping}")
        xfer(ser, 0x04)
        time.sleep(0.05)
        o = open_ep(ser, 0xA7)
        steps.append(("open", o))
        if o["kind"] not in (0x90,) or o["episode_id"] != 0:
            raise RuntimeError(f"open {o}")
        epid = o["episode_id"]
        ba = bind_txt(ser, epid, CUE_A)
        bb = bind_txt(ser, epid, CUE_B)
        steps.append(("bind_a", ba))
        steps.append(("bind_b", bb))
        if ba["cue_n"] != 1 or bb["cue_n"] != 2 or bb["episode_id"] != epid:
            raise RuntimeError(f"bind {ba} {bb}")
        toff = xfer(ser, 0x13)
        steps.append(("teacher_off", toff))
        pa = probe_txt(ser, CUE_A)
        pb = probe_txt(ser, CUE_B)
        pu = probe_txt(ser, CUE_UNREL)
        steps.append(("probe_a", pa))
        steps.append(("probe_b", pb))
        steps.append(("probe_unrel", pu))
        if not pa["hit"] or not pb["hit"]:
            raise RuntimeError(f"probe miss {pa} {pb}")
        if pa["episode_id"] != pb["episode_id"] or pa["value_token"] != 0xA7:
            raise RuntimeError(f"episode mismatch {pa} {pb}")
        if pu["hit"]:
            raise RuntimeError(f"unrelated hit {pu}")
        ka = fold_bytes(CUE_A)
        flip = probe_key(ser, ka ^ 1)
        steps.append(("probe_1flip", flip))
        if not flip["hit"] or flip["episode_id"] != epid or flip["hamming"] != 1:
            raise RuntimeError(f"1flip {flip}")
        nack = bind_txt(ser, epid, CUE_UNREL)
        steps.append(("bind_after_toff", nack))
        if nack["kind"] != 0x9E or nack["second_or_nack"] != 1:
            raise RuntimeError(f"expected teacher-off nack {nack}")
        verdict = "A7EAM02M_PASS"
    except Exception as exc:
        verdict = f"A7EAM02M_FAIL {exc}"
        steps.append(("error", str(exc)))
    finally:
        ser.close()

    OUT.parent.mkdir(parents=True, exist_ok=True)
    rec = {
        "lane": "A7-EAM-02M",
        "law": "eam02m-bind-v1",
        "claim": "multi-cue exact bind; NOT unseen paraphrase",
        "verdict": verdict,
        "ping": ping,
        "steps": steps,
        "fold_keys": {
            "A": f"{fold_bytes(CUE_A):016x}",
            "B": f"{fold_bytes(CUE_B):016x}",
        },
        "frozen": frozen_ok,
        "ts": datetime.now(timezone.utc).isoformat(),
    }
    OUT.write_text(json.dumps(rec, indent=2), encoding="utf-8")
    print(verdict)
    print(OUT)
    return 0 if verdict == "A7EAM02M_PASS" else 1


if __name__ == "__main__":
    raise SystemExit(main())
