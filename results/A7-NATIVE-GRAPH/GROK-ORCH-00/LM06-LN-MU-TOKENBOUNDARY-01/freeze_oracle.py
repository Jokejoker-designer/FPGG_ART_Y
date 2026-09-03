#!/usr/bin/env python3
"""Per-token LN oracle (sum, mu, var, scale, n1) frozen BEFORE XSim."""
from __future__ import annotations

import hashlib
import json
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[4]
sys.path.insert(0, str(ROOT))

from python.lm.tiny_gpt_ref import layernorm_stats
from python.ref.a7lm06_fixed_ref import TinyGPT803k, WMEM_WORDS, LAW_ID

BAG = Path(__file__).resolve().parent
HEX = ROOT / "tests" / "xsim" / "a7lm06_wmem.hex"
WMEM_SHA_LOCK = "C204E55909D99370387C479C74E28C15F285FDDEE20239459D7C0EC3373001E0"
UNIT = [2, 0, 1, 3, 4, 5, 6, 7]
D = 128


def load_hex(path: Path) -> list[int]:
    blob = []
    for line in path.read_text(encoding="utf-8").splitlines():
        s = line.strip()
        if not s:
            continue
        b = int(s, 16) & 0xFF
        blob.append(b - 256 if b >= 128 else b)
    return blob


def main() -> int:
    wmem_sha = hashlib.sha256(HEX.read_bytes()).hexdigest().upper()
    if wmem_sha != WMEM_SHA_LOCK:
        print("STOP_FAIL wmem", wmem_sha)
        return 2
    m = TinyGPT803k(0)
    m.load_flat(load_hex(HEX))
    z1, p1 = m.forward([1])
    if p1 != 744:
        print("STOP_FAIL control", p1)
        return 3
    emb = m.embed(UNIT)
    z8, p8 = m.forward(UNIT)
    toks = []
    for t, x in enumerate(emb):
        n1, mu, scale = layernorm_stats(x)
        s = int(sum(x))
        var = int(sum((v - mu) * (v - mu) for v in x) // D)
        toks.append(
            {
                "tok": t,
                "sum": s,
                "mu": int(mu),
                "var": var,
                "scale": int(scale),
                "n1_0": int(n1[0]),
                "emb_0": int(x[0]),
            }
        )
        print(
            f"TOK{t} sum={s} mu={mu} var={var} scale={scale} emb0={x[0]} n1_0={n1[0]}"
        )
    payload = {
        "gate": "LM06-LN-MU-TOKENBOUNDARY-01",
        "law_id": LAW_ID,
        "wmem_sha256": wmem_sha,
        "control_pred": int(p1),
        "unit_pred": int(p8),
        "unit_logit0": int(z8[0]),
        "tokens": UNIT,
        "per_token": toks,
    }
    text = json.dumps(payload, indent=2) + "\n"
    (BAG / "ORACLE.json").write_text(text, encoding="utf-8")
    lines = [
        "// Frozen BEFORE XSim. Do not edit after run.",
        "localparam int ORACLE_CTRL_PRED = 744;",
        f"localparam int ORACLE_UNIT_PRED = {int(p8)};",
        f"localparam int ORACLE_UNIT_LOGIT0 = {int(z8[0])};",
        "localparam int signed ORACLE_SUM [0:7] = '{",
        "  " + ", ".join(str(t["sum"]) for t in toks) + "};",
        "localparam int signed ORACLE_MU [0:7] = '{",
        "  " + ", ".join(str(t["mu"]) for t in toks) + "};",
    ]
    (BAG / "ln_oracle.svh").write_text("\n".join(lines) + "\n", encoding="utf-8")
    print("UNIT pred", p8, "logit0", z8[0])
    print("WROTE", BAG / "ORACLE.json")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
