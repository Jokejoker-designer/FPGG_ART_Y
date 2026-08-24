"""A0.3 silicon golden check. Law eam03e-a03-signed-h-v1.

Replays the exact tb_a7eam03e_a03.sv sequence over UART and compares against the
pre-registered bag in docs/contracts/A7-EAM-03E-A03.md. The expected integers
were published before the RTL existed; they are not editable here.

Host sends UTF-8 bytes, a slot index, a label bit, a seed and a mode flag. It
sends no gradient, no weight, no cue, no address and no winner.
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

BIT = ROOT / "build" / "out" / "arty_a7_eam03e_a03.bit"
BIT_SHA = "05E478FF53D8CEBE5CFDF79E1046E986F077F6E0117C714CDA794B38142BEC09"
OUT = ROOT / "results" / "A7-EAM-03E" / "A03_SIGNED" / "board_ladder_a03.json"
PORT, BAUD, RLEN = "COM12", 115200, 20

SA, SB, SC = b"ALPHA", b"BETA.", b"OMEGA"
SEED = 0x11111111
STEPS = 32

# pre-registered, from docs/contracts/A7-EAM-03E-A03.md — do not edit
EXPECT = {
    "init_AB": 739, "init_AC": 581,
    "train_AB": 164, "train_AC": 1957,
    "reset_AB": 742,
    "swap_AC": 137, "swap_AB": 1370,
}

# frozen artifacts that must never be disturbed by this lane
FROZEN = {
    "arty_a7_eam03e.bit": "80F2ED9E0C1A1679F87D5362F2D953258DEF640C6C2079E41B7BFBD7BCD12F41",
    "arty_a7_eam01r.bit": "57D1DF1BF86338A896876F6FBE204B1705128FFEC0A96F0582CF7EF90E9EF6CF",
    "arty_a7_eam02m.bit": "DB3BC58A6CC697FD0C290F97B5D6AD171AE7721A6C8A1E2DB2E87C5A84CFE696",
}


def sha256(path: Path) -> str:
    h = hashlib.sha256()
    with path.open("rb") as fh:
        for chunk in iter(lambda: fh.read(1 << 20), b""):
            h.update(chunk)
    return h.hexdigest().upper()


def xor_bytes(data: bytes) -> int:
    x = 0
    for b in data:
        x ^= b
    return x & 0xFF


def pack(cmd: int, payload: bytes = b"") -> bytes:
    if any(k in payload for k in (b"WAY", b"BRAM", b"GRAD")):
        raise ValueError("forbidden field")
    head = bytes([0xA5, cmd & 0xFF, len(payload) & 0xFF]) + payload
    return head + bytes([xor_bytes(head)])


def parse(rep: bytes) -> dict:
    if len(rep) != RLEN or rep[0] != 0x5A or xor_bytes(rep[:19]) != rep[19]:
        raise RuntimeError(f"bad reply {rep.hex()}")
    return {
        "kind": rep[1], "flags": rep[2], "dH": rep[3],
        "d1": int.from_bytes(rep[4:6], "little"),
        "cue": int.from_bytes(rep[6:14], "little"),
        "learn": bool(rep[18] & 1), "freeze": bool(rep[18] & 2),
    }


def xfer(ser, cmd: int, payload: bytes = b"", timeout: float = 12.0) -> dict:
    ser.reset_input_buffer()
    ser.write(pack(cmd, payload))
    ser.flush()
    t0, buf = time.time(), bytearray()
    while len(buf) < RLEN:
        if time.time() - t0 > timeout:
            raise TimeoutError(f"cmd=0x{cmd:02x} {buf.hex()}")
        chunk = ser.read(RLEN - len(buf))
        if chunk:
            buf.extend(chunk)
    return parse(bytes(buf))


def measure(ser, a: bytes, b: bytes, same: bool) -> dict:
    xfer(ser, 0x22, bytes([0, len(a)]) + a)
    xfer(ser, 0x22, bytes([1, len(b)]) + b)
    return xfer(ser, 0x23, bytes([1 if same else 0]))


def run(ser) -> dict:
    """Exact tb_a7eam03e_a03.sv order."""
    got = {}
    xfer(ser, 0x21, SEED.to_bytes(4, "little"))
    xfer(ser, 0x20, bytes([0]))               # learn=0 freeze=0
    measure(ser, SA, SB, True)                # prime after seed
    got["init_AB"] = measure(ser, SA, SB, True)["d1"]
    got["init_AC"] = measure(ser, SA, SC, False)["d1"]

    xfer(ser, 0x20, bytes([1]))               # learn=1
    for _ in range(STEPS):
        measure(ser, SA, SB, True)
        measure(ser, SA, SC, False)
    xfer(ser, 0x13)                           # learn=0 freeze=1
    got["train_AB"] = measure(ser, SA, SB, True)["d1"]
    got["train_AC"] = measure(ser, SA, SC, False)["d1"]

    xfer(ser, 0x21, SEED.to_bytes(4, "little"))
    xfer(ser, 0x20, bytes([0]))
    got["reset_AB"] = measure(ser, SA, SB, True)["d1"]

    xfer(ser, 0x20, bytes([1]))
    for _ in range(STEPS):
        measure(ser, SA, SC, True)
        measure(ser, SA, SB, False)
    xfer(ser, 0x13)
    got["swap_AC"] = measure(ser, SA, SC, True)["d1"]
    got["swap_AB"] = measure(ser, SA, SB, False)["d1"]
    return got


def main() -> int:
    loaded_sha = sha256(BIT) if BIT.exists() else None
    if loaded_sha != BIT_SHA:
        print(f"REFUSE: bit SHA mismatch\n  want {BIT_SHA}\n  have {loaded_sha}")
        return 2
    frozen = {}
    for name, expect in FROZEN.items():
        p = ROOT / "build" / "out" / name
        frozen[name] = sha256(p) == expect if p.exists() else None
    if any(v is False for v in frozen.values()):
        print("REFUSE: a frozen artifact changed", frozen)
        return 2

    ser = serial.Serial(PORT, BAUD, timeout=0.2)
    time.sleep(0.4)
    try:
        ping = xfer(ser, 0x01)
        if ping["kind"] != 0x81:
            raise RuntimeError(f"ping {ping}")
        got = run(ser)
    finally:
        ser.close()

    mismatch = {k: {"expect": EXPECT[k], "board": got[k]}
                for k in EXPECT if got[k] != EXPECT[k]}
    ok = not mismatch
    print(f"{'field':<10}{'xsim/pre-reg':>14}{'board':>8}  verdict")
    for k in EXPECT:
        print(f"{k:<10}{EXPECT[k]:>14}{got[k]:>8}  "
              + ("MATCH" if got[k] == EXPECT[k] else "*** MISMATCH ***"))
    verdict = "A7EAM03EA03_SILICON_EXACT_PASS" if ok else "A7EAM03EA03_SILICON_FAIL"
    print()
    print(verdict)

    rec = {
        "lane": "A7-EAM-03E-A0.3",
        "law": "eam03e-a03-signed-h-v1",
        "evidence_class": "BOARD",
        "board": {"part": "xc7a100tcsg324-1", "jtag": "210319BE776EA",
                  "uart": f"{PORT}@{BAUD}"},
        "bit": BIT.name, "bit_sha256": loaded_sha,
        "seed": f"0x{SEED:08X}", "steps": STEPS,
        "expected_prereg": EXPECT, "board": got,
        "mismatch": mismatch, "verdict": verdict,
        "ping": ping, "frozen_artifacts_intact": frozen,
        "claim": "board reproduces the pre-registered A0.3 XSim integers; "
                 "says nothing about representation quality",
        "ts": datetime.now(timezone.utc).isoformat(),
    }
    OUT.parent.mkdir(parents=True, exist_ok=True)
    OUT.write_text(json.dumps(rec, indent=2), encoding="utf-8")
    print(OUT)
    return 0 if ok else 1


if __name__ == "__main__":
    raise SystemExit(main())
