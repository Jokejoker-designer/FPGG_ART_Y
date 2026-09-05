#!/usr/bin/env python3
"""Independent U6 TYPE_CLASS host golden. Do not read RTL outputs."""
from __future__ import annotations

import hashlib
import json
import sys
from pathlib import Path

BAG = Path(__file__).resolve().parent
BAG_T2 = BAG.parent / "U5Q-T2-FPGA-TYPE-CLASS-TABLE-00"
BAG_U5Q = BAG.parent / "U5Q-M10-RETRIEVAL-QUALITY-SCALE-CLOSURE-00"
sys.path.insert(0, str(BAG_U5Q))
import host_u5q as u5q  # noqa: E402

K = 8
CAND_CAP = 64
PAD_BASE = 0x00FFFFF0
TABLE_SHA = "B5958D4ADBE96F1D4432915E767BA2C4806594DBB291BBFFBEC95FE588E436C2"
MAP_SHA = "CEA2B9710D4D5F229BC341DF790E557B20F023F98161464C6C79BEADAE6BD68B"


def sha_bytes(b: bytes) -> str:
    return hashlib.sha256(b).hexdigest().upper()


def sat16(a: int, b: int) -> int:
    s = a + b
    if s > 32767:
        return 32767
    if s < -32768:
        return -32768
    return s


def sext8(t: int) -> int:
    t = int(t) & 0xFF
    if t >= 128:
        t -= 256
    return t


def compose_tree(em, im, rm, cm, path=0, prior=0, pen=0) -> int:
    partial = sat16(sat16(sext8(em), sext8(im)), sat16(sext8(rm), sext8(cm)))
    return sat16(sat16(partial, sext8(path)), sat16(sext8(prior), -sext8(pen)))


def terms_of(q: dict, row: dict) -> dict:
    em = 8 if (q["eid"] and q["eid"] == row["eid"]) else 0
    im = 8 if (q["iid"] and q["iid"] == row["iid"]) else 0
    rm = 8 if (q["rid"] and q["rid"] == row["rid"]) else 0
    cm = 8 if (q["xid"] and q["xid"] == row["xid"]) else 0
    return dict(em=em, im=im, rm=rm, cm=cm, path=0, prior=0, pen=0)


def beats(a: dict, b: dict) -> bool:
    if a["v"] != b["v"]:
        return bool(a["v"])
    if a["v"]:
        if a["s"] != b["s"]:
            return a["s"] > b["s"]
        if a["id"] != b["id"]:
            return a["id"] < b["id"]
        return a["lane"] < b["lane"]
    if a["id"] != b["id"]:
        return a["id"] < b["id"]
    return a["lane"] < b["lane"]


def topk8(cands: list[dict]) -> list[dict]:
    nreal = len(cands)
    if nreal == 0:
        stream = [{"v": 0, "s": 0, "id": PAD_BASE + i, "lane": 0} for i in range(K)]
    elif nreal < K:
        pads = [{"v": 0, "s": 0, "id": PAD_BASE + i, "lane": 0} for i in range(K - nreal)]
        stream = list(cands) + pads
    else:
        stream = list(cands)
    h: list[dict] = []
    for c in stream:
        if len(h) < K:
            h.append(c)
        else:
            wi = 0
            for j in range(1, K):
                if beats(h[wi], h[j]):
                    wi = j
            if beats(c, h[wi]):
                h[wi] = c
    for p in range(K - 1):
        for j in range(K - 1 - p):
            if beats(h[j + 1], h[j]):
                h[j], h[j + 1] = h[j + 1], h[j]
    return h


def bound_empty(q: dict) -> bool:
    return not (q["eid"] or q["iid"] or q["rid"] or q["xid"])


