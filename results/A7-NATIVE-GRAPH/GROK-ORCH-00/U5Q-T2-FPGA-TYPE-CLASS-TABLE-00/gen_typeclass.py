#!/usr/bin/env python3
"""Freeze TYPE_CLASS table + CLASS_ID map. Not NID-derived."""
from __future__ import annotations

import hashlib
import json
from collections import defaultdict
from pathlib import Path

BAG = Path(__file__).resolve().parent
BAG_U5Q = BAG.parent / "U5Q-M10-RETRIEVAL-QUALITY-SCALE-CLOSURE-00"
import sys
sys.path.insert(0, str(BAG_U5Q))
import host_u5q as u5q  # noqa: E402


def class_key(f: dict) -> tuple:
    return (int(f["eid"]), int(f["iid"]), int(f["rid"]), int(f["xid"]))


def sha_bytes(b: bytes) -> str:
    return hashlib.sha256(b).hexdigest().upper()


def main() -> None:
    catalog = u5q.registered_catalog()
    feats = [u5q.feat(t) for t in catalog]
    groups: dict[tuple, list[int]] = defaultdict(list)
    for i, f in enumerate(feats):
        groups[class_key(f)].append(i)
    keys = sorted(groups.keys())
    rows = []
    mapping_lines = []
    for rank, ck in enumerate(keys):
        cid = 1 + rank
        members = groups[ck]
        rows.append({
            "class_id": cid,
            "eid": ck[0], "iid": ck[1], "rid": ck[2], "xid": ck[3],
            "member_ptr": members[0],
            "member_count": len(members),
        })
        mapping_lines.append("%d\t%d\t%d\t%d\t%d\t%d\t%d\n" % (
            cid, ck[0], ck[1], ck[2], ck[3], members[0], len(members)))
    table_blob = json.dumps(rows, sort_keys=True, separators=(",", ":")).encode()
    map_blob = "".join(mapping_lines).encode()
    table_sha = sha_bytes(table_blob)
    map_sha = sha_bytes(map_blob)

    qrows = u5q.query_list("confirm")
    gold = []
    for name, text in qrows:
        q = u5q.feat(text)
        hits = []
        qb = u5q.bound_slots(q)
        for r in rows:
            if not qb:
                continue
            rec = {"eid": r["eid"], "iid": r["iid"], "rid": r["rid"], "xid": r["xid"]}
            if all(rec[k] == v for k, v in qb.items()):
                hits.append(r["class_id"])
        gold.append({
            "name": name, "text": text,
            "eid": q["eid"], "iid": q["iid"], "rid": q["rid"], "xid": q["xid"],
            "ev": int(q["eid"] != 0), "iv": int(q["iid"] != 0),
            "rv": int(q["rid"] != 0), "xv": int(q["xid"] != 0),
            "class_ids": hits, "n": len(hits),
        })

    meta = {
        "n_rows": len(rows),
        "class_id_w": 16,
        "class_id_first": rows[0]["class_id"] if rows else 0,
        "class_id_last": rows[-1]["class_id"] if rows else 0,
        "TYPECLASS_TABLE_SHA256": table_sha,
        "CLASS_ID_MAPPING_SHA256": map_sha,
        "nid_derived": False,
    }
    (BAG / "TYPECLASS_TABLE.json").write_text(json.dumps({"meta": meta, "rows": rows}, indent=2), encoding="utf-8")
    (BAG / "CLASS_ID_MAPPING.txt").write_text("".join(mapping_lines), encoding="utf-8")
    (BAG / "T1_GOLDEN_CLASS_IDS.json").write_text(json.dumps(gold, indent=2), encoding="utf-8")
    (BAG / "FREEZE.json").write_text(json.dumps(meta, indent=2), encoding="utf-8")

    # svh ROM
    n = len(rows)
    lines = [
        "// generated gen_typeclass.py — TYPE_CLASS catalog. CLASS_ID not from NID.",
        f"localparam int unsigned TC_N = {n};",
        "localparam int unsigned TC_ID_W = 16;",
        "localparam int unsigned TC_CAP = 64;",
        f"localparam logic [15:0] TC_ID [0:TC_N-1] = '{{" + ", ".join("16'd%d" % r["class_id"] for r in rows) + "};",
        f"localparam logic [7:0] TC_EID [0:TC_N-1] = '{{" + ", ".join("8'd%d" % r["eid"] for r in rows) + "};",
        f"localparam logic [7:0] TC_IID [0:TC_N-1] = '{{" + ", ".join("8'd%d" % r["iid"] for r in rows) + "};",
        f"localparam logic [7:0] TC_RID [0:TC_N-1] = '{{" + ", ".join("8'd%d" % r["rid"] for r in rows) + "};",
        f"localparam logic [7:0] TC_XID [0:TC_N-1] = '{{" + ", ".join("8'd%d" % r["xid"] for r in rows) + "};",
        f"localparam logic [15:0] TC_MPTR [0:TC_N-1] = '{{" + ", ".join("16'd%d" % r["member_ptr"] for r in rows) + "};",
        f"localparam logic [15:0] TC_MCNT [0:TC_N-1] = '{{" + ", ".join("16'd%d" % r["member_count"] for r in rows) + "};",
    ]
    # golden for TB
    nq = len(gold)
    maxh = max((g["n"] for g in gold), default=1)
    flat = []
    for g in gold:
        ids = g["class_ids"] + [0] * (maxh - len(g["class_ids"]))
        flat.extend(ids)
    lines.append(f"localparam int TC_NQ = {nq};")
    lines.append(f"localparam int TC_MAXH = {maxh};")
    lines.append("localparam int TC_NEXP [0:TC_NQ-1] = '{" + ", ".join(str(g["n"]) for g in gold) + "};")
    lines.append("localparam logic [7:0] TC_QE [0:TC_NQ-1] = '{" + ", ".join("8'd%d" % g["eid"] for g in gold) + "};")
    lines.append("localparam logic [7:0] TC_QI [0:TC_NQ-1] = '{" + ", ".join("8'd%d" % g["iid"] for g in gold) + "};")
    lines.append("localparam logic [7:0] TC_QR [0:TC_NQ-1] = '{" + ", ".join("8'd%d" % g["rid"] for g in gold) + "};")
    lines.append("localparam logic [7:0] TC_QX [0:TC_NQ-1] = '{" + ", ".join("8'd%d" % g["xid"] for g in gold) + "};")
    lines.append("localparam logic TC_EV [0:TC_NQ-1] = '{" + ", ".join(str(g["ev"]) for g in gold) + "};")
    lines.append("localparam logic TC_IV [0:TC_NQ-1] = '{" + ", ".join(str(g["iv"]) for g in gold) + "};")
    lines.append("localparam logic TC_RV [0:TC_NQ-1] = '{" + ", ".join(str(g["rv"]) for g in gold) + "};")
    lines.append("localparam logic TC_XV [0:TC_NQ-1] = '{" + ", ".join(str(g["xv"]) for g in gold) + "};")
    lines.append("localparam logic [15:0] TC_EXP [0:TC_NQ*TC_MAXH-1] = '{" + ", ".join("16'd%d" % x for x in flat) + "};")
    # query texts as bytes for QSE path
    def pack_text(t: str) -> tuple[int, str]:
        b = t.encode("latin1")[:48]
        v = 0
        for i, x in enumerate(b):
            v |= x << (8 * i)
        return len(b), f"{v:096X}"
    lens, hexes = zip(*(pack_text(g["text"]) for g in gold))
    lines.append("localparam int TC_QLEN [0:TC_NQ-1] = '{" + ", ".join(str(x) for x in lens) + "};")
    lines.append("localparam logic [8*48-1:0] TC_QBYTES [0:TC_NQ-1] = '{" + ", ".join("384'h"+h for h in hexes) + "};")
    (BAG / "typeclass_table.svh").write_text("\n".join(lines) + "\n", encoding="utf-8")
    print("N", len(rows), "first", rows[0]["class_id"], "last", rows[-1]["class_id"])
    print("TABLE_SHA", table_sha)
    print("MAP_SHA", map_sha)
    for g in gold:
        print(g["name"], g["n"], g["class_ids"][:8])


if __name__ == "__main__":
    main()
