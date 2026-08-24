"""A7-EAM-03E-A0 silicon. Encoder-only SAME/DIFF. Host sends bytes+label only."""
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

BIT = ROOT / "build" / "out" / "arty_a7_eam03e.bit"
OUT = ROOT / "results" / "A7-EAM-03E" / "ladder_a0.json"
PORT = "COM12"
BAUD = 115200
RLEN = 20

FROZEN = {
    "arty_a7_lm06c3.bit": "222F804351261B5878D73E5501E4E34A28D330B09BB4BC3E1590EE79402884C6",
    "arty_a7_eam01r.bit": "57D1DF1BF86338A896876F6FBE204B1705128FFEC0A96F0582CF7EF90E9EF6CF",
    "arty_a7_eam02m.bit": "DB3BC58A6CC697FD0C290F97B5D6AD171AE7721A6C8A1E2DB2E87C5A84CFE696",
}

SA = b"ALPHA"
SB = b"BETA."
SC = b"OMEGA"
STEPS = 32  # match A0.1-T xsim goldens; A0 silicon.md used 24


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
    if any(k in payload for k in (b"WAY", b"BRAM", b"GRAD")):
        raise ValueError("forbidden field")
    head = bytes([0xA5, cmd & 0xFF, len(payload) & 0xFF]) + payload
    return head + bytes([xor_bytes(head)])


def parse(rep: bytes) -> dict:
    if len(rep) != RLEN or rep[0] != 0x5A or xor_bytes(rep[:19]) != rep[19]:
        raise RuntimeError(f"bad reply {rep.hex()}")
    return {
        "kind": rep[1],
        "flags": rep[2],
        "dH": rep[3],
        "d1": int.from_bytes(rep[4:6], "little"),
        "cue": int.from_bytes(rep[6:14], "little"),
        "learn": bool(rep[18] & 1),
        "freeze": bool(rep[18] & 2),
    }


def xfer(ser: serial.Serial, cmd: int, payload: bytes = b"", timeout: float = 12.0) -> dict:
    ser.reset_input_buffer()
    ser.write(pack(cmd, payload))
    ser.flush()
    t0 = time.time()
    buf = bytearray()
    while len(buf) < RLEN:
        if time.time() - t0 > timeout:
            raise TimeoutError(f"cmd=0x{cmd:02x} {buf.hex()}")
        chunk = ser.read(RLEN - len(buf))
        if chunk:
            buf.extend(chunk)
    return parse(bytes(buf))


def buf(ser, slot: int, text: bytes) -> dict:
    return xfer(ser, 0x22, bytes([slot, len(text)]) + text)


def pair(ser, same: bool) -> dict:
    return xfer(ser, 0x23, bytes([1 if same else 0]))


def measure(ser, a: bytes, b: bytes, same: bool) -> dict:
    buf(ser, 0, a)
    buf(ser, 1, b)
    return pair(ser, same)


def run_seed(ser, seed: int, swap: bool) -> dict:
    xfer(ser, 0x21, seed.to_bytes(4, "little"))
    xfer(ser, 0x20, bytes([0]))  # learn=0 freeze=0
    measure(ser, SA, SB, True)  # prime after seed
    pre_ab = measure(ser, SA, SB, True)
    pre_ac = measure(ser, SA, SC, False)
    xfer(ser, 0x20, bytes([1]))  # learn=1
    for _ in range(STEPS):
        if not swap:
            measure(ser, SA, SB, True)
            measure(ser, SA, SC, False)
        else:
            measure(ser, SA, SC, True)
            measure(ser, SA, SB, False)
    xfer(ser, 0x13)  # freeze
    post_ab = measure(ser, SA, SB, True)
    post_ac = measure(ser, SA, SC, False)
    return {
        "seed": seed,
        "swap": swap,
        "pre_ab": pre_ab,
        "pre_ac": pre_ac,
        "post_ab": post_ab,
        "post_ac": post_ac,
    }


def main() -> int:
    frozen = {}
    for name, expect in FROZEN.items():
        p = ROOT / "build" / "out" / name
        frozen[name] = sha256(p) == expect if p.exists() else None

    ser = serial.Serial(PORT, BAUD, timeout=0.2)
    time.sleep(0.4)
    notes = []
    try:
        ping = xfer(ser, 0x01)
        if ping["kind"] != 0x81:
            raise RuntimeError(f"ping {ping}")
        r0 = run_seed(ser, 0x11111111, False)
        # reset erase
        xfer(ser, 0x21, (0x11111111).to_bytes(4, "little"))
        xfer(ser, 0x20, bytes([0]))
        rst = measure(ser, SA, SB, True)
        r1 = run_seed(ser, 0x11111111, True)
        r2 = run_seed(ser, 0x22222222, False)

        def ok_map(r, same_ab: bool) -> bool:
            if same_ab:
                return r["post_ab"]["d1"] < r["pre_ab"]["d1"] and r["post_ac"]["d1"] > r["post_ab"]["d1"]
            return r["post_ac"]["d1"] < r["pre_ac"]["d1"] and r["post_ab"]["d1"] > r["post_ac"]["d1"]

        checks = {
            "map0_same_shrink": r0["post_ab"]["d1"] < r0["pre_ab"]["d1"],
            "map0_diff_gt_same": r0["post_ac"]["d1"] > r0["post_ab"]["d1"],
            "reset_erases": rst["d1"] > r0["post_ab"]["d1"],
            "swap_new_geometry": r1["post_ac"]["d1"] < r1["post_ab"]["d1"],
            "seed2_same_shrink": r2["post_ab"]["d1"] < r2["pre_ab"]["d1"],
        }
        if r0["post_ab"]["dH"] >= 8 and r0["post_ab"]["dH"] >= r0["pre_ab"]["dH"]:
            notes.append("dH_same did not drop under 8 — A1 stays closed")
        verdict = "A7EAM03EA0_PASS" if all(checks.values()) else "A7EAM03EA0_FAIL"
        if verdict.endswith("PASS") and notes:
            verdict = "A7EAM03EA0_PASS_WITH_NOTES"
        rec = {
            "lane": "A7-EAM-03E-A0",
            "law": "eam03e-a0-signsgd-v1",
            "claim": "FPGA SAME closer / DIFF farther on train pairs; NOT unseen paraphrase",
            "verdict": verdict,
            "ping": ping,
            "checks": checks,
            "notes": notes,
            "runs": [r0, {"reset_ab": rst}, r1, r2],
            "frozen": frozen,
            "ts": datetime.now(timezone.utc).isoformat(),
        }
    except Exception as exc:
        verdict = f"A7EAM03EA0_FAIL {exc}"
        rec = {"verdict": verdict, "error": str(exc)}
    finally:
        ser.close()

    OUT.parent.mkdir(parents=True, exist_ok=True)
    OUT.write_text(json.dumps(rec, indent=2), encoding="utf-8")
    print(verdict)
    print(OUT)
    return 0 if str(verdict).startswith("A7EAM03EA0_PASS") else 1


if __name__ == "__main__":
    raise SystemExit(main())
