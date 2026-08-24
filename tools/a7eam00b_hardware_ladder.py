"""A7-EAM-00B silicon ladder. Host sends key/vec/token/cmd only."""
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

BIT = ROOT / "build" / "out" / "arty_a7_eam00b.bit"
OUT = ROOT / "results" / "A7-EAM-00" / "ladder_00b.json"
PORT = "COM12"
BAUD = 115200
NMAP = 48
SET = 0xA5
RLEN = 20

FROZEN = {
    "arty_a7_lm00.bit": "449A330BD2E23E1D9714ECF94142A0555914D6C76EDE6310EF347A3596534783",
    "arty_a7_lm01.bit": "96065A174F22B6F79B6A04B79EBA4DDEF094B2BFAF36F5C93F0C376C679507B8",
    "arty_a7_lm02.bit": "7CEBA854BDE500DDC87C4742315C45562CB5902C6F66377BCE499DA43BD95CC4",
    "arty_a7_lm03.bit": "C98B7C85814C8D4C57CA5E4ED1C9C411BC71EBF2991ABA1B210B9347509F23D1",
    "arty_a7_lm04r5.bit": "A177E0989956DF08C7150E451984C914E1D53B1FCF96A49EBEC68CE8497A55F8",
    "arty_a7_lm05.bit": "1AA0B5C481B0ADF3CAA599F081B430AF3C28A26FB4715DC56A0D25D940548F51",
    "arty_a7_lm06.bit": "67C37DD51AED30F82B5B72EC9EF0736DDABA534ED1D724D0ADCAFD2B4282E3BA",
    "arty_a7_lm06c3.bit": "222F804351261B5878D73E5501E4E34A28D330B09BB4BC3E1590EE79402884C6",
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
    if cmd in (0x02, 0x03) and len(payload) != 25:
        raise ValueError("MAP/PROBE payload must be 25 bytes (key+vec+tok)")
    if any(k in payload for k in (b"WAY", b"BRAM")):
        raise ValueError("forbidden field in payload")
    head = bytes([0xA5, cmd & 0xFF, len(payload) & 0xFF]) + payload
    return head + bytes([xor_bytes(head)])


def qv(key: int, vec: int, tok: int) -> bytes:
    return key.to_bytes(8, "little") + vec.to_bytes(16, "little") + bytes([tok & 0xFF])


def parse(rep: bytes) -> dict:
    if len(rep) != RLEN or rep[0] != 0x5A or xor_bytes(rep[:19]) != rep[19]:
        raise RuntimeError(f"bad reply {rep.hex()}")
    return {
        "kind": rep[1],
        "hit": bool(rep[2] & 1),
        "result": bool(rep[2] & 2),
        "token": rep[3],
        "hamming": rep[4],
        "cycles": rep[5],
        "hit_cnt": int.from_bytes(rep[6:10], "little"),
        "miss_cnt": int.from_bytes(rep[10:14], "little"),
        "qry_cnt": int.from_bytes(rep[14:18], "little"),
        "epoch": rep[18],
    }


class Link:
    def __init__(self, port: str):
        self.ser = serial.Serial(port, BAUD, timeout=0.05)
        time.sleep(0.2)
        self.ser.reset_input_buffer()

    def close(self) -> None:
        self.ser.close()

    def xact(self, cmd: int, payload: bytes = b"", timeout: float = 2.0) -> dict:
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
        rows[name] = {"ok": got == exp, "got": got, "exp": exp}
    return rows


def main() -> int:
    if BIT.name.startswith("arty_a7_lm"):
        print("REFUSE: EAM bit name collides with LM")
        return 2
    frozen = frozen_ok()
    if not all(r["ok"] for r in frozen.values()):
        print("FROZEN_FAIL", json.dumps(frozen, indent=2))
        return 3
    bit_sha = sha256(BIT) if BIT.exists() else ""
    # Mappings AFTER bitstream identity is known.
    rng = secrets.SystemRandom()
    keys = [rng.getrandbits(64) for _ in range(NMAP)]
    vecs = [rng.getrandbits(128) for _ in range(NMAP)]
    toks = [rng.randrange(1, 255) for _ in range(NMAP)]

    link = Link(PORT)
    steps: dict = {}
    try:
        pong = link.xact(0x01)
        steps["ping"] = pong["kind"] == 0x81 and pong["token"] == 0x45
        clr = link.xact(0x05)
        steps["clr"] = clr["kind"] == 0x83 and clr["hit_cnt"] == 0 and clr["miss_cnt"] == 0

        nmiss = 0
        for i in range(NMAP):
            r = link.xact(0x02, qv(keys[i], vecs[i], toks[i]))
            if r["kind"] == 0x82 and not r["hit"]:
                nmiss += 1
        steps["first_miss_48"] = nmiss == NMAP

        nhit = 0
        ntok = 0
        nd0 = 0
        for i in range(NMAP):
            r = link.xact(0x03, qv(keys[i], 0, 0))
            if r["kind"] == 0x82 and r["hit"]:
                nhit += 1
            if r["token"] == toks[i]:
                ntok += 1
            if r["hamming"] == 0:
                nd0 += 1
        steps["second_hit_48"] = nhit == NMAP
        steps["probe_dummy_teacher_token"] = ntok == NMAP
        steps["hamming_zero"] = nd0 == NMAP

        used_sets = {k & 0xFF for k in keys}
        ev_set = SET
        if ev_set in used_sets:
            ev_set = next(s for s in range(256) if s not in used_sets)
        ev_keys = [((rng.getrandbits(56) << 8) | ev_set) for _ in range(17)]
        ev_toks = [rng.randrange(1, 255) for _ in range(17)]
        ev_vecs = [rng.getrandbits(128) for _ in range(17)]
        ev_miss = 0
        for i in range(16):
            r = link.xact(0x02, qv(ev_keys[i], ev_vecs[i], ev_toks[i]))
            if not r["hit"]:
                ev_miss += 1
        r17 = link.xact(0x02, qv(ev_keys[16], ev_vecs[16], ev_toks[16]))
        steps["evict_fill16_miss"] = ev_miss == 16
        steps["evict_17th_miss"] = (not r17["hit"])

        hits = 0
        miss_idx = []
        for i in range(17):
            r = link.xact(0x03, qv(ev_keys[i], 0, 0))
            if r["hit"] and r["token"] == ev_toks[i] and r["hamming"] == 0:
                hits += 1
            else:
                miss_idx.append(i)
        steps["evict_16_survive"] = hits == 16
        steps["evict_17th_recall"] = 16 not in miss_idx
        steps["evict_one_original_gone"] = len(miss_idx) == 1 and miss_idx[0] < 16

        survivors = [i for i in range(16) if i not in miss_idx]
        disc_ok = True
        for i in survivors:
            r = link.xact(0x03, qv(ev_keys[i], 0, 0))
            if not (r["hit"] and r["token"] == ev_toks[i]):
                disc_ok = False
        rnew = link.xact(0x03, qv(ev_keys[16], 0, 0))
        steps["teacher_disconnect_recall"] = disc_ok and rnew["hit"] and rnew["token"] == ev_toks[16]

        soft = link.xact(0x04)
        steps["soft_ack"] = soft["kind"] == 0x83
        old_miss = True
        for i in survivors[:4]:
            r = link.xact(0x03, qv(ev_keys[i], 0, 0))
            if r["hit"]:
                old_miss = False
        r_old48 = link.xact(0x03, qv(keys[0], 0, 0))
        steps["soft_old_unavailable"] = old_miss and (not r_old48["hit"])

        nk, nv, nt = rng.getrandbits(64), rng.getrandbits(128), rng.randrange(1, 255)
        r_teach = link.xact(0x02, qv(nk, nv, nt))
        r_new = link.xact(0x03, qv(nk, 0, 0))
        r_old = link.xact(0x03, qv(keys[1], 0, 0))
        steps["new_map_miss"] = not r_teach["hit"]
        steps["new_map_recall"] = r_new["hit"] and r_new["token"] == nt and r_new["hamming"] == 0
        steps["old_still_gone"] = not r_old["hit"]
    finally:
        link.close()

    all_ok = all(bool(v) for v in steps.values())
    doc = {
        "candidate": "00b",
        "bit": str(BIT.relative_to(ROOT)).replace("\\", "/"),
        "bit_sha256": bit_sha,
        "port": PORT,
        "baud": BAUD,
        "maps_generated_after_bit_sha": True,
        "host_sends": ["key", "context_vec", "context_token", "command"],
        "host_must_not_send": ["way", "bram_addr", "evict_decision", "precomputed_match"],
        "frozen": frozen,
        "steps": steps,
        "pass": all_ok,
        "utc": datetime.now(timezone.utc).isoformat(),
    }
    OUT.parent.mkdir(parents=True, exist_ok=True)
    OUT.write_text(json.dumps(doc, indent=2), encoding="utf-8")
    print(json.dumps(doc, indent=2))
    print("A7_EAM00B_LADDER_PASS" if all_ok else "A7_EAM00B_LADDER_FAIL")
    return 0 if all_ok else 5


if __name__ == "__main__":
    raise SystemExit(main())
