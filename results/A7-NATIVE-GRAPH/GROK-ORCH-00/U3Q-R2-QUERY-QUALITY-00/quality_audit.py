#!/usr/bin/env python3
"""U3Q-R2 held-out query quality. FPGA law qfe-v1-crc16-mix-00 twin.

CRC same-in-same-out is LAW_SELFCHECK, never semantic recall.
Gold for retrieval is independent labels, not key buckets.
PROGRAM=NO. HOST_MODEL + later XSim spot.
"""
from __future__ import annotations

import json
from collections import defaultdict
from pathlib import Path

LAW = "qfe-v1-crc16-mix-00"
U3Q_HELD_IN = {(2, 3, 4), (2, 3, 5), (8, 1, 9, 2), (8, 1, 9, 3)}
N_BUCKETS_12 = 4096  # 12-bit K0
CHANCE_12 = 1.0 / N_BUCKETS_12
MAX_TOK = 16


def crc16_ccitt_false(data: bytes) -> int:
    crc = 0xFFFF
    for b in data:
        crc ^= b << 8
        for _ in range(8):
            if crc & 0x8000:
                crc = ((crc << 1) & 0xFFFF) ^ 0x1021
            else:
                crc = (crc << 1) & 0xFFFF
    return crc


def qfe_keys(tokens: list[int]) -> tuple[int, int, int, int]:
    assert 1 <= len(tokens) <= MAX_TOK
    xor = 0
    sm = 0
    for b in tokens:
        xor ^= b
        sm = (sm + b) & 0xFFFF
    crc = crc16_ccitt_false(bytes(tokens))
    first, last, L = tokens[0], tokens[-1], len(tokens)
    k0 = crc
    k1 = crc ^ ((xor << 8) | first)
    k2 = ((sm & 0xFF) << 8 | xor) ^ ((last << 8) | first)
    k3 = ((L << 8) | xor) ^ crc
    return k0 & 0xFFFF, k1 & 0xFFFF, k2 & 0xFFFF, k3 & 0xFFFF


def tok(s: str) -> list[int]:
    raw = s.lower().encode("ascii", "ignore")[:MAX_TOK]
    if not raw:
        raise ValueError(s)
    return list(raw)


def k12(k0: int) -> int:
    return k0 % N_BUCKETS_12


# Held-out HVAC/M&E surface forms. Not U3Q Q0..Q4 numeric tokens.
ENTITY = {
    "chiller": ["chiller", "water chiller", "chiller unit", "chiller plant"],
    "condenser": ["condenser", "condensing unit", "air condenser", "condenser coil"],
    "evaporator": ["evaporator", "evap coil", "evaporator coil", "dx evaporator"],
    "compressor": ["compressor", "scroll compressor", "compressor unit"],
    "refrigerant": ["refrigerant", "r410a", "r32 gas", "refrigerant line"],
    "ahu": ["ahu", "air handler", "ahu unit", "air handling"],
    "duct": ["duct", "supply duct", "return duct", "ductwork"],
    "vav": ["vav", "vav box", "variable air"],
    "cooling_tower": ["cooling tower", "tower cell", "ct fan"],
    "pump": ["chilled pump", "condenser pump", "water pump"],
    "valve": ["expansion valve", "txv valve", "solenoid valve"],
    "sensor": ["temp sensor", "pressure sensor", "dp sensor"],
}

INTENT = {
    "install": ["install chiller", "mount chiller", "chiller installation"],
    "leak": ["leak check", "check leak", "find leak", "gas leak test"],
    "balance": ["air balance", "balance airflow", "tab balance"],
    "insulate": ["insulate pipe", "pipe insulation", "wrap pipe"],
    "startup": ["startup ahu", "commission ahu", "ahu start"],
    "replace": ["replace compressor", "swap compressor", "new compressor"],
}

UNRELATED = [
    "payroll tax form",
    "weather forecast",
    "soccer match score",
    "cookie recipe",
    "piano lesson",
    "airport delay",
    "stock ticker",
    "garden soil",
]

