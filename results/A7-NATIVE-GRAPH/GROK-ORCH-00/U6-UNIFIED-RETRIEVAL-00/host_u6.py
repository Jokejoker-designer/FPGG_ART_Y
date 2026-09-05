#!/usr/bin/env python3
"""U6 independent host golden: retrieve → terms → scorer tree → Top-8 beats()."""
from __future__ import annotations

import json
import sys
from pathlib import Path

BAG = Path(__file__).resolve().parent
BAG_U4 = BAG.parent / "U4-MEM02-AXI-DIRECTORY-00"
BAG_U3Q = BAG.parent / "U3Q-R3-STRUCTURED-QUERY-FEATURE-00"
sys.path.insert(0, str(BAG_U4))
sys.path.insert(0, str(BAG_U3Q))
from host_u4 import (  # noqa: E402
    CAND_CAP,
    ENTRY,
    EPOCH,
    INDEX_BASE,
    N_BUCKETS,
    N_TABLES,
    POST_HEAP,
    adv0,
    build_docs,
    dir_addr,
    dir_pack,
    feat,
    index_docs,
    pack_post_beat,
    word_of,
)
from lexicon import ADV_SEED  # noqa: E402

K = 8
SENTINEL = 799999
PAD_BASE = 0x00FFFFF0


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
    """Match a7ng_scorer_lane staging, not pkg left-fold."""
    partial = sat16(sat16(sext8(em), sext8(im)), sat16(sext8(rm), sext8(cm)))
    return sat16(sat16(partial, sext8(path)), sat16(sext8(prior), -sext8(pen)))


def terms_of(q, rec):
    if rec.get("use_st"):
        return rec["terms"]
    em = 8 if (q["ent"] and q["ent"] == rec["ent"]) else 0
    im = 8 if (q["int"] and q["int"] == rec["int"]) else 0
    rm = 8 if (q["rel"] and q["rel"] == rec["rel"]) else 0
    cm = 8 if (q["ctx"] and q["ctx"] == rec["ctx"]) else 0
    return dict(em=em, im=im, rm=rm, cm=cm, path=0, prior=0, pen=0)


def beats(a, b) -> bool:
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


def topk8(cands):
    """Insert stream then sort by beats; pad to 8 invalids like U6 RTL."""
    stream = list(cands)
    while len(stream) < K:
        i = len(stream)
        stream.append({"v": 0, "s": 0, "id": PAD_BASE + (i - len(cands) if len(cands) else i), "lane": 0})
    # pads: RTL uses n_pad 0.. for ids PAD+n_pad after reals
    pads = []
    nreal = len(cands)
    if nreal == 0:
        pads = [{"v": 0, "s": 0, "id": PAD_BASE + i, "lane": 0} for i in range(K)]
        stream = pads
    elif nreal < K:
        pads = [{"v": 0, "s": 0, "id": PAD_BASE + i, "lane": 0} for i in range(K - nreal)]
        stream = list(cands) + pads
    # retain best K by streaming min-heap of worst
    h = []
    for c in stream:
        if len(h) < K:
            h.append(c)
        else:
            # root = worst
            wi = 0
            for j in range(1, K):
                if beats(h[wi], h[j]):
                    wi = j
            if beats(c, h[wi]):
                h[wi] = c
    # sort best-first: beats(a,b) means a better than b so a should come first
    for p in range(K - 1):
        for j in range(K - 1 - p):
            if beats(h[j + 1], h[j]):
                h[j], h[j + 1] = h[j + 1], h[j]
    return h


def route(q, heads):
    predup, seen, ndup, ntrunc = [], [], 0, 0
    dirs, posts, pcnts = [], [], []
    for t in range(4):
        if not q["v"][t]:
            continue
        b = q["k"][t] & 0xFFF
        dirs.append(dir_addr(t, q["k"][t]))
        ids = list(heads[t][b])
        pcnts.append(len(ids))
        posts.append(1 if ids else 0)
        for nid in ids:
            predup.append(nid)
            if nid in seen:
                ndup += 1
            elif len(seen) >= CAND_CAP:
                ntrunc += 1
            else:
                seen.append(nid)
    return seen, predup, ndup, ntrunc, dirs


