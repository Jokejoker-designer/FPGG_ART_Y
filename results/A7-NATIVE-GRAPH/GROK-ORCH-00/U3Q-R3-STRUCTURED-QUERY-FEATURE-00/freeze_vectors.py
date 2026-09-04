#!/usr/bin/env python3
"""Freeze PREREG corpus + golden packets. Law qse-v1-lexicon-hdc-00 unchanged."""
from __future__ import annotations
import json
from pathlib import Path
from lexicon import (
    ENTITY_CANON, INTENT_CANON, SAME_ENT_DIFF_INT, UNRELATED,
    PERTURB_BASE, ADV_SEED, ADV_N, LAW,
)
from twin import extract_bytes

SEC = {
    "entity_paraphrase": 1,
    "intent_paraphrase": 2,
    "same_entity_diff_intent": 3,
    "unrelated": 4,
    "perturbation": 5,
    "adversarial": 6,
    "sentinel": 7,
}


def add(rows, section, label, raw: list[int], text: str):
    g = extract_bytes(raw)
    g["n_host_entity"] = 0
    g["n_host_hash"] = 0
    g["n_host_cand"] = 0
    g["n_host_winner"] = 0
    g["n_host_addr"] = 0
    g["n_host_answer"] = 0
    rows.append({
        "id": len(rows),
        "section": section,
        "section_id": SEC[section],
        "label": label,
        "text": text,
        "raw_hex": bytes(raw).hex(),
        "len": len(raw),
        "golden": g,
    })


def adv_texts():
    s = ADV_SEED
    texts = []
    for _ in range(ADV_N):
        ws = []
        for _w in range(2):
            chars = []
            for _k in range(5):
                s = (s * 1103515245 + 12345) & 0x7FFFFFFF
                chars.append(chr(ord("a") + (s % 26)))
            ws.append("".join(chars))
        texts.append(" ".join(ws))
    return texts


def build():
    rows = []
    for lab, forms in ENTITY_CANON.items():
        for s in forms:
            add(rows, "entity_paraphrase", lab, list(s.encode("ascii")), s)
    for lab, forms in INTENT_CANON.items():
        for s in forms:
            add(rows, "intent_paraphrase", lab, list(s.encode("ascii")), s)
    for s in SAME_ENT_DIFF_INT:
        add(rows, "same_entity_diff_intent", "chiller", list(s.encode("ascii")), s)
    for s in UNRELATED:
        add(rows, "unrelated", "unrelated", list(s.encode("ascii")), s)
    for s in PERTURB_BASE:
        t = list(s.encode("ascii"))
        t[-1] = (t[-1] + 1) & 0xFF
        if t[-1] == 0:
            t[-1] = 1
        add(rows, "perturbation", s, t, "pert:" + bytes(t).decode("latin1"))
    for s in adv_texts():
        add(rows, "adversarial", "adv", list(s.encode("ascii")), s)
    add(rows, "sentinel", "c34ff", [0xC3, 0x4F, 0xFF], "raw:C34FFF")
    add(rows, "sentinel", "ascii799999", list(b"799999"), "799999")
    return rows


def emit_svh(rows, path: Path):
    n = len(rows)
    def arr8(key, width=8):
        vals = ",".join(f"{width}'h{rows[i]['golden'][key]:0{width//4}x}" for i in range(n))
        return vals

    def pack_bytes(raw, nmax=48):
        v = 0
        for i, b in enumerate(raw[:nmax]):
            v |= (b & 0xFF) << (8 * i)
        return v

    lines = [
        f"// frozen PREREG corpus golden — {LAW}. Do not hand-edit.",
        f"localparam int unsigned NVEC = {n};",
        "localparam int unsigned VEC_SEC [0:NVEC-1] = '{",
        ",".join(str(r["section_id"]) for r in rows) + "};",
        "localparam int unsigned VEC_LEN [0:NVEC-1] = '{",
        ",".join(str(r["len"]) for r in rows) + "};",
        "localparam logic [383:0] VEC_BYTES [0:NVEC-1] = '{",
        ",".join(f"384'h{pack_bytes(bytes.fromhex(r['raw_hex'])):096x}" for r in rows) + "};",
        "localparam logic [7:0] G_EID [0:NVEC-1] = '{" + ",".join(f"8'd{r['golden']['entity_id']}" for r in rows) + "};",
        "localparam logic [7:0] G_IID [0:NVEC-1] = '{" + ",".join(f"8'd{r['golden']['intent_id']}" for r in rows) + "};",
        "localparam logic [7:0] G_RID [0:NVEC-1] = '{" + ",".join(f"8'd{r['golden']['relation_id']}" for r in rows) + "};",
        "localparam logic [7:0] G_XID [0:NVEC-1] = '{" + ",".join(f"8'd{r['golden']['context_id']}" for r in rows) + "};",
        "localparam logic [63:0] G_ECUE [0:NVEC-1] = '{" + ",".join(f"64'h{r['golden']['entity_cue']:016x}" for r in rows) + "};",
        "localparam logic [63:0] G_ICUE [0:NVEC-1] = '{" + ",".join(f"64'h{r['golden']['intent_cue']:016x}" for r in rows) + "};",
        "localparam logic [63:0] G_RCUE [0:NVEC-1] = '{" + ",".join(f"64'h{r['golden']['relation_cue']:016x}" for r in rows) + "};",
        "localparam logic [63:0] G_XCUE [0:NVEC-1] = '{" + ",".join(f"64'h{r['golden']['context_cue']:016x}" for r in rows) + "};",
        "localparam logic [15:0] G_CRC [0:NVEC-1] = '{" + ",".join(f"16'h{r['golden']['crc16_dbg']:04x}" for r in rows) + "};",
        "localparam logic [15:0] G_K0 [0:NVEC-1] = '{" + ",".join(f"16'h{r['golden']['k0']:04x}" for r in rows) + "};",
        "localparam logic [15:0] G_K1 [0:NVEC-1] = '{" + ",".join(f"16'h{r['golden']['k1']:04x}" for r in rows) + "};",
        "localparam logic [15:0] G_K2 [0:NVEC-1] = '{" + ",".join(f"16'h{r['golden']['k2']:04x}" for r in rows) + "};",
        "localparam logic [15:0] G_K3 [0:NVEC-1] = '{" + ",".join(f"16'h{r['golden']['k3']:04x}" for r in rows) + "};",
        "",
    ]
    path.write_text("\n".join(lines), encoding="utf-8")


def main():
    bag = Path(__file__).resolve().parent
    rows = build()
    blob = {
        "law": LAW,
        "prereg": "_PREREG.md",
        "n": len(rows),
        "sections": {k: sum(1 for r in rows if r["section"] == k) for k in SEC},
        "vectors": rows,
    }
    (bag / "FROZEN_VECTORS.json").write_text(json.dumps(blob, indent=2), encoding="utf-8")
    emit_svh(rows, bag / "frozen_vectors.svh")
    print("FROZEN_N", len(rows), "SECTIONS", blob["sections"])


if __name__ == "__main__":
    main()