# Perturbations: 1-byte change of a canonical entity string.
PERTURB_BASE = ["chiller", "condenser", "evaporator", "compressor", "ahu unit"]


def build_corpus():
    rows = []
    for eid, forms in ENTITY.items():
        for i, s in enumerate(forms):
            rows.append({
                "split": "entity",
                "label": eid,
                "role": "canonical" if i == 0 else "variant",
                "text": s,
                "tokens": tok(s),
            })
    for iid, forms in INTENT.items():
        for i, s in enumerate(forms):
            rows.append({
                "split": "intent",
                "label": iid,
                "role": "canonical" if i == 0 else "variant",
                "text": s,
                "tokens": tok(s),
            })
    for s in UNRELATED:
        rows.append({
            "split": "unrelated",
            "label": "unrelated",
            "role": "unrelated",
            "text": s,
            "tokens": tok(s),
        })
    for s in PERTURB_BASE:
        t = tok(s)
        t2 = t.copy()
        t2[-1] = (t2[-1] + 1) & 0xFF
        if t2[-1] == 0:
            t2[-1] = 1
        rows.append({
            "split": "perturbation",
            "label": s,
            "role": "base",
            "text": s,
            "tokens": t,
        })
        rows.append({
            "split": "perturbation",
            "label": s,
            "role": "edit",
            "text": s + "#p",
            "tokens": t2,
        })
    for r in rows:
        tt = tuple(r["tokens"])
        if tt in U3Q_HELD_IN:
            raise SystemExit(f"HELD_IN_LEAK {r}")
        r["keys"] = list(qfe_keys(r["tokens"]))
        r["k12"] = k12(r["keys"][0])
    return rows


def law_selfcheck() -> dict:
    a = qfe_keys([2, 3, 4])
    b = qfe_keys([2, 3, 4])
    c = qfe_keys([2, 3, 5])
    return {
        "name": "LAW_SELFCHECK",
        "not_semantic_recall": True,
        "same_in_same_out": a == b,
        "token_delta_changes_keys": a != c,
        "q0_k0": f"{a[0]:04X}",
        "q1_k0": f"{c[0]:04X}",
        "expect_q0_k0": "B72B",
        "q0_match_u3q": a == (0xB72B, 0xB229, 0x0D07, 0xB42E),
    }


def stability(rows, split: str) -> dict:
    by = defaultdict(list)
    for r in rows:
        if r["split"] == split:
            by[r["label"]].append(r)
    n = 0
    hit = 0
    for _lab, items in by.items():
        cans = [x for x in items if x["role"] == "canonical"]
        vars_ = [x for x in items if x["role"] == "variant"]
        if not cans or not vars_:
            continue
        ck = cans[0]["k12"]
        for v in vars_:
            n += 1
            if v["k12"] == ck:
                hit += 1
    return {"n_pairs": n, "same_k12": hit, "rate": (hit / n) if n else 0.0}


def unrelated_collision(rows) -> dict:
    ks = [r["k12"] for r in rows if r["split"] == "unrelated"]
    n = 0
    hit = 0
    for i in range(len(ks)):
        for j in range(i + 1, len(ks)):
            n += 1
            if ks[i] == ks[j]:
                hit += 1
    rate = (hit / n) if n else 0.0
    return {
        "n_pairs": n,
        "same_k12": hit,
        "rate": rate,
        "chance_12bit": CHANCE_12,
        "rate_over_chance": (rate / CHANCE_12) if CHANCE_12 else None,
    }


def perturbation_delta(rows) -> dict:
    by = defaultdict(dict)
    for r in rows:
        if r["split"] == "perturbation":
            by[r["label"]][r["role"]] = r
    n = 0
    changed = 0
    for _lab, d in by.items():
        if "base" in d and "edit" in d:
            n += 1
            if tuple(d["base"]["keys"]) != tuple(d["edit"]["keys"]):
                changed += 1
    return {"n_pairs": n, "key_delta": changed, "rate": (changed / n) if n else 0.0}


