#!/usr/bin/env python3
"""Freeze TinyGPT OUT for actual C9 graph packs. Run AFTER graph XSim, BEFORE any LM compare.

Do not edit ORACLE.json after an LM run. Do not use G5 549/861/237. Do not use 733.
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
EXPECTED = ROOT / "tests" / "xsim" / "a7lm06_expected.txt"

# From C9_LEARNED_PRIOR_GRAPH_XSIM_PASS unit_xsim.log (graph minheap, not persist FAST IDs).
PACKS = {
    "HOLD_A": 0x8382238122802120,
    "UNREL": 0x8786858483828180,
    "CONTRA": 0x2322832182208180,
    "HOLD_B": 0x8382438142804140,
}


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
    if not HEX.is_file():
        print("STOP_FAIL missing", HEX)
        return 2
    blob = load_hex(HEX)
    if len(blob) != WMEM_WORDS:
        print(f"STOP_FAIL wmem_len={len(blob)} want={WMEM_WORDS}")
        return 3
    wmem_sha = hashlib.sha256(HEX.read_bytes()).hexdigest().upper()
    exp_pred = int(EXPECTED.read_text(encoding="utf-8").splitlines()[0])
    m = TinyGPT803k(0)
    m.load_flat(blob)
    _z, pred1 = m.forward([1])
    print(f"SANITY token[1] pred={pred1} golden={exp_pred} law={LAW_ID}")
    if pred1 != exp_pred:
        print("STOP_FAIL frozen-ref does not reproduce LM-06 golden pred")
        return 4
    queries = []
    for tag, pack in PACKS.items():
        toks = tokens_from_pack(pack)
        _z, pred = m.forward(toks)
        rec = f"{tag}|tokens={toks}|pack={pack:016x}|wmem={wmem_sha}|law={LAW_ID}"
        qsha = hashlib.sha256(rec.encode("utf-8")).hexdigest().upper()
        queries.append(
            {
                "tag": tag,
                "tokens": toks,
                "ctx_pack_hex": f"{pack:016x}",
                "query_sha256": qsha,
                "oracle_out": int(pred),
            }
        )
        print(f"ORACLE {tag} pack={pack:016x} toks={toks} OUT={pred}")
    out = {
        "gate": "P2-GATE14-C9-LEARNED-PRIOR-GRAPH-03",
        "source": "actual C9 graph minheap packs from XSim PASS",
        "not_g5_fast_ids": True,
        "not_out_733": True,
        "wmem_sha256": wmem_sha,
        "law_id": LAW_ID,
        "queries": queries,
    }
    path = BAG / "ORACLE.json"
    if path.is_file():
        print("STOP_FAIL ORACLE.json already exists; will not retarget")
        return 5
    path.write_text(json.dumps(out, indent=2) + "\n", encoding="utf-8")
    print("ORACLE_SHA", hashlib.sha256(path.read_bytes()).hexdigest().upper())
    print("ORACLE_FROZEN")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
