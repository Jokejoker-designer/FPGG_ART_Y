#!/usr/bin/env python3
"""U7A-R3A: measure learned-state identity rivals. No RTL. No owner decision."""
from __future__ import annotations

import json
from collections import defaultdict
from pathlib import Path

BAG = Path(__file__).resolve().parent
BAG_T2 = BAG.parent / "U5Q-T2-FPGA-TYPE-CLASS-TABLE-00"
BAG_U6 = BAG.parent / "U6-TYPECLASS-UNIFIED-RETRIEVAL-00"
TC_PREFIX = 0x5443
LEGACY_SUBJ_EXAMPLES = [
    0x0000A000, 0x0000A001, 0x0000B000, 0x00011234, 0x00035678,
    0x000C34FF, 0x000BEEFF, 0x00FFFFF0, 0x00000039, 0x0000003A,
]


def v1_key(cid: int, ev, iv, rv, xv, eid, iid, rid, xid) -> tuple[int, int, int]:
    subj = (TC_PREFIX << 16) | (int(cid) & 0xFFFF)
    rel = ((int(xv) & 1) << 3) | ((int(rv) & 1) << 2) | ((int(iv) & 1) << 1) | (int(ev) & 1)
    obj = ((int(eid) & 0xFF) << 24) | ((int(iid) & 0xFF) << 16) | ((int(rid) & 0xFF) << 8) | (int(xid) & 0xFF)
    return subj, rel, obj