def retrieval(rows) -> dict:
    """Label-gold retrieval via 2-table 12-bit buckets of extractor keys.

    Docs = entity+intent surface forms. Gold = same label, not same key.
    """
    docs = [r for r in rows if r["split"] in ("entity", "intent")]
    # index: table t bucket -> doc indices
    heads = [[defaultdict(list) for _ in range(2)] for _ in range(1)]
    # flatten: tables 0..1
    table = [defaultdict(list), defaultdict(list)]
    for i, d in enumerate(docs):
        k0, k1, _, _ = d["keys"]
        table[0][k0 % N_BUCKETS_12].append(i)
        table[1][k1 % N_BUCKETS_12].append(i)

    def recall_at(k: int) -> float:
        recs = []
        for qi, q in enumerate(docs):
            gold = {j for j, d in enumerate(docs)
                    if d["split"] == q["split"] and d["label"] == q["label"] and j != qi}
            if not gold:
                continue
            k0, k1, _, _ = q["keys"]
            seen = []
            used = set()
            for nid in table[0][k0 % N_BUCKETS_12] + table[1][k1 % N_BUCKETS_12]:
                if nid == qi or nid in used:
                    continue
                used.add(nid)
                seen.append(nid)
            got = gold.intersection(seen[:k])
            recs.append(len(got) / len(gold))
        return sum(recs) / len(recs) if recs else 0.0

    return {
        "n_docs": len(docs),
        "gold": "independent_label_same_entity_or_intent",
        "recall_at_16": recall_at(16),
        "recall_at_64": recall_at(64),
        "note": "not CRC self-consistency",
    }


def spot_vectors(rows, n=8):
    picks = []
    for split in ("entity", "intent", "unrelated", "perturbation"):
        for r in rows:
            if r["split"] == split and r not in picks:
                picks.append(r)
                break
    for r in rows:
        if len(picks) >= n:
            break
        if r not in picks:
            picks.append(r)
    return [
        {
            "text": p["text"],
            "split": p["split"],
            "tokens": p["tokens"],
            "k0": f"{p['keys'][0]:04X}",
            "k1": f"{p['keys'][1]:04X}",
            "k2": f"{p['keys'][2]:04X}",
            "k3": f"{p['keys'][3]:04X}",
        }
        for p in picks[:n]
    ]


def write_spot_tb(bag: Path, spots: list[dict]):
    lines = [
        "// auto-generated by quality_audit.py — U3Q-R2 spot. PROGRAM=NO.",
        "`timescale 1ns / 1ps",
        "module tb_u3q_r2_spot;",
        "  logic clk, rst_n, tok_v, tok_r, fire, busy, valid;",
        "  logic [7:0] tok, ntok, txor, first_t, last_t;",
        "  logic [15:0] tsum, crc, k0, k1, k2, k3;",
        "  integer fail;",
        "  a7ng_query_feature_extract dut (",
        "    .clk(clk), .rst_n(rst_n),",
        "    .tok_valid_i(tok_v), .tok_ready_o(tok_r), .tok_i(tok),",
        "    .fire_i(fire), .busy_o(busy), .valid_o(valid),",
        "    .tok_count_o(ntok), .tok_xor_o(txor), .tok_sum_o(tsum), .crc_o(crc),",
        "    .first_tok_o(first_t), .last_tok_o(last_t),",
        "    .k0_o(k0), .k1_o(k1), .k2_o(k2), .k3_o(k3)",
        "  );",
        "  initial clk = 0; always #5 clk = ~clk;",
        "  task automatic send_tok(input logic [7:0] b);",
        "    begin @(posedge clk); tok_v <= 1'b1; tok <= b; @(posedge clk);",
        "      if (!tok_r) fail = fail + 1; tok_v <= 1'b0; end",
        "  endtask",
        "  task automatic do_fire; begin @(posedge clk); fire <= 1; @(posedge clk); fire <= 0; end endtask",
        "  initial begin",
        "    fail = 0; rst_n = 0; tok_v = 0; tok = 0; fire = 0;",
        "    repeat (4) @(posedge clk); rst_n = 1; repeat (2) @(posedge clk);",
    ]
    for i, s in enumerate(spots):
        for b in s["tokens"]:
            lines.append(f"    send_tok(8'h{b:02X});")
        lines.append("    do_fire(); @(posedge clk);")
        lines.append("    if (!valid) fail = fail + 1;")
        lines.append(
            f"    if (k0!==16'h{s['k0']} || k1!==16'h{s['k1']} || k2!==16'h{s['k2']} || k3!==16'h{s['k3']}) begin"
        )
        lines.append(f"      fail = fail + 1; $display(\"SPOT{i} MISMATCH %h %h %h %h\", k0,k1,k2,k3);")
        lines.append("    end else $display(\"SPOT%d OK %s\", " + str(i) + f", \"{s['split']}\");")
    lines += [
        "    if (fail==0) $display(\"U3Q_R2_XSIM_SPOT_PASS\");",
        "    else $display(\"U3Q_R2_XSIM_SPOT_FAIL fail=%0d\", fail);",
        "    #20 $finish;",
        "  end",
        "endmodule",
        "",
    ]
    (bag / "tb_u3q_r2_spot.sv").write_text("\n".join(lines), encoding="utf-8")


