#!/usr/bin/env python3
"""Freeze A-FAST pack Python oracle BEFORE XSim. PROGRAM=NO.

Do not write 664 as patched acceptance. Independent forward on exact pack.
"""
from __future__ import annotations

import hashlib
import json
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[4]
sys.path.insert(0, str(ROOT))

from python.ref.a7lm06_fixed_ref import TinyGPT803k, LAW_ID, WMEM_WORDS

BAG = Path(__file__).resolve().parent
HEX = ROOT / "tests" / "xsim" / "a7lm06_wmem.hex"
REF = ROOT / "python" / "ref" / "a7lm06_fixed_ref.py"
WMEM_LOCK = "C204E55909D99370387C479C74E28C15F285FDDEE20239459D7C0EC3373001E0"
REF_LOCK = "05FACAF42AE4A7EBA00D1F3377A8223ACD0B70A4153AC335D7F80C78E8EEA870"
CORE_NEW_LOCK = "75706E2C804C4044CF7A76638978A617A83DE0D4E7D5A37EF703C974E8EFB5FB"
CORE_OLD_LOCK = "29D230FCC23247F49DD58E081607314C1CC4F8C8B4ECBD422E2FA75412290C9E"
PACK = 0x3B392B291B190B09
TOKENS = [9, 11, 25, 27, 41, 43, 57, 59]


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
    wsha = hashlib.sha256(HEX.read_bytes()).hexdigest().upper()
    rsha = hashlib.sha256(REF.read_bytes()).hexdigest().upper()
    newsha = hashlib.sha256((ROOT / "rtl" / "lm" / "tiny_gpt803k_core.sv").read_bytes()).hexdigest().upper()
    oldsha = hashlib.sha256((BAG / "tiny_gpt803k_core_OLD.sv").read_bytes()).hexdigest().upper()
    if wsha != WMEM_LOCK:
        print("STOP_FAIL wmem", wsha)
        return 2
    if rsha != REF_LOCK:
        print("STOP_FAIL pyref", rsha)
        return 3
    if newsha != CORE_NEW_LOCK:
        print("STOP_FAIL core_new", newsha)
        return 4
    if oldsha != CORE_OLD_LOCK:
        print("STOP_FAIL core_old", oldsha)
        return 5
    blob = load_hex(HEX)
    if len(blob) != WMEM_WORDS:
        print("STOP_FAIL wmem_len", len(blob))
        return 6
    got = [(PACK >> (8 * i)) & 0xFF for i in range(8)]
    if got != TOKENS:
        print("STOP_FAIL pack tokens", got)
        return 7
    m = TinyGPT803k(0)
    m.load_flat(blob)
    z1, p1 = m.forward([1])
    z, p = m.forward(TOKENS)
    logit0 = int(z[0])
    rec = f"AFAST|{TOKENS}|pack={PACK:016x}|wmem={wsha}|law={LAW_ID}|pred={int(p)}|logit0={logit0}"
    qsha = hashlib.sha256(rec.encode("utf-8")).hexdigest().upper()
    print(f"SANITY token[1] pred={p1} logit0={int(z1[0])}")
    print(f"ORACLE pack={PACK:016x} tokens={TOKENS} pred={int(p)} logit0={logit0}")
    if int(p1) != 744 or int(z1[0]) != -1090663:
        print("STOP_FAIL sanity", p1, int(z1[0]))
        return 8
    payload = {
        "gate": "LN-FIX-AFAST-REGRESSION-00",
        "PROGRAM": "NO",
        "historical_pred_old_core": 664,
        "historical_old_core_sha256": CORE_OLD_LOCK,
        "patched_core_sha256": CORE_NEW_LOCK,
        "wmem_sha256": wsha,
        "python_ref_sha256": rsha,
        "law_id": LAW_ID,
        "ctx_idx": 0,
        "ctx_n": 8,
        "ctx_pack_hex": f"{PACK:016x}",
        "tokens": TOKENS,
        "sanity_token1_pred": int(p1),
        "sanity_token1_logit0": int(z1[0]),
        "python_pred": int(p),
        "python_logit0": logit0,
        "oracle_rec_sha256": qsha,
        "do_not_hardcode_664_as_patched_acceptance": True,
        "historical_afast_wmem_cite": "9A6BBC7AC8AF82725CAFD0B50241EE683C07FB9943C754753025F3569967D10F",
    }
    (BAG / "ORACLE.json").write_text(json.dumps(payload, indent=2) + "\n", encoding="utf-8")
    svh = "\n".join(
        [
            "// Frozen BEFORE A/B XSim. Do not edit after run.",
            f"// wmem={wsha}",
            f"// pyref={rsha}",
            f"// rec={qsha}",
            "localparam int ORACLE_CTRL_PRED = 744;",
            "localparam int ORACLE_CTRL_LOGIT0 = -1090663;",
            f"localparam int ORACLE_UNIT_PRED = {int(p)};",
            f"localparam int ORACLE_UNIT_LOGIT0 = {logit0};",
            "localparam [63:0] PACK_AFAST = 64'h3b392b291b190b09;",
            "localparam [6:0] CTX_N = 7'd8;",
            "localparam int HISTORICAL_PRED = 664;",
            "",
        ]
    )
    (BAG / "afast_oracle.svh").write_text(svh, encoding="utf-8")
    print("WROTE", BAG / "ORACLE.json")
    print("WROTE", BAG / "afast_oracle.svh")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