def retrieve(rows: list[dict], q: dict, cap: int = CAND_CAP) -> dict:
    qb = u5q.bound_slots(q)
    hits = []
    ntrunc = 0
    ovf = 0
    if qb:
        for r in rows:
            rec = {"eid": r["eid"], "iid": r["iid"], "rid": r["rid"], "xid": r["xid"]}
            if all(rec[k] == v for k, v in qb.items()) and r["member_count"] != 0:
                if len(hits) >= cap:
                    ntrunc += 1
                    ovf = 1
                else:
                    hits.append(r)
    scored = []
    mats = []
    for r in hits:
        t = terms_of(q, r)
        sc = compose_tree(t["em"], t["im"], t["rm"], t["cm"])
        cid = int(r["class_id"])
        heap_id = cid  # zero-extend in 32-bit
        scored.append({"v": 1, "s": sc, "id": heap_id, "lane": 0, "class_id": cid, "terms": t})
        mats.append({
            "class_id": cid, "eid": r["eid"], "iid": r["iid"], "rid": r["rid"], "xid": r["xid"],
            "member_ptr": r["member_ptr"], "member_count": r["member_count"],
        })
    tk = topk8(scored)
    return {
        "n": len(hits),
        "ovf": ovf,
        "trunc": ntrunc,
        "class_ids": [r["class_id"] for r in hits],
        "materialized": mats,
        "scores": scored,
        "topk": tk,
        "q": {k: q[k] for k in ("eid", "iid", "rid", "xid")},
        "ev": int(q["eid"] != 0), "iv": int(q["iid"] != 0),
        "rv": int(q["rid"] != 0), "xv": int(q["xid"] != 0),
    }


def pack_text(t: str) -> tuple[int, str]:
    b = t.encode("latin1")[:48]
    v = 0
    for i, x in enumerate(b):
        v |= x << (8 * i)
    return len(b), f"{v:096X}"


