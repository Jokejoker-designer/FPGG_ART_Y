"""Long-sequence twin <-> board equivalence for law `eam03e-a03-signed-h-v1`.

Why this matters more than another golden check: every conclusion in this program
about 10k and 100k update horizons is REFERENCE MODEL evidence produced by
`python/eam/eam03e_twin.py`. That twin has only ever been validated against a
32-step ladder. If it drifts from silicon after a few hundred updates, every
long-horizon closeout rests on nothing.

This runs the same deterministic transaction sequence on the board and on the
twin in lockstep, learning enabled, and compares `d1` and `dH` after every
single transaction. It reports the first divergence rather than an aggregate, so
a single mismatched integer is visible.

Host sends UTF-8 bytes, a slot index, a label bit, a seed and a mode flag. No
gradient, weight, cue, address or winner crosses the link in either direction.
"""
from __future__ import annotations

import argparse
import hashlib
import json
import sys
import time
from datetime import datetime, timezone
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT))
sys.path.insert(0, str(ROOT / "tools"))
import serial  # noqa: E402

import a7eam03e_stability as stab  # noqa: E402
import python.eam.eam03e_twin as tw  # noqa: E402
from python.eam.eam03e_bench import (  # noqa: E402
    build_name_dataset,
    group_split,
)
from python.eam.eam03e_twin import Eam03eTwin, golden_check  # noqa: E402

BIT = ROOT / "build" / "out" / "arty_a7_eam03e_a03.bit"
BIT_SHA = "05E478FF53D8CEBE5CFDF79E1046E986F077F6E0117C714CDA794B38142BEC09"
PORT, BAUD, RLEN = "COM12", 115200, 20
SEED = 0x11111111


def sha256(path: Path) -> str:
    h = hashlib.sha256()
    with path.open("rb") as fh:
        for chunk in iter(lambda: fh.read(1 << 20), b""):
            h.update(chunk)
    return h.hexdigest().upper()


def xorb(d: bytes) -> int:
    x = 0
    for b in d:
        x ^= b
    return x & 0xFF


def pack(cmd: int, payload: bytes = b"") -> bytes:
    head = bytes([0xA5, cmd & 0xFF, len(payload) & 0xFF]) + payload
    return head + bytes([xorb(head)])


def parse(rep: bytes) -> dict:
    if len(rep) != RLEN or rep[0] != 0x5A or xorb(rep[:19]) != rep[19]:
        raise RuntimeError(f"bad reply {rep.hex()}")
    return {"kind": rep[1], "dH": rep[3],
            "d1": int.from_bytes(rep[4:6], "little"),
            "learn": bool(rep[18] & 1), "freeze": bool(rep[18] & 2)}


def xfer(ser, cmd: int, payload: bytes = b"", timeout: float = 12.0) -> dict:
    ser.reset_input_buffer()
    ser.write(pack(cmd, payload))
    ser.flush()
    t0, buf = time.time(), bytearray()
    while len(buf) < RLEN:
        if time.time() - t0 > timeout:
            raise TimeoutError(f"cmd=0x{cmd:02x} got {buf.hex()}")
        c = ser.read(RLEN - len(buf))
        if c:
            buf.extend(c)
    return parse(bytes(buf))


