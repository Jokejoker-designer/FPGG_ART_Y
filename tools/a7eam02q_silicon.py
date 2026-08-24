"""02Q silicon: LOADH + ENC twin vs host Q1. Then MAP_H / PROBE_H.

Not semantic evidence. Host sends INT16 hidden only — no precomputed winner.
"""
from __future__ import annotations

import hashlib
import json
import sys
import time
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT))

import serial  # noqa: E402

from python.eam.qenc import D_MODEL, Q1_LAW, Q1_SEED, encode_q1  # noqa: E402

BIT = ROOT / "build" / "out" / "arty_a7_eam02q.bit"
OUT = ROOT / "results" / "A7-EAM-02Q" / "silicon_q1.json"
PORT = "COM12"
BAUD = 115200
RLEN = 20

FROZEN = {
    "arty_a7_lm06c3.bit": "222F804351261B5878D73E5501E4E34A28D330B09BB4BC3E1590EE79402884C6",
    "arty_a7_eam00b.bit": "7CBB0CFCC9F3A05D7EF2993AF3F7283CD63508D0C1806A3074560B511E292C8D",
    "arty_a7_eam01r.bit": "57D1DF1BF86338A896876F6FBE204B1705128FFEC0A96F0582CF7EF90E9EF6CF",
}


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
    head = bytes([0xA5, cmd & 0xFF, len(payload) & 0xFF]) + payload
    return head + bytes([xor_bytes(head)])


def transact(ser: serial.Serial, pkt: bytes, timeout: float = 2.0) -> bytes:
    ser.reset_input_buffer()
    ser.write(pkt)
    ser.flush()
    t0 = time.time()
    buf = bytearray()
    while len(buf) < RLEN and time.time() - t0 < timeout:
        chunk = ser.read(RLEN - len(buf))
        if chunk:
            buf.extend(chunk)
    if len(buf) != RLEN or buf[0] != 0x5A or xor_bytes(buf[:19]) != buf[19]:
        raise RuntimeError(f"bad reply {bytes(buf).hex()}")
    return bytes(buf)


def h_bytes(h: list[int]) -> bytes:
    return b"".join(int(x).to_bytes(2, "little", signed=True) for x in h)


def load_h(ser: serial.Serial, h: list[int]) -> None:
    raw = h_bytes(h)
    if len(raw) != 256:
        raise ValueError("hidden must be 256 bytes")
    for blk in range(16):
        pay = bytes([blk]) + raw[blk * 16 : (blk + 1) * 16]
        rep = transact(ser, pack(0x09, pay))
        if rep[1] != 0x83:
            raise RuntimeError(f"LOADH blk={blk} kind={rep[1]:02x}")


def enc_key(ser: serial.Serial) -> int:
    rep = transact(ser, pack(0x0C), timeout=3.0)
    if rep[1] != 0x84:
        raise RuntimeError(f"ENC kind={rep[1]:02x}")
    return int.from_bytes(rep[3:11], "little")


def map_h(ser: serial.Serial, vec: int, tok: int, probe: bool) -> dict:
    pay = vec.to_bytes(16, "little") + bytes([tok & 0xFF])
    cmd = 0x0B if probe else 0x0A
    rep = transact(ser, pack(cmd, pay), timeout=8.0)
    if rep[1] != 0x82:
        raise RuntimeError(f"MAP/PROBE kind={rep[1]:02x}")
    return {"hit": bool(rep[2] & 1), "token": rep[3], "hamming": rep[4]}


def vectors() -> list[list[int]]:
    return [
        [0] * D_MODEL,
        [1] * D_MODEL,
        [5 if (i % 3) else -3 for i in range(D_MODEL)],
        [i - 64 for i in range(D_MODEL)],
    ]


def main() -> int:
    if not BIT.exists():
        print("MISSING_BIT", BIT)
        return 2
    bit_sha = sha256(BIT)
    drift = []
    for name, exp in FROZEN.items():
        p = BIT.parent / name
        if p.exists() and sha256(p) != exp:
            drift.append(name)
    if drift:
        print("HASH_DRIFT", drift)
        return 3

    ser = serial.Serial(PORT, BAUD, timeout=0.2)
    try:
        time.sleep(0.3)
        pong = transact(ser, pack(0x01))
        if pong[1] != 0x81 or pong[3:6] != b"Q1R":
            print("PING_FAIL", pong.hex())
            return 4
        twins = []
        for h in vectors():
            load_h(ser, h)
            got = enc_key(ser)
            exp = encode_q1(h)
            twins.append({"got": f"{got:016x}", "exp": f"{exp:016x}", "ok": got == exp})
        if not all(t["ok"] for t in twins):
            print("TWIN_FAIL", json.dumps(twins))
            return 5
        h0 = vectors()[2]
        load_h(ser, h0)
        m = map_h(ser, 0x1111, 0xA1, probe=False)
        load_h(ser, h0)
        p = map_h(ser, 0, 0, probe=True)
        far = [((i * 13) % 401) - 200 for i in range(D_MODEL)]
        load_h(ser, far)
        f = map_h(ser, 0, 0, probe=True)
    finally:
        ser.close()

    ok = (not m["hit"]) and p["hit"] and p["token"] == 0xA1 and p["hamming"] == 0 and (not f["hit"])
    report = {
        "law": Q1_LAW,
        "seed": Q1_SEED,
        "bit_sha": bit_sha,
        "ping": "Q1R",
        "twins": twins,
        "map_miss": m,
        "probe_hit": p,
        "far_miss": f,
        "semantic_evidence": False,
        "pass": bool(ok),
    }
    OUT.parent.mkdir(parents=True, exist_ok=True)
    OUT.write_text(json.dumps(report, indent=2), encoding="utf-8")
    print(json.dumps(report, indent=2))
    print("A7EAM02Q_SILICON_PASS" if ok else "A7EAM02Q_SILICON_FAIL")
    return 0 if ok else 6


if __name__ == "__main__":
    raise SystemExit(main())
