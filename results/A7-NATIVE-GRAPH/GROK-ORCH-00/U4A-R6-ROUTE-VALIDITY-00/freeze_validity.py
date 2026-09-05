#!/usr/bin/env python3
"""U4A-R6: replay 98 frozen U3Q-R3 vectors. Keys MUST match. Add validity goldens.

Does not rewrite qse key values. Does not rewrite FROZEN_VECTORS.json.
"""
from __future__ import annotations

import json
import sys
from pathlib import Path

BAG = Path(__file__).resolve().parent
BAG_U3Q = BAG.parent / "U3Q-R3-STRUCTURED-QUERY-FEATURE-00"
sys.path.insert(0, str(BAG_U3Q))
from twin import extract_bytes  # noqa: E402

KEY_FIELDS = (
    "entity_id", "intent_id", "relation_id", "context_id",
    "entity_cue", "intent_cue", "relation_cue", "context_cue",
    "crc16_dbg", "k0", "k1", "k2", "k3",
)


def main() -> int:
    frozen = json.loads((BAG_U3Q / "FROZEN_VECTORS.json").read_text(encoding="utf-8"))
    rows = frozen["vectors"]
    n = len(rows)
    mismatches = []
    out_rows = []
    for r in rows:
        raw = list(bytes.fromhex(r["raw_hex"]))
        g = extract_bytes(raw)
        old = r["golden"]
        bad = {k: {"old": old[k], "new": g[k]} for k in KEY_FIELDS if int(old[k]) != int(g[k])}
        if int(g.get("n_host", 0)) != 0:
            bad["n_host"] = {"old": 0, "new": g["n_host"]}
        rec = {
            "id": r["id"],
            "section": r["section"],
            "label": r["label"],
            "text": r["text"],
            "raw_hex": r["raw_hex"],
            "k0": g["k0"], "k1": g["k1"], "k2": g["k2"], "k3": g["k3"],
            "v0": g["k0_valid"], "v1": g["k1_valid"], "v2": g["k2_valid"], "v3": g["k3_valid"],
            "entity_bind": g["entity_bind"], "intent_bind": g["intent_bind"],
            "relation_bind": g["relation_bind"], "context_bind": g["context_bind"],
            "n_host": 0,
            "valid_eq_key_neq_zero": bool(
                (g["k0_valid"] == (1 if g["k0"] != 0 else 0))
                and (g["k1_valid"] == (1 if g["k1"] != 0 else 0))
                and (g["k2_valid"] == (1 if g["k2"] != 0 else 0))
                and (g["k3_valid"] == (1 if g["k3"] != 0 else 0))
            ),
            "key_match": not bad,
        }
        if bad:
            rec["mismatch"] = bad
            mismatches.append(rec)
        out_rows.append(rec)

    # Independent-of-key proof on frozen set: any (valid,key) pair that is not
    # (1,nonzero) or (0,zero) demonstrates the objects are distinct. The
    # protocol test injects valid=1,key=0 separately; here we record whether
    # the frozen corpus itself contains that pair.
    v1k0 = []
    v0knz = []
    for rec in out_rows:
        for t, v, k in (
            (0, rec["v0"], rec["k0"]),
            (1, rec["v1"], rec["k1"]),
            (2, rec["v2"], rec["k2"]),
            (3, rec["v3"], rec["k3"]),
        ):
            if v == 1 and k == 0:
                v1k0.append({"id": rec["id"], "table": t})
            if v == 0 and k != 0:
                v0knz.append({"id": rec["id"], "table": t, "key": k})

    blob = {
        "gate": "U4A-R6-ROUTE-VALIDITY-00",
        "law": "qse-v1-lexicon-hdc-00",
        "n": n,
        "key_match": n - len(mismatches),
        "key_mismatch": len(mismatches),
        "host_semantic_nonzero": 0,
        "frozen_valid1_key0": v1k0,
        "frozen_valid0_key_nonzero": v0knz,
        "note": "valid=(key!=0) is not the law; protocol test injects valid=1,key=0",
        "vectors": out_rows,
        "mismatches": mismatches,
    }
    (BAG / "VALIDITY_GOLDEN.json").write_text(json.dumps(blob, indent=2), encoding="utf-8")

    lines = [
        "// U4A-R6 validity goldens. Keys live in U3Q-R3 frozen_vectors.svh.",
        f"localparam int unsigned NVEC_V = {n};",
        "localparam logic G_V0 [0:NVEC_V-1] = '{" + ",".join(str(r["v0"]) for r in out_rows) + "};",
        "localparam logic G_V1 [0:NVEC_V-1] = '{" + ",".join(str(r["v1"]) for r in out_rows) + "};",
        "localparam logic G_V2 [0:NVEC_V-1] = '{" + ",".join(str(r["v2"]) for r in out_rows) + "};",
        "localparam logic G_V3 [0:NVEC_V-1] = '{" + ",".join(str(r["v3"]) for r in out_rows) + "};",
        "",
    ]
    (BAG / "frozen_validity.svh").write_text("\n".join(lines), encoding="utf-8")

    print("FROZEN_N", n)
    print("KEY_MATCH", n - len(mismatches), "/", n)
    print("FROZEN_VALID1_KEY0", len(v1k0))
    print("FROZEN_VALID0_KEY_NZ", len(v0knz))
    if mismatches:
        print("FIRST_DIVERGENCE", mismatches[0]["id"], mismatches[0].get("mismatch"))
        print("U4A_R6_KEY_MISMATCH")
        return 6
    print("U4A_R6_KEY_MATCH_98")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
