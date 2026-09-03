#!/usr/bin/env python3
"""Re-verify frozen G5 LM-06 oracle INTO this R1 bag. Do not overwrite G5.

Locked OUT: HOLD_A=549 UNREL=861 CONTRA=549 HOLD_B=237
WMEM SHA C204E559…  sanity forward([1])=744
PROGRAM=NO.
"""
from __future__ import annotations

import hashlib
import json
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[4]
sys.path.insert(0, str(ROOT))

from python.ref.a7lm06_fixed_ref import TinyGPT803k, WMEM_WORDS, LAW_ID

BAG = Path(__file__).resolve().parent
HEX = ROOT / "tests" / "xsim" / "a7lm06_wmem.hex"
WMEM_LOCK = "C204E55909D99370387C479C74E28C15F285FDDEE20239459D7C0EC3373001E0"
CORE_LOCK = "75706E2C804C4044CF7A76638978A617A83DE0D4E7D5A37EF703C974E8EFB5FB"
PACKS = {
    "HOLD_A": 0x0706050403010002,
    "UNREL": 0x0F0E0D0C0B0A0908,
    "CONTRA": 0x0706050403010002,
    "HOLD_B": 0x0F0E0D0C090B080A,
}
LOCKED_OUT = {"HOLD_A": 549, "UNREL": 861, "CONTRA": 549, "HOLD_B": 237}


def tokens_from_pack(pack: int) -> list[int]:
    return [(pack >> (8 * i)) & 0xFF for i in range(8)]


def load_hex(path: Path) -> list[int]:
    blob: list[int] = []
    for line in path.read_text(encoding="utf-8").splitlines():
        s = line.strip()
        if not s:
            continue
        b = int(s, 16) & 0xFF
        blob.append(b - 256 if b >= 128 else b)
    return blob


def main() -> int:
    wmem_sha = hashlib.sha256(HEX.read_bytes()).hexdigest().upper()
    if wmem_sha != WMEM_LOCK:
        print("STOP_FAIL wmem", wmem_sha)
        return 2
    core = ROOT / "rtl" / "lm" / "tiny_gpt803k_core.sv"
    core_sha = hashlib.sha256(core.read_bytes()).hexdigest().upper()
    if core_sha != CORE_LOCK:
        print("STOP_FAIL core", core_sha)
        return 3
    blob = load_hex(HEX)
    if len(blob) != WMEM_WORDS:
        print("STOP_FAIL wmem_len", len(blob))
        return 4
    m = TinyGPT803k(0)
    m.load_flat(blob)
    _z1, pred1 = m.forward([1])
    print(f"SANITY token[1] pred={pred1} law={LAW_ID}")
    if pred1 != 744:
        print("STOP_FAIL control", pred1)
        return 5
    queries = []
    for tag, pack in PACKS.items():
        toks = tokens_from_pack(pack)
        _z, pred = m.forward(toks)
        rec = f"{tag}|tokens={toks}|pack={pack:016x}|wmem={wmem_sha}|law={LAW_ID}"
        qsha = hashlib.sha256(rec.encode("utf-8")).hexdigest().upper()
        want = LOCKED_OUT[tag]
        print(f"ORACLE {tag} pack={pack:016x} tokens={toks} OUT={pred} lock={want}")
        if int(pred) != want:
            print("STOP_FAIL oracle drift", tag, pred, want)
            return 6
        queries.append(
            {
                "tag": tag,
                "tokens": toks,
                "ctx_pack_hex": f"{pack:016x}",
                "query_sha256": qsha,
                "oracle_out": int(pred),
            }
        )
    payload = {
        "gate": "P2-TEACHER-OFF-SOC-XSIM-R1-LNFIX-00",
        "parent": "P2-TEACHER-OFF-SOC-XSIM-00",
        "parent_verdict": "FAIL_LM_ORACLE_MISMATCH+FAIL_LM_KNOWNNESS",
        "PROGRAM": "NO",
        "TEACHER_OFF": "not_claimed",
        "law_id": LAW_ID,
        "wmem_path": "tests/xsim/a7lm06_wmem.hex",
        "wmem_sha256": wmem_sha,
        "wmem_words": WMEM_WORDS,
        "core_sha256": core_sha,
        "sanity_token1_pred": int(pred1),
        "queries": queries,
    }
    out_json = BAG / "ORACLE.json"
    out_json.write_text(json.dumps(payload, indent=2) + "\n", encoding="utf-8")
    print("WROTE", out_json)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
