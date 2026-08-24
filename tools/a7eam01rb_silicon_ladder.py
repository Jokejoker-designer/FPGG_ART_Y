"""A7-EAM-01R-B randomized silicon ladder.

Closes the multi-index *router* on board. Host sends key/vec/tok only.
Oracle is exhaustive Hamming NN over stored keys — not the 00G set-index twin.
Keys are drawn far (pairwise d>=24) so MARGIN_MIN=4 cannot reject an exact unique hit.
"""
from __future__ import annotations

import hashlib
import json
import secrets
import sys
import time
from datetime import datetime, timezone
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT))

import serial  # noqa: E402

BIT = ROOT / "build" / "out" / "arty_a7_eam01r.bit"
OUT = ROOT / "results" / "A7-EAM-01R" / "ladder_01rb.json"
PORT = "COM12"
BAUD = 115200
RLEN = 20
NMAP = 32
PAIR_MIN = 24
HIT_MAX = 8
MARGIN = 4

FROZEN = {
    "arty_a7_lm00.bit": "449A330BD2E23E1D9714ECF94142A0555914D6C76EDE6310EF347A3596534783",
    "arty_a7_lm05.bit": "1AA0B5C481B0ADF3CAA599F081B430AF3C28A26FB4715DC56A0D25D940548F51",
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


def pop64(x: int) -> int:
    return int(x & ((1 << 64) - 1)).bit_count()


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


def qv(key: int, vec: int = 0, tok: int = 0) -> bytes:
    return key.to_bytes(8, "little") + vec.to_bytes(16, "little") + bytes([tok & 0xFF])


def parse(rep: bytes) -> dict:
    if len(rep) != RLEN or rep[0] != 0x5A or xor_bytes(rep[:19]) != rep[19]:
        raise RuntimeError(f"bad reply {rep.hex()}")
    return {
        "kind": rep[1],
        "hit": bool(rep[2] & 1),
        "token": rep[3],
        "best": rep[4],
        "second": rep[5],
        "hit_cnt": int.from_bytes(rep[6:10], "little"),
        "miss_cnt": int.from_bytes(rep[10:14], "little"),
        "ovf": rep[17],
    }


def far_keys(n: int, rng: secrets.SystemRandom, mind: int) -> list[int]:
    keys: list[int] = []
    guard = 0
    while len(keys) < n:
        k = rng.getrandbits(64)
        if all(pop64(k ^ e) >= mind for e in keys):
            keys.append(k)
        guard += 1
        if guard > 100000:
            raise RuntimeError("unable to sample far keys")
    return keys


class Oracle:
    def __init__(self) -> None:
        self.rows: list[tuple[int, int]] = []

    def map(self, key: int, tok: int) -> None:
        self.rows.append((key, tok))

    def probe(self, q: int) -> dict:
        if not self.rows:
            return {"best": 64, "second": 64, "token": 0}
        ds = sorted((pop64(q ^ k), t) for k, t in self.rows)
        best, tok = ds[0]
        second = ds[1][0] if len(ds) > 1 else 64
        return {"best": best, "second": second, "token": tok}


class Link:
    def __init__(self, port: str) -> None:
        self.ser = serial.Serial(port, BAUD, timeout=0.05)
        time.sleep(0.4)
        self.ser.reset_input_buffer()

    def close(self) -> None:
        self.ser.close()

    def xact(self, cmd: int, payload: bytes = b"", timeout: float = 8.0) -> dict:
        self.ser.reset_input_buffer()
        self.ser.write(pack(cmd, payload))
        self.ser.flush()
        buf = bytearray()
        deadline = time.monotonic() + timeout
        while time.monotonic() < deadline and len(buf) < RLEN:
            chunk = self.ser.read(RLEN - len(buf))
            if chunk:
                buf.extend(chunk)
        if len(buf) != RLEN:
            raise TimeoutError(f"short reply {buf.hex()} cmd={cmd:#x}")
        return parse(bytes(buf))


def frozen_ok() -> dict:
    rows = {}
    for name, exp in FROZEN.items():
        path = ROOT / "build" / "out" / name
        if not path.exists():
            rows[name] = {"ok": False, "reason": "missing"}
            continue
        got = sha256(path)
        rows[name] = {"ok": got == exp, "got": got}
    return rows


def main() -> int:
    if "lm" in BIT.name:
        print("REFUSE lm-named bit")
        return 2
    frozen = frozen_ok()
    if not all(r["ok"] for r in frozen.values()):
        print("FROZEN_FAIL", json.dumps(frozen, indent=2))
        return 3
    bit_sha = sha256(BIT)
    rng = secrets.SystemRandom()
    keys = far_keys(NMAP, rng, PAIR_MIN)
    toks = [rng.randrange(1, 255) for _ in range(NMAP)]
    vecs = [rng.getrandbits(128) for _ in range(NMAP)]
    ora = Oracle()
    steps: dict = {}
    disagree = 0
    probes = 0

    link = Link(PORT)
    try:
        pong = link.xact(0x01)
        steps["ping_r1r"] = pong["kind"] == 0x81 and pong["token"] == 0x52
        steps["clr"] = link.xact(0x05)["kind"] == 0x83
        steps["hmax8"] = link.xact(0x07, bytes([HIT_MAX]))["kind"] == 0x83
        steps["marg4"] = link.xact(0x08, bytes([MARGIN]))["kind"] == 0x83

        nmiss = 0
        for i in range(NMAP):
            r = link.xact(0x02, qv(keys[i], vecs[i], toks[i]))
            ora.map(keys[i], toks[i])
            if r["kind"] == 0x82 and not r["hit"]:
                nmiss += 1
        steps["map_miss_n"] = nmiss == NMAP

        nhit = ntok = nd0 = 0
        for i in range(NMAP):
            r = link.xact(0x03, qv(keys[i]))
            tw = ora.probe(keys[i])
            probes += 1
            # Inside the MIH ball (exhaustive d<=8) FPGA must match NN.
            if tw["best"] <= HIT_MAX and r["best"] != tw["best"]:
                disagree += 1
            if r["hit"]:
                nhit += 1
            if r["token"] == toks[i]:
                ntok += 1
            if r["best"] == 0:
                nd0 += 1
        steps["exact_hit_n"] = nhit == NMAP
        steps["exact_token_n"] = ntok == NMAP
        steps["exact_d0_n"] = nd0 == NMAP

        def check_case(name: str, flip: int, expect_hit: bool, expect_d: int | None) -> None:
            nonlocal disagree, probes
            ok = 0
            sample = min(16, NMAP)
            for i in range(sample):
                q = keys[i] ^ flip
                r = link.xact(0x03, qv(q))
                tw = ora.probe(q)
                probes += 1
                if tw["best"] <= HIT_MAX and r["best"] != tw["best"]:
                    disagree += 1
                if expect_hit:
                    if r["hit"] and r["token"] == toks[i] and r["best"] == expect_d:
                        ok += 1
                else:
                    # Outside radius-1 FPGA may report 64; reject is the gate.
                    if not r["hit"]:
                        ok += 1
            steps[name] = ok == sample
            steps[name + "_n"] = ok

        check_case("set_1flip", 0x1, True, 1)
        check_case("eight_in_one_byte", 0xFF, True, 8)
        check_case("theorem_1_per_byte", 0x0101010101010101, True, 8)
        check_case("d16_reject", 0x0303030303030303, False, 16)

        uok = 0
        ufp = 0
        for _ in range(NMAP):
            u = rng.getrandbits(64)
            while any(pop64(u ^ k) <= HIT_MAX for k in keys):
                u = rng.getrandbits(64)
            r = link.xact(0x03, qv(u))
            tw = ora.probe(u)
            probes += 1
            if tw["best"] <= HIT_MAX and r["best"] != tw["best"]:
                disagree += 1
            if r["hit"]:
                ufp += 1
            else:
                uok += 1
        steps["unrelated_reject"] = uok == NMAP and ufp == 0
        steps["unrelated_n"] = uok
        steps["unrelated_fp"] = ufp
        steps["oracle_disagree_in_ball"] = disagree
        steps["oracle_agree_in_ball"] = disagree == 0
        st = link.xact(0x06)
        steps["ovf_zero"] = st["ovf"] == 0
        steps["stat_kind"] = st["kind"] == 0x83
    finally:
        link.close()

    skip = ("_n", "_fp")
    all_ok = all(
        bool(v)
        for k, v in steps.items()
        if not k.endswith(skip) and k != "oracle_disagree_in_ball"
    )
    doc = {
        "candidate": "01r-b",
        "law": "eam01r-mih-v1",
        "bit": "build/out/arty_a7_eam01r.bit",
        "bit_sha256": bit_sha,
        "port": PORT,
        "n": NMAP,
        "pair_min": PAIR_MIN,
        "hit_max": HIT_MAX,
        "margin_min": MARGIN,
        "probes": probes,
        "oracle": "exhaustive Hamming NN on stored keys",
        "host_must_not_send": ["way", "bram_addr", "precomputed_match"],
        "frozen": frozen,
        "steps": steps,
        "pass": all_ok,
        "utc": datetime.now(timezone.utc).isoformat(),
    }
    OUT.parent.mkdir(parents=True, exist_ok=True)
    OUT.write_text(json.dumps(doc, indent=2), encoding="utf-8")
    print(json.dumps(doc, indent=2))
    print("A7EAM01RB_PASS" if all_ok else "A7EAM01RB_FAIL")
    return 0 if all_ok else 5


if __name__ == "__main__":
    raise SystemExit(main())