def main() -> None:
    table = json.loads((BAG_T2 / "TYPECLASS_TABLE.json").read_text(encoding="utf-8"))
    rows = table["rows"]
    gold = json.loads((BAG_U6 / "GOLDEN_TYPECLASS_CANDIDATES.json").read_text(encoding="utf-8"))
    by_cid = {int(r["class_id"]): r for r in rows}
    assert len(rows) == 443
    assert max(by_cid) == 443

    def qtuple(q: dict) -> tuple:
        return (int(q["ev"]), int(q["iv"]), int(q["rv"]), int(q["xv"]),
                int(q["eid"]), int(q["iid"]), int(q["rid"]), int(q["xid"]))

    # collapse duplicate confirmation rows that share QSE tuple (chiller vs overflow_relevant_chiller)
    gold_u = []
    seen_t = set()
    dup_names = defaultdict(list)
    for q in gold:
        t = qtuple(q)
        dup_names[t].append(q["name"])
        if t in seen_t:
            continue
        seen_t.add(t)
        gold_u.append(q)

    events = []
    for q in gold_u:
        ctx = dict(eid=q["eid"], iid=q["iid"], rid=q["rid"], xid=q["xid"],
                   ev=q["ev"], iv=q["iv"], rv=q["rv"], xv=q["xv"],
                   name=q["name"], text=q["text"], qtuple=qtuple(q))
        for cid in q["class_ids"]:
            events.append({**ctx, "class_id": int(cid)})

    # A CLASS_ONLY
    a_map = defaultdict(list)
    for e in events:
        a_map[e["class_id"]].append(e["name"])
    a_alias = {k: sorted(set(v)) for k, v in a_map.items() if len(set(v)) > 1}

    # B CLASS_CONTEXT V1
    b_map = defaultdict(list)
    for e in events:
        k = v1_key(e["class_id"], e["ev"], e["iv"], e["rv"], e["xv"],
                   e["eid"], e["iid"], e["rid"], e["xid"])
        b_map[k].append((e["name"], e["class_id"]))
    b_coll = {str(k): v for k, v in b_map.items() if len({x[0] for x in v}) > 1}

    # 58 critical
    ch58 = [e for e in events if e["class_id"] == 58]
    k58 = {}
    for e in ch58:
        k58[e["name"]] = {
            "class_only": e["class_id"],
            "class_context_v1": list(v1_key(e["class_id"], e["ev"], e["iv"], e["rv"], e["xv"],
                                            e["eid"], e["iid"], e["rid"], e["xid"])),
        }

    # injectivity over all 443 × confirmation contexts (including 0-hit queries' context)
    contexts = []
    seen_ctx = set()
    for q in gold:
        t = (q["ev"], q["iv"], q["rv"], q["xv"], q["eid"], q["iid"], q["rid"], q["xid"])
        if t not in seen_ctx:
            seen_ctx.add(t)
            contexts.append((q["name"], t))
    # also synthetic: same numeric fields, flipped mask
    synth = ("synth_mask_eid1_unbound", (0, 0, 0, 0, 1, 0, 0, 0))
    all_ctx = contexts + [synth]

    pairs = []
    for cid in range(1, 444):
        for name, t in all_ctx:
            pairs.append((cid, name, v1_key(cid, *t)))
    inv = defaultdict(list)
    for cid, name, k in pairs:
        inv[k].append((cid, name))
    v1_pair_coll = {str(k): v for k, v in inv.items() if len(set(v)) > 1}

    # namespace vs legacy
    v1_subjs = {(TC_PREFIX << 16) | cid for cid in range(1, 444)}
    ns_hit = sorted(hex(s) for s in v1_subjs.intersection(LEGACY_SUBJ_EXAMPLES))
    prefix_ok = all((s >> 16) == TC_PREFIX for s in v1_subjs)
    high_id = v1_key(427, 0, 1, 1, 0, 0, 1, 3, 0)  # exact8 last
    high_survives = (high_id[0] & 0xFFFF) == 427

    # C RAW_MEMBER: member_ptr is catalog index, not 800k NID
    member_counts = [int(r["member_count"]) for r in rows]
    ptrs = [int(r["member_ptr"]) for r in rows]
    raw = {
        "member_ptr_is": "catalog_index_of_first_member_not_800k_nid",
        "n_classes": 443,
        "min_members": min(member_counts),
        "max_members": max(member_counts),
        "sum_members": sum(member_counts),
        "unique_first_ptr": len(set(ptrs)),
        "requires_member_selection": True,
        "host_selected_if_unspecified": True,
        "same_class_diff_query_aliases_if_first_member": True,
    }

    # D LEGACY triple: graph ROM 0xA000+i / qid — no TYPE_CLASS wire
    legacy = {
        "key": "{subj[31:0],rel[7:0],obj[31:0]}",
        "graph_subj_a": "32'hA000+i",
        "reachable_from_u6_topk": False,
        "lookup_before_score": True,
        "persistence": "SchemaV2 full32 compatible",
        "collision_with_v1_prefix_0x5443": False,
    }

    # cardinality of observed retrieval (query,class) keys
    n_events = len(events)
    n_class_only = len(a_map)
    n_ctx = len(b_map)
    store_depth = 32
    unique_cids_in_gold = sorted({e["class_id"] for e in events})

    overlap_58 = {
        "chiller_has_58": any(e["name"] == "chiller" and e["class_id"] == 58 for e in events),
        "water_chiller_has_58": any(e["name"] == "water_chiller" and e["class_id"] == 58 for e in events),
        "class_only_same_key": k58.get("chiller", {}).get("class_only") == k58.get("water_chiller", {}).get("class_only"),
        "class_context_same_key": k58.get("chiller", {}).get("class_context_v1") == k58.get("water_chiller", {}).get("class_context_v1"),
    }

    # pairwise query class-set overlap
    qsets = {q["name"]: set(q["class_ids"]) for q in gold}
    overlaps = []
    names = list(qsets)
    for i, a in enumerate(names):
        for b in names[i + 1:]:
            inter = sorted(qsets[a] & qsets[b])
            if inter:
                overlaps.append({"a": a, "b": b, "n": len(inter), "ids_head": inter[:8]})

    rivals = {
        "A_CLASS_ONLY": {
            "key": "CLASS_ID",
            "identity_collisions_on_gold_events": len(a_alias),
            "credit_aliasing": "same CLASS_ID shares one prior across all retrieving queries",
            "same_class_diff_query_alias": True,
            "diff_class_same_query_alias": False,
            "host_information": "none beyond FPGA CLASS_ID stream",
            "need_member_selection": False,
            "persistence_compat": "would need new 16-bit or padded-32 key; not current triple",
            "ws_cardinality_gold_unique_ids": n_class_only,
            "lookup_prior_before_score": "yes if scorer keys by CLASS_ID only",
            "determinism": True,
            "resource": "443 classes worst-case distinct keys; store DEPTH=32 still caps live priors",
            "critical_58_aliases_chiller_and_water": overlap_58["class_only_same_key"],
        },
        "B_CLASS_CONTEXT": {
            "key": "LEARN_KEY_CLASS_CONTEXT_V1",
            "encoding": "subj={16'h5443,CLASS_ID}; rel[3:0]={xv,rv,iv,ev}; obj={eid,iid,rid,xid}",
            "identity_collisions_on_gold_events": len(b_coll),
            "credit_aliasing": "split by query bind+fields",
            "same_class_diff_query_alias": False,
            "diff_class_same_query_alias": False,
            "host_information": "none; QSE fields already FPGA-owned",
            "need_member_selection": False,
            "persistence_compat": "fits existing {subj32,rel8,obj32} SchemaV2",
            "ws_cardinality_gold_unique_keys": n_ctx,
            "lookup_prior_before_score": "yes: CLASS_ID from scan + latched QSE tuple",
            "determinism": True,
            "resource": "keys grow with (class × distinct query-contexts); store DEPTH=32 unchanged",
            "critical_58_aliases_chiller_and_water": overlap_58["class_context_same_key"],
            "injective_443_x_gold_and_synth_mask": len(v1_pair_coll) == 0,
            "legacy_namespace_collision": bool(ns_hit),
            "high_class_id_427_survives": high_survives,
            "prefix_0x5443": prefix_ok,
        },
        "C_RAW_MEMBER": raw | {
            "same_class_diff_query_alias": True,
            "diff_class_same_query_alias": False,
            "host_information": "forbidden if host picks NID; FPGA first-member is extra policy",
            "lookup_prior_before_score": "no NID in U6 CLASS_ID stream; only member_ptr of class",
            "determinism": "only after a frozen member-pick law",
            "persistence_compat": "triple would still need fabricated rel/obj or NID packing",
            "critical_58": "would credit one provenance NID for both chiller and water chiller",
        },
        "D_LEGACY_GRAPH_TRIPLE": legacy | {
            "same_class_diff_query_alias": "n/a — not TYPE_CLASS keyed",
            "host_information": "none on graph ROM path; qid[7:0] is not CLASS_ID",
            "need_member_selection": False,
            "lookup_prior_before_score": True,
            "determinism": True,
            "resource": "32-slot store as today",
            "u6_reachable": False,
        },
    }

    collision_matrix = {
        "class_only_aliased_class_ids": {str(k): v for k, v in sorted(a_alias.items())},
        "class_context_v1_event_collisions": b_coll,
        "class_context_v1_pair_collisions_443x_contexts": v1_pair_coll,
        "class_id_58": k58,
        "query_class_set_overlaps": overlaps,
        "legacy_subj_namespace_hits_vs_0x5443": ns_hit,
        "synth_mask_vs_chiller_numeric": {
            "chiller_v1_cid58": list(v1_key(58, 1, 0, 0, 0, 1, 0, 0, 0)),
            "synth_unbound_eid1_v1_cid58": list(v1_key(58, 0, 0, 0, 0, 1, 0, 0, 0)),
            "distinguishable": v1_key(58, 1, 0, 0, 0, 1, 0, 0, 0) != v1_key(58, 0, 0, 0, 0, 1, 0, 0, 0),
        },
        "unbound_all_zero_per_class_unique": True,
        "all_443_class_ids_unique": len(by_cid) == 443,
    }

    cardinality = {
        "tc_n": 443,
        "store_depth": store_depth,
        "gold_queries_raw": len(gold),
        "gold_unique_qse_tuples": len(gold_u),
        "duplicate_qse_rows": {str(k): v for k, v in dup_names.items() if len(v) > 1},
        "gold_queries": len(gold_u),
        "gold_retrieval_events": n_events,
        "unique_CLASS_ONLY_keys_on_gold": n_class_only,
        "unique_CLASS_CONTEXT_V1_keys_on_gold": n_ctx,
        "unique_class_ids_appearing_in_gold": len(unique_cids_in_gold),
        "max_cands_one_query": max(q["n"] for q in gold),
        "member_count_min": min(member_counts),
        "member_count_max": max(member_counts),
        "member_count_sum": sum(member_counts),
        "ws_32_cannot_hold_all_443": True,
        "ws_32_vs_gold_context_keys": {"keys": n_ctx, "depth": 32, "fits": n_ctx <= 32},
        "high_class_ids_in_gold": [c for c in unique_cids_in_gold if c > 255],
    }

    (BAG / "COLLISION_MATRIX.json").write_text(json.dumps(collision_matrix, indent=2), encoding="utf-8")
    (BAG / "CARDINALITY.json").write_text(json.dumps(cardinality, indent=2), encoding="utf-8")
    (BAG / "RIVALS.json").write_text(json.dumps(rivals, indent=2), encoding="utf-8")
    print("58 CLASS_ONLY alias", overlap_58)
    print("V1 event coll", len(b_coll), "pair coll", len(v1_pair_coll), "ns_hit", ns_hit)
    print("gold events", n_events, "class_only", n_class_only, "ctx", n_ctx)
    print("high ids", cardinality["high_class_ids_in_gold"][:12])


if __name__ == "__main__":
    main()