def main() -> None:
    obj = json.loads((BAG_T2 / "TYPECLASS_TABLE.json").read_text(encoding="utf-8"))
    rows = obj["rows"]
    table_blob = json.dumps(rows, sort_keys=True, separators=(",", ":")).encode()
    map_lf = (BAG_T2 / "CLASS_ID_MAPPING.txt").read_bytes().replace(b"\r\n", b"\n")
    tsha = sha_bytes(table_blob)
    msha = sha_bytes(map_lf)
    if tsha != TABLE_SHA:
        raise SystemExit(f"TABLE SHA mismatch {tsha}")
    if msha != MAP_SHA:
        raise SystemExit(f"MAP SHA mismatch {msha}")

    qrows = u5q.query_list("confirm")
    gold_cands = []
    gold_mat = []
    gold_sc = []
    gold_tk = []
    for name, text in qrows:
        q = u5q.feat(text)
        g = retrieve(rows, q, CAND_CAP)
        g["name"] = name
        g["text"] = text
        gold_cands.append({
            "name": name, "text": text, "n": g["n"], "ovf": g["ovf"], "trunc": g["trunc"],
            "class_ids": g["class_ids"],
            "eid": q["eid"], "iid": q["iid"], "rid": q["rid"], "xid": q["xid"],
            "ev": g["ev"], "iv": g["iv"], "rv": g["rv"], "xv": g["xv"],
        })
        gold_mat.append({"name": name, "rows": g["materialized"]})
        gold_sc.append({
            "name": name,
            "items": [{"class_id": s["class_id"], "s": s["s"], **s["terms"]} for s in g["scores"]],
        })
        gold_tk.append({
            "name": name,
            "topk": [{"v": x["v"], "id": x["id"], "s": x["s"], "lane": x["lane"]} for x in g["topk"]],
        })
        print(name, "n", g["n"], "top", [x["id"] for x in g["topk"][:4]], "sc0", g["topk"][0]["s"])

    # directed protocol gold
    q_empty = {"eid": 0, "iid": 0, "rid": 0, "xid": 0}
    g_empty = retrieve(rows, q_empty)
    q_exact8 = {"eid": 0, "iid": 1, "rid": 3, "xid": 0}
    g_exact8 = retrieve(rows, q_exact8)
    q_leak = u5q.feat("leak check")
    g_cap8 = retrieve(rows, q_leak, cap=8)

    # poison B: class 57 eid -> 99 on chiller
    q_ch = u5q.feat("chiller")
    g_ch = retrieve(rows, q_ch)
    poisoned_rows = []
    for r in rows:
        rr = dict(r)
        if rr["class_id"] == 57:
            rr = dict(rr)
            rr["eid"] = 99
        poisoned_rows.append(rr)
    g_poi = retrieve(poisoned_rows, q_ch)

    proto = {
        "empty": {"n": g_empty["n"], "class_ids": g_empty["class_ids"],
                  "topk": [{"v": x["v"], "id": x["id"], "s": x["s"]} for x in g_empty["topk"]]},
        "exact8_iid1_rid3": {"n": g_exact8["n"], "class_ids": g_exact8["class_ids"],
                             "topk": [{"v": x["v"], "id": x["id"], "s": x["s"]} for x in g_exact8["topk"]]},
        "cap8_leak_check": {"n": g_cap8["n"], "ovf": g_cap8["ovf"], "trunc": g_cap8["trunc"],
                            "class_ids": g_cap8["class_ids"],
                            "topk": [{"v": x["v"], "id": x["id"], "s": x["s"]} for x in g_cap8["topk"]]},
        "poison_b_chiller_c57_eid99": {
            "n": g_poi["n"], "class_ids": g_poi["class_ids"],
            "topk": [{"v": x["v"], "id": x["id"], "s": x["s"]} for x in g_poi["topk"]],
            "baseline_top0": g_ch["topk"][0]["id"],
            "poison_top0": g_poi["topk"][0]["id"],
        },
    }
    print("empty", g_empty["n"], [x["id"] for x in g_empty["topk"]])
    print("exact8", g_exact8["n"], g_exact8["class_ids"])
    print("cap8", g_cap8["n"], "ovf", g_cap8["ovf"], "trunc", g_cap8["trunc"], g_cap8["class_ids"])
    print("poisonB top", [x["id"] for x in g_poi["topk"]], "vs", [x["id"] for x in g_ch["topk"]])

    freeze = {
        "TYPECLASS_TABLE_SHA256": tsha,
        "CLASS_ID_MAPPING_SHA256": msha,
        "tc_n": len(rows),
        "class_id_first": rows[0]["class_id"],
        "class_id_last": rows[-1]["class_id"],
        "nid_derived": False,
        "cand_cap": CAND_CAP,
        "K": K,
        "learn": 0,
        "match_const": 8,
        "pad_base": PAD_BASE,
        "tie": "valid>score>id<lane<",
    }
    (BAG / "TYPECLASS_FREEZE_REF.json").write_text(json.dumps(freeze, indent=2), encoding="utf-8")
    (BAG / "GOLDEN_TYPECLASS_CANDIDATES.json").write_text(json.dumps(gold_cands, indent=2), encoding="utf-8")
    (BAG / "GOLDEN_TYPECLASS_MATERIALIZED.json").write_text(json.dumps(gold_mat, indent=2), encoding="utf-8")
    (BAG / "GOLDEN_TYPECLASS_SCORES.json").write_text(json.dumps(gold_sc, indent=2), encoding="utf-8")
    (BAG / "GOLDEN_TYPECLASS_TOPK.json").write_text(json.dumps({"confirm": gold_tk, "proto": proto}, indent=2), encoding="utf-8")

    # SVH for TB
    nq = len(gold_cands)
    maxc = max(g["n"] for g in gold_cands)
    if maxc < 1:
        maxc = 1
    lines = [
        "// generated host_u6tc.py — independent host golden. CLASS_ID not NID.",
        f"localparam int U6_NQ = {nq};",
        f"localparam int U6_MAXC = {maxc};",
        f"localparam int U6_K = {K};",
        f"localparam logic [31:0] U6_PAD_BASE = 32'h{PAD_BASE:08X};",
        "localparam int U6_NC [0:U6_NQ-1] = '{" + ", ".join(str(g["n"]) for g in gold_cands) + "};",
        "localparam int U6_OVF [0:U6_NQ-1] = '{" + ", ".join(str(g["ovf"]) for g in gold_cands) + "};",
        "localparam logic [7:0] U6_QE [0:U6_NQ-1] = '{" + ", ".join("8'd%d" % g["eid"] for g in gold_cands) + "};",
        "localparam logic [7:0] U6_QI [0:U6_NQ-1] = '{" + ", ".join("8'd%d" % g["iid"] for g in gold_cands) + "};",
        "localparam logic [7:0] U6_QR [0:U6_NQ-1] = '{" + ", ".join("8'd%d" % g["rid"] for g in gold_cands) + "};",
        "localparam logic [7:0] U6_QX [0:U6_NQ-1] = '{" + ", ".join("8'd%d" % g["xid"] for g in gold_cands) + "};",
        "localparam logic U6_EV [0:U6_NQ-1] = '{" + ", ".join(str(g["ev"]) for g in gold_cands) + "};",
        "localparam logic U6_IV [0:U6_NQ-1] = '{" + ", ".join(str(g["iv"]) for g in gold_cands) + "};",
        "localparam logic U6_RV [0:U6_NQ-1] = '{" + ", ".join(str(g["rv"]) for g in gold_cands) + "};",
        "localparam logic U6_XV [0:U6_NQ-1] = '{" + ", ".join(str(g["xv"]) for g in gold_cands) + "};",
    ]
    flat_c, flat_s = [], []
    for g, sc in zip(gold_cands, gold_sc):
        ids = g["class_ids"] + [0] * (maxc - g["n"])
        ss = [it["s"] for it in sc["items"]] + [0] * (maxc - g["n"])
        flat_c.extend(ids)
        flat_s.extend(ss)
    lines.append(
        "localparam logic [15:0] U6_CAND [0:U6_NQ*U6_MAXC-1] = '{"
        + ", ".join("16'd%d" % x for x in flat_c) + "};"
    )
    lines.append(
        "localparam logic signed [15:0] U6_CSC [0:U6_NQ*U6_MAXC-1] = '{"
        + ", ".join("16'sd%d" % x for x in flat_s) + "};"
    )
    flat_tid, flat_tsc, flat_tv = [], [], []
    for tk in gold_tk:
        for x in tk["topk"]:
            flat_tid.append(x["id"])
            flat_tsc.append(x["s"])
            flat_tv.append(int(x["v"]))
    lines.append(
        "localparam logic [31:0] U6_TID [0:U6_NQ*U6_K-1] = '{"
        + ", ".join("32'h%08X" % x for x in flat_tid) + "};"
    )
    lines.append(
        "localparam logic signed [15:0] U6_TSC [0:U6_NQ*U6_K-1] = '{"
        + ", ".join("16'sd%d" % x for x in flat_tsc) + "};"
    )
    lines.append(
        "localparam logic U6_TV [0:U6_NQ*U6_K-1] = '{"
        + ", ".join(str(x) for x in flat_tv) + "};"
    )
    lens, hexes = zip(*(pack_text(g["text"]) for g in gold_cands))
    lines.append("localparam int U6_QLEN [0:U6_NQ-1] = '{" + ", ".join(str(x) for x in lens) + "};")
    lines.append(
        "localparam logic [8*48-1:0] U6_QBYTES [0:U6_NQ-1] = '{"
        + ", ".join("384'h" + h for h in hexes) + "};"
    )
    # proto
    e8 = g_exact8["class_ids"]
    lines.append("localparam int U6_EXACT8_N = %d;" % g_exact8["n"])
    lines.append(
        "localparam logic [15:0] U6_EXACT8_ID [0:7] = '{"
        + ", ".join("16'd%d" % x for x in e8) + "};"
    )
    lines.append(
        "localparam logic [31:0] U6_EXACT8_TID [0:7] = '{"
        + ", ".join("32'h%08X" % x["id"] for x in g_exact8["topk"]) + "};"
    )
    lines.append(
        "localparam logic signed [15:0] U6_EXACT8_TSC [0:7] = '{"
        + ", ".join("16'sd%d" % x["s"] for x in g_exact8["topk"]) + "};"
    )
    c8 = g_cap8["class_ids"]
    lines.append("localparam int U6_CAP8_N = %d;" % g_cap8["n"])
    lines.append("localparam int U6_CAP8_TRUNC = %d;" % g_cap8["trunc"])
    lines.append(
        "localparam logic [15:0] U6_CAP8_ID [0:7] = '{"
        + ", ".join("16'd%d" % x for x in c8) + "};"
    )
    lines.append(
        "localparam logic [31:0] U6_CAP8_TID [0:7] = '{"
        + ", ".join("32'h%08X" % x["id"] for x in g_cap8["topk"]) + "};"
    )
    lines.append(
        "localparam logic [31:0] U6_POIB_TID [0:7] = '{"
        + ", ".join("32'h%08X" % x["id"] for x in g_poi["topk"]) + "};"
    )
    lines.append(
        "localparam logic signed [15:0] U6_POIB_TSC [0:7] = '{"
        + ", ".join("16'sd%d" % x["s"] for x in g_poi["topk"]) + "};"
    )
    (BAG / "u6tc_gold.svh").write_text("\n".join(lines) + "\n", encoding="utf-8")
    print("WROTE gold nq", nq, "maxc", maxc)


if __name__ == "__main__":
    main()
