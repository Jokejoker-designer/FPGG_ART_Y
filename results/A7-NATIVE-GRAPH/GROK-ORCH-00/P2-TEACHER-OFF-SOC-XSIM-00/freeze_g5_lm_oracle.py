#!/usr/bin/env python3
"""Freeze independent LM-06 frozen-ref OUT for G5 exam queries.

Must run BEFORE XSim rerun. Do not edit ORACLE.json after the XSim that
consumes it. PROGRAM=NO. Host is not the exam answer path.
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

# Persist packs measured on frozen G4 SHA D1BF0340… (same instance this gate).
# Byte0 = rank-1 low-8 = ctx token 0. Do not invent a second pack.
PACKS = {
    "HOLD_A": 0x0706050403010002,
    "UNREL": 0x0F0E0D0C0B0A0908,
    "CONTRA": 0x0706050403010002,  # Fast map_q(A4)=qid 2; same persist slot as HOLD_A
    "HOLD_B": 0x0F0E0D0C090B080A,
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
    z1, pred1 = m.forward([1])
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
        print(f"ORACLE {tag} pack={pack:016x} tokens={toks} OUT={pred} SHA={qsha[:16]}…")

    payload = {
        "gate": "P2-TEACHER-OFF-SOC-XSIM-00",
        "classification_prior": "PASS_NARROW_FRAMING / FAIL_LM_KNOWNNESS",
        "PROGRAM": "NO",
        "TEACHER_OFF": "not_claimed",
        "law_id": LAW_ID,
        "wmem_path": "tests/xsim/a7lm06_wmem.hex",
        "wmem_sha256": wmem_sha,
        "wmem_words": WMEM_WORDS,
        "sanity_token1_pred": int(pred1),
        "sanity_golden_pred": int(exp_pred),
        "queries": queries,
    }
    out_json = BAG / "ORACLE.json"
    out_json.write_text(json.dumps(payload, indent=2) + "\n", encoding="utf-8")

    svh = BAG / "g5_lm_oracle.svh"
    lines = [
        "// AUTO-FROZEN by freeze_g5_lm_oracle.py BEFORE XSim. Do not edit after run.",
        f"// wmem_sha={wmem_sha}",
        f"// sanity_token1_pred={pred1}",
    ]
    for q in queries:
        lines.append(f"localparam [9:0] ORACLE_{q['tag']} = 10'd{q['oracle_out']};")
        lines.append(f"localparam [63:0] PACK_{q['tag']} = 64'h{q['ctx_pack_hex']};")
    svh.write_text("\n".join(lines) + "\n", encoding="utf-8")
    print("WROTE", out_json)
    print("WROTE", svh)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