def main():
    bag = Path(__file__).resolve().parent
    rows = build_corpus()
    law = law_selfcheck()
    ent = stability(rows, "entity")
    inten = stability(rows, "intent")
    unrel = unrelated_collision(rows)
    pert = perturbation_delta(rows)
    retr = retrieval(rows)
    spots = spot_vectors(rows, 8)
    write_spot_tb(bag, spots)

    quality_open = True
    # Honest: CRC token hash is not an embedding. Do not freeze semantic authority.
    # Gate PASS is measurement integrity, not high paraphrase recall.
    measure_ok = (
        law["same_in_same_out"]
        and law["token_delta_changes_keys"]
        and law["q0_match_u3q"]
        and pert["rate"] == 1.0
        and retr["gold"] == "independent_label_same_entity_or_intent"
    )
    out = {
        "gate": "U3Q-R2-QUERY-QUALITY-00",
        "law": LAW,
        "evidence_class": "HOST_MODEL",
        "extractor_fpga_owned": True,
        "host_hash_winner_address": False,
        "crc_selfcheck_is_not_semantic_recall": True,
        "law_selfcheck": law,
        "n_corpus": len(rows),
        "entity_k12_stability": ent,
        "intent_k12_stability": inten,
        "unrelated_k12_collision": unrel,
        "perturbation_key_delta": pert,
        "downstream_retrieval": retr,
        "spot": spots,
        "measure_ok": measure_ok,
        "semantic_authority": "OPEN",
        "quality_open": quality_open,
        "note": (
            "entity/intent k12 stability is a hash-bucket coincidence metric. "
            "Do not report law_selfcheck as semantic recall."
        ),
    }
    (bag / "METRICS.json").write_text(json.dumps(out, indent=2), encoding="utf-8")
    (bag / "corpus.json").write_text(
        json.dumps([{k: v for k, v in r.items() if k != "keys"} | {"keys": [f"{x:04X}" for x in r["keys"]]} for r in rows], indent=2),
        encoding="utf-8",
    )
    print("LAW_SELFCHECK", law)
    print("ENTITY_STAB", ent)
    print("INTENT_STAB", inten)
    print("UNRELATED_COLLISION", unrel)
    print("PERTURB_DELTA", pert)
    print("RETRIEVAL", retr)
    if not measure_ok:
        print("U3Q_R2_MEASURE_FAIL")
        raise SystemExit(2)
    print("U3Q_R2_MEASURE_PASS")
    print("U3Q_R2_SEMANTIC_AUTHORITY_OPEN")
    print("CRC_SELFCHECK_NOT_SEMANTIC_RECALL")


if __name__ == "__main__":
    main()