def board_measure(ser, a: str, b: str, same: bool) -> dict:
    ab, bb = a.encode("utf-8")[:46], b.encode("utf-8")[:46]
    xfer(ser, 0x22, bytes([0, len(ab)]) + ab)
    xfer(ser, 0x22, bytes([1, len(bb)]) + bb)
    return xfer(ser, 0x23, bytes([1 if same else 0]))


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--transactions", type=int, default=2000)
    ap.add_argument("--out", default="results/A7-EAM-03E/A03_SIGNED")
    args = ap.parse_args()

    have = sha256(BIT) if BIT.exists() else None
    if have != BIT_SHA:
        print(f"REFUSE: bit SHA mismatch\n  want {BIT_SHA}\n  have {have}")
        return 2
    gc = golden_check()
    if not gc["pass"]:
        print("REFUSE: twin fails its own A0.1-T goldens", gc["mismatch"])
        return 2

    # A0.3 law on the twin: signed h, DIFF gate left at the contract value.
    tw.h_update = stab.h_update_signed

    base = build_name_dataset(n_entities=260, seed=0)
    parts = group_split(base.train + base.dev + base.test, fracs=(0.6, 0.2, 0.2), seed=0)
    rows = parts["train"]

    twin = Eam03eTwin(SEED)
    ser = serial.Serial(PORT, BAUD, timeout=0.2)
    time.sleep(0.4)
    first_div = None
    compared = 0
    t0 = time.time()
    try:
        ping = xfer(ser, 0x01)
        if ping["kind"] != 0x81:
            raise RuntimeError(f"ping {ping}")
        xfer(ser, 0x21, SEED.to_bytes(4, "little"))
        xfer(ser, 0x20, bytes([0]))
        twin.reseed(SEED)
        twin.mode(learn=False, freeze=False)

        # e_ra alignment. `e_ra` has no reset in the RTL and S_SEED never writes
        # it, so a board that has run anything before carries a stale read
        # address while a freshly constructed twin starts at 0. The address is
        # fully determined by the last byte processed, so one forward on each
        # side aligns them. Prime twice with learn=0: the first aligns, the
        # second must agree, which proves alignment before any comparison that
        # counts. Weights cannot move here because learn=0.
        for k in range(2):
            b0 = board_measure(ser, rows[0].a, rows[0].b, True)
            t_0 = twin.measure(rows[0].a, rows[0].b, True)
            same = (b0["d1"], b0["dH"]) == (t_0.d1, t_0.dH)
            print(f"  prime {k}: board d1={b0['d1']} dH={b0['dH']}  "
                  f"twin d1={t_0.d1} dH={t_0.dH}  "
                  f"{'aligned' if same else 'not yet aligned'}")
            if k == 1 and not same:
                first_div = {"i": -1, "phase": "prime2_alignment_failed",
                             "board": [b0["d1"], b0["dH"]],
                             "twin": [t_0.d1, t_0.dH]}

        if first_div is not None:
            raise RuntimeError("e_ra alignment failed; comparison would be meaningless")

        xfer(ser, 0x20, bytes([1]))
        twin.mode(learn=True, freeze=False)

        for i in range(args.transactions):
            p = rows[i % len(rows)]
            b = board_measure(ser, p.a, p.b, p.same)
            t = twin.measure(p.a, p.b, p.same)
            compared += 1
            if (b["d1"], b["dH"]) != (t.d1, t.dH):
                if first_div is None:
                    first_div = {"i": i, "text_a": p.a, "text_b": p.b,
                                 "same": p.same,
                                 "board": [b["d1"], b["dH"]],
                                 "twin": [t.d1, t.dH]}
                break
            if (i + 1) % 250 == 0:
                print(f"  {i+1:>5} transactions, still exact "
                      f"(d1={b['d1']} dH={b['dH']}, {time.time()-t0:.0f}s)",
                      flush=True)
    finally:
        ser.close()

    ok = first_div is None
    print()
    print(f"compared {compared} transactions with learning enabled")
    if ok:
        print("A7EAM03EA03_TWIN_BOARD_EQUIV_PASS")
    else:
        print("A7EAM03EA03_TWIN_BOARD_DIVERGENCE")
        print(json.dumps(first_div, indent=2))

    rec = {
        "test": "long-sequence twin<->board equivalence",
        "law": "eam03e-a03-signed-h-v1",
        "evidence_class": "BOARD + REFERENCE_MODEL comparison",
        "bit": BIT.name, "bit_sha256": have,
        "board": {"jtag": "210319BE776EA", "uart": f"{PORT}@{BAUD}",
                  "part": "xc7a100tcsg324-1"},
        "seed": f"0x{SEED:08X}",
        "transactions_requested": args.transactions,
        "transactions_compared": compared,
        "compared_fields": ["d1", "dH"],
        "learning_enabled": True,
        "first_divergence": first_div,
        "verdict": "PASS" if ok else "DIVERGENCE",
        "why_it_matters": "every 10k/100k horizon conclusion in this program is "
                          "twin evidence; the twin was previously validated only "
                          "against a 32-step ladder",
        "seconds": round(time.time() - t0, 1),
        "ts": datetime.now(timezone.utc).isoformat(),
    }
    dst = ROOT / args.out
    dst.mkdir(parents=True, exist_ok=True)
    p = dst / "twin_board_equiv.json"
    p.write_text(json.dumps(rec, indent=2), encoding="utf-8")
    print(p)
    return 0 if ok else 1


if __name__ == "__main__":
    raise SystemExit(main())