def main() -> int:
    docs = build_docs()
    heads, _ovf = index_docs(docs)
    recs = {}
    for d in docs:
        recs[d["nid"]] = {
            "ent": d["entity_id"] if "entity_id" in d else feat(d["text"])["entity_id"] if False else None
        }
    # rebuild recs from feat
    recs = {}
    for d in docs:
        x = feat(d["text"] if "text" in d else "")
        # docs from build_docs have k,v from feat already but not ent fields
    # build_docs stores nid,label,k,v,crc,eid,iid,rid,xid
    recs = {}
    for d in docs:
        recs[d["nid"]] = {
            "ent": d["eid"], "int": d["iid"], "rel": d["rid"], "ctx": d["xid"],
            "use_st": 0, "terms": None, "text": d.get("text", ""),
        }

    def plant(t, key, ids, ovf=0):
        b = key & 0xFFF
        heads[t][b] = list(ids)
        return dir_addr(t, key)

    # sentinel
    recs[SENTINEL] = {"ent": 9, "int": 0, "rel": 0, "ctx": 0, "use_st": 0, "terms": None}
    plant(0, 0x0FD0, [SENTINEL])
    # exactly 64
    ids64 = list(range(5000, 5064))
    for i, nid in enumerate(ids64):
        recs[nid] = {"ent": 1, "int": 0, "rel": 0, "ctx": 0, "use_st": 0, "terms": None}
    plant(0, 0x0FB0, ids64)
    # 80 trunc
    ids80 = list(range(5100, 5180))
    for nid in ids80:
        recs[nid] = {"ent": 1, "int": 0, "rel": 0, "ctx": 0, "use_st": 0, "terms": None}
    plant(0, 0x0FE0, ids80)
    # empty
    plant(0, 0x0EE0, [])
    # equal score two ids
    recs[6000] = {"ent": 7, "int": 0, "rel": 0, "ctx": 0, "use_st": 0, "terms": None}
    recs[6001] = {"ent": 7, "int": 0, "rel": 0, "ctx": 0, "use_st": 0, "terms": None}
    plant(0, 0x0FA0, [6001, 6000])  # posting order 6001 then 6000; tie id< keeps 6000 first in TopK
    # sat pos/neg stored terms
    recs[7000] = {"ent": 0, "int": 0, "rel": 0, "ctx": 0, "use_st": 1,
                  "terms": dict(em=127, im=127, rm=127, cm=127, path=127, prior=127, pen=127)}
    recs[7001] = {"ent": 0, "int": 0, "rel": 0, "ctx": 0, "use_st": 1,
                  "terms": dict(em=-128, im=-128, rm=-128, cm=-128, path=-128, prior=-128, pen=0)}
    plant(0, 0x0F90, [7000])
    plant(0, 0x0F80, [7001])

    writes = {}
    post_ptr = POST_HEAP
    for t in range(N_TABLES):
        for b in range(N_BUCKETS):
            ids = heads[t][b]
            if not ids:
                continue
            n = len(ids)
            nbeats = (n + 3) // 4
            base = post_ptr
            post_ptr += nbeats * ENTRY
            writes[word_of(dir_addr(t, b))] = dir_pack(base, n, 1 if n > 64 else 0, EPOCH)
            for i in range(nbeats):
                writes[word_of(base + i * ENTRY)] = pack_post_beat(ids[i * 4 : i * 4 + 4])

    def qpack(text=None, k=None, v=None, ent=0, ii=0, rel=0, ctx=0, mode=0, name=""):
        if text is not None:
            f = feat(text)
            return {
                "name": name, "mode": mode, "text": text,
                "k": f["k"], "v": f["v"],
                "ent": f["eid"], "int": f["iid"], "rel": f["rid"], "ctx": f["xid"],
            }
        return {"name": name, "mode": 1, "text": "", "k": k, "v": v,
                "ent": ent, "int": ii, "rel": rel, "ctx": ctx}

    queries = [
        qpack(text="chiller", mode=0, name="chiller"),
        qpack(text="water chiller", mode=0, name="water_chiller"),
        qpack(text="leak chiller", mode=0, name="leak_chiller"),
        qpack(text="payroll tax form", mode=0, name="payroll"),
        qpack(text="soccer match score", mode=0, name="soccer"),
        qpack(text=adv0(), mode=0, name="adversarial"),
        qpack(name="dup_chiller", mode=0, text="chiller"),  # same as 0, dups in predup
        qpack(name="cap64", k=[0x0FB0, 0, 0, 0], v=[1, 0, 0, 0], ent=1),
        qpack(name="cap80", k=[0x0FE0, 0, 0, 0], v=[1, 0, 0, 0], ent=1),
        qpack(name="sentinel", k=[0x0FD0, 0, 0, 0], v=[1, 0, 0, 0], ent=9),
        qpack(name="empty", k=[0x0EE0, 0, 0, 0], v=[1, 0, 0, 0], ent=1),
        qpack(name="unknown", k=[0, 0, 0, 0], v=[0, 0, 0, 0]),
        qpack(name="tie", k=[0x0FA0, 0, 0, 0], v=[1, 0, 0, 0], ent=7),
        qpack(name="sat_pos", k=[0x0F90, 0, 0, 0], v=[1, 0, 0, 0]),
        qpack(name="sat_neg", k=[0x0F80, 0, 0, 0], v=[1, 0, 0, 0]),
    ]

    gold_c, gold_s, gold_t = [], [], []
    qres = []
    for q in queries:
        seen, predup, ndup, ntrunc, dirs = route(q, heads)
        scored = []
        for nid in seen:
            rec = recs[nid]
            tm = terms_of(q, rec)
            s = compose_tree(tm["em"], tm["im"], tm["rm"], tm["cm"], tm["path"], tm["prior"], tm["pen"])
            scored.append({
                "id": nid, "ent": rec["ent"], "int": rec["int"], "rel": rec["rel"], "ctx": rec["ctx"],
                "terms": tm, "score": s, "v": 1, "s": s, "lane": 0,
            })
        tk = topk8([{"v": 1, "s": x["score"], "id": x["id"], "lane": 0} for x in scored])
        qres.append({
            "name": q["name"], "mode": q["mode"], "text": q["text"],
            "k": q["k"], "v": q["v"], "ent": q["ent"], "int": q["int"], "rel": q["rel"], "ctx": q["ctx"],
            "cand_ids": seen, "n_trunc": ntrunc, "n_dup": ndup, "n_dir": len(dirs),
            "overflow": 1 if ntrunc else 0,
        })
        gold_c.append({"name": q["name"], "ids": seen, "predup": predup, "n_trunc": ntrunc})
        gold_s.append({"name": q["name"], "rows": [
            {"id": x["id"], "score": x["score"], "terms": x["terms"],
             "ent": x["ent"], "int": x["int"], "rel": x["rel"], "ctx": x["ctx"]}
            for x in scored
        ]})
        gold_t.append({"name": q["name"], "topk": [
            {"id": c["id"], "score": c["s"], "v": c["v"]} for c in tk
        ]})

    fail = []
    ch = next(x for x in gold_t if x["name"] == "chiller")
    if not ch["topk"][0]["v"]:
        fail.append("CHILLER_EMPTY_TOP")
    sen = next(x for x in gold_c if x["name"] == "sentinel")
    if sen["ids"] != [SENTINEL]:
        fail.append("SENTINEL_GOLD")
    c80 = next(x for x in gold_c if x["name"] == "cap80")
    if len(c80["ids"]) != 64 or c80["n_trunc"] != 16:
        fail.append("CAP80_GOLD")
    tie = next(x for x in gold_t if x["name"] == "tie")
    ids_v = [c["id"] for c in tie["topk"] if c["v"]]
    if ids_v[:2] != [6000, 6001]:
        fail.append(f"TIE_GOLD {ids_v[:2]}")
    unk = next(x for x in gold_c if x["name"] == "unknown")
    if unk["ids"]:
        fail.append("UNK_GOLD")

    result = "PASS" if not fail else "FAIL"
    (BAG / "GOLDEN_CANDIDATES.json").write_text(json.dumps(gold_c, indent=2), encoding="utf-8")
    (BAG / "GOLDEN_SCORES.json").write_text(json.dumps(gold_s, indent=2), encoding="utf-8")
    (BAG / "GOLDEN_TOPK.json").write_text(json.dumps(gold_t, indent=2), encoding="utf-8")
    (BAG / "GOLDEN.json").write_text(json.dumps({"result": result, "fail": fail, "n_q": len(queries)}, indent=2), encoding="utf-8")

    # LUT + mem svh
    lut_ids = sorted(recs.keys())
    def hx16(v):
        return f"16'h{v & 0xFFFF:04X}"
    def t8(v):
        v = int(v)
        if v < 0:
            return f"8'sh{(v + 256) & 0xFF:02X}"
        return f"8'sd{v}"

    nlut = len(lut_ids)
    lines = ["// generated host_u6.py", f"localparam int unsigned G_LUT_N = {nlut};"]
    lines.append("localparam logic [19:0] G_LUT_ID [0:G_LUT_N-1] = '{" + ", ".join(f"20'h{i:05X}" for i in lut_ids) + "};")
    lines.append("localparam logic G_LUT_OCC [0:G_LUT_N-1] = '{" + ", ".join("1" for _ in lut_ids) + "};")
    lines.append("localparam logic [7:0] G_LUT_ENT [0:G_LUT_N-1] = '{" + ", ".join(f"8'd{recs[i]['ent']}" for i in lut_ids) + "};")
    lines.append("localparam logic [7:0] G_LUT_INT [0:G_LUT_N-1] = '{" + ", ".join(f"8'd{recs[i]['int']}" for i in lut_ids) + "};")
    lines.append("localparam logic [7:0] G_LUT_REL [0:G_LUT_N-1] = '{" + ", ".join(f"8'd{recs[i]['rel']}" for i in lut_ids) + "};")
    lines.append("localparam logic [7:0] G_LUT_CTX [0:G_LUT_N-1] = '{" + ", ".join(f"8'd{recs[i]['ctx']}" for i in lut_ids) + "};")
    lines.append("localparam logic G_LUT_UST [0:G_LUT_N-1] = '{" + ", ".join(str(int(recs[i]["use_st"])) for i in lut_ids) + "};")
    def term_or(i, k):
        tm = recs[i]["terms"] or dict(em=0, im=0, rm=0, cm=0, path=0, prior=0, pen=0)
        return tm[k]
    for arr, key in [("TE", "em"), ("TI", "im"), ("TR", "rm"), ("TC", "cm"), ("TP", "path"), ("TPR", "prior"), ("TPE", "pen")]:
        lines.append(f"localparam logic signed [7:0] G_LUT_{arr} [0:G_LUT_N-1] = '" + "{" + ", ".join(t8(term_or(i, key)) for i in lut_ids) + "};")
    wr = sorted(writes)
    lines.append(f"localparam int unsigned G_N_WR = {len(wr)};")
    lines.append("localparam int G_WR_I [0:G_N_WR-1] = '{" + ", ".join(str(i) for i in wr) + "};")
    lines.append("localparam logic [127:0] G_WR_D [0:G_N_WR-1] = '{" + ", ".join(f"128'h{writes[i]:032X}" for i in wr) + "};")
    nq = len(queries)
    lines.append(f"localparam int unsigned G_N_Q = {nq};")
    lines.append("localparam int G_MODE [0:G_N_Q-1] = '{" + ", ".join(str(q["mode"]) for q in queries) + "};")
    lines.append("localparam int G_LEN [0:G_N_Q-1] = '{" + ", ".join(str(len(q["text"].encode("latin1")[:48])) for q in queries) + "};")
    def pack_text(s):
        b = s.encode("latin1")[:48]
        v = 0
        for i, x in enumerate(b):
            v |= x << (8 * i)
        return v
    lines.append("localparam logic [8*48-1:0] G_BYTES [0:G_N_Q-1] = '{" + ", ".join(f"384'h{pack_text(q['text']):096X}" for q in queries) + "};")
    for fld, idx in [("K0", 0), ("K1", 1), ("K2", 2), ("K3", 3)]:
        lines.append(f"localparam logic [15:0] G_{fld} [0:G_N_Q-1] = '" + "{" + ", ".join(hx16(q["k"][idx]) for q in queries) + "};")
    for fld, idx in [("V0", 0), ("V1", 1), ("V2", 2), ("V3", 3)]:
        lines.append(f"localparam logic G_{fld} [0:G_N_Q-1] = '" + "{" + ", ".join(str(q["v"][idx]) for q in queries) + "};")
    lines.append("localparam logic [7:0] G_ENT [0:G_N_Q-1] = '{" + ", ".join(f"8'd{q['ent']}" for q in queries) + "};")
    lines.append("localparam logic [7:0] G_INT [0:G_N_Q-1] = '{" + ", ".join(f"8'd{q['int']}" for q in queries) + "};")
    lines.append("localparam logic [7:0] G_REL [0:G_N_Q-1] = '{" + ", ".join(f"8'd{q['rel']}" for q in queries) + "};")
    lines.append("localparam logic [7:0] G_CTX [0:G_N_Q-1] = '{" + ", ".join(f"8'd{q['ctx']}" for q in queries) + "};")
    lines.append("localparam logic [15:0] G_NTRUNC [0:G_N_Q-1] = '{" + ", ".join(hx16(r["n_trunc"]) for r in qres) + "};")
    lines.append("localparam logic G_OVF [0:G_N_Q-1] = '{" + ", ".join(str(r["overflow"]) for r in qres) + "};")
    lines.append("localparam int G_NCAND [0:G_N_Q-1] = '{" + ", ".join(str(len(r["cand_ids"])) for r in qres) + "};")
    maxc = max(max(len(r["cand_ids"]) for r in qres), 1)
    flatc = []
    for r in qres:
        flatc.extend((r["cand_ids"] + [0] * maxc)[:maxc])
    lines.append(f"localparam int unsigned G_MAXC = {maxc};")
    lines.append("localparam logic [19:0] G_CAND [0:G_N_Q*G_MAXC-1] = '{" + ", ".join(f"20'h{x:05X}" for x in flatc) + "};")
    flatt = []
    for t in gold_t:
        for c in t["topk"]:
            flatt.append((c["id"], c["score"] & 0xFFFF, c["v"]))
    lines.append("localparam logic [31:0] G_TKID [0:G_N_Q*8-1] = '{" + ", ".join(f"32'h{x[0]:08X}" for x in flatt) + "};")
    lines.append("localparam logic signed [15:0] G_TKSC [0:G_N_Q*8-1] = '{" + ", ".join(f"16'sh{x[1]:04X}" for x in flatt) + "};")
    (BAG / "u6_lut.svh").write_text("\n".join(lines) + "\n", encoding="utf-8")
    (BAG / "u6_gold.svh").write_text("// alias\n`include \"u6_lut.svh\"\n", encoding="utf-8")

    print("LUT", nlut, "WR", len(wr), "Q", nq)
    for r, t in zip(qres, gold_t):
        print(r["name"], "ncand", len(r["cand_ids"]), "trunc", r["n_trunc"],
              "top", [(c["id"], c["score"]) for c in t["topk"][:3]])
    print("RESULT", result, fail)
    print("U6_HOST_GOLDEN_DONE")
    return 0 if result == "PASS" else 7


if __name__ == "__main__":
    raise SystemExit(main())
