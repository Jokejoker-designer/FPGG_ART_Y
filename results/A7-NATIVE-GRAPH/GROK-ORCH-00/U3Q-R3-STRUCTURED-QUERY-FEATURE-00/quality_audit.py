#!/usr/bin/env python3
"""U3Q-R3 held-out quality vs frozen _PREREG.md thresholds. No retarget."""
from __future__ import annotations
import json
from collections import defaultdict
from pathlib import Path
from lexicon import (
    ENTITY_CANON, INTENT_CANON, SAME_ENT_DIFF_INT, UNRELATED,
    PERTURB_BASE, ADV_SEED, ADV_N,
)
from twin import extract

TH = {
    "entity_paraphrase_id_stability": 0.85,
    "intent_paraphrase_id_stability": 0.85,
    "same_ent_entity_same": 0.85,
    "same_ent_intent_diff": 0.85,
    "unrelated_entity_collision": 0.10,
    "lexicon_perturbation_changes_entity": 0.80,
    "adversarial_entity_hit_rate": 0.20,
    "retrieval_recall_at_16": 0.80,
    "retrieval_recall_at_64": 0.85,
}


def stab_entity():
    n = h = 0
    rows = []
    for lab, forms in ENTITY_CANON.items():
        can = extract(forms[0])["entity_id"]
        for v in forms[1:]:
            got = extract(v)["entity_id"]
            n += 1
            ok = can != 0 and got == can
            h += int(ok)
            rows.append({"label": lab, "canon": forms[0], "var": v, "canon_id": can, "var_id": got, "ok": ok})
    return {"n": n, "hit": h, "rate": h / n if n else 0.0, "rows": rows}


def stab_intent():
    n = h = 0
    rows = []
    for lab, forms in INTENT_CANON.items():
        can = extract(forms[0])["intent_id"]
        for v in forms[1:]:
            got = extract(v)["intent_id"]
            n += 1
            ok = can != 0 and got == can
            h += int(ok)
            rows.append({"label": lab, "canon": forms[0], "var": v, "canon_id": can, "var_id": got, "ok": ok})
    return {"n": n, "hit": h, "rate": h / n if n else 0.0, "rows": rows}


def same_ent_diff_int():
    xs = [extract(s) for s in SAME_ENT_DIFF_INT]
    e0 = xs[0]["entity_id"]
    n = len(xs)
    e_ok = sum(1 for x in xs if e0 and x["entity_id"] == e0)
    intents = [x["intent_id"] for x in xs]
    i_diff = 1.0 if len(set(intents)) == n and all(i != 0 for i in intents) else (
        sum(1 for a, b in zip(intents, intents[1:]) if a != b and a and b) / max(n - 1, 1)
    )
    return {
        "entity_same_rate": e_ok / n,
        "intent_diff_rate": i_diff,
        "entity_ids": [x["entity_id"] for x in xs],
        "intent_ids": intents,
        "texts": SAME_ENT_DIFF_INT,
    }


def unrelated_coll():
    xs = [extract(s) for s in UNRELATED]
    n = hit = 0
    for i in range(len(xs)):
        for j in range(i + 1, len(xs)):
            n += 1
            a, b = xs[i]["entity_id"], xs[j]["entity_id"]
            if a != 0 and a == b:
                hit += 1
    return {"n": n, "hit": hit, "rate": hit / n if n else 0.0,
            "ids": list(zip(UNRELATED, [x["entity_id"] for x in xs]))}


def perturb():
    n = ch = 0
    rows = []
    for s in PERTURB_BASE:
        t = list(s.encode("ascii"))
        t[-1] = (t[-1] + 1) & 0xFF
        if t[-1] == 0:
            t[-1] = 1
        p = bytes(t).decode("latin1")
        a, b = extract(s)["entity_id"], extract(p)["entity_id"]
        n += 1
        ok = a != b
        ch += int(ok)
        rows.append({"base": s, "pert": p, "base_id": a, "pert_id": b, "changed": ok})
    return {"n": n, "changed": ch, "rate": ch / n if n else 0.0, "rows": rows}


def adversarial():
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
    hits = 0
    rows = []
    for t in texts:
        e = extract(t)["entity_id"]
        hits += int(e != 0)
        rows.append({"text": t, "entity_id": e})
    return {"n": len(texts), "hits": hits, "rate": hits / len(texts), "rows": rows}


def sentinel():
    a = extract(bytes([0xC3, 0x4F, 0xFF]).decode("latin1"))
    b = extract("799999")
    return {"c34ff_entity": a["entity_id"], "ascii799999_entity": b["entity_id"],
            "ok": a["entity_id"] == 0 and b["entity_id"] == 0}


def retrieval():
    docs = []
    for lab, forms in ENTITY_CANON.items():
        for s in forms:
            docs.append({"label": lab, "text": s, "eid": extract(s)["entity_id"]})
    def rec_at(k: int) -> float:
        rs = []
        for i, q in enumerate(docs):
            gold = {j for j, d in enumerate(docs) if d["label"] == q["label"] and j != i}
            if not gold:
                continue
            got = []
            for j, d in enumerate(docs):
                if j == i:
                    continue
                if q["eid"] != 0 and d["eid"] == q["eid"]:
                    got.append(j)
            rs.append(len(gold.intersection(got[:k])) / len(gold))
        return sum(rs) / len(rs) if rs else 0.0
    return {"n_docs": len(docs), "recall_at_16": rec_at(16), "recall_at_64": rec_at(64)}


def packing_law():
    x = extract("install chiller")
    k0_ok = x["k0"] == ((x["entity_id"] << 8) | x["intent_id"])
    k1_ok = x["k1"] == ((x["relation_id"] << 8) | x["context_id"])
    crc_unused = x["k0"] != x["crc16_dbg"] and x["k1"] != x["crc16_dbg"]
    same = extract("install chiller") == x
    return {"k0_ok": k0_ok, "k1_ok": k1_ok, "crc_unused_in_k0k1": crc_unused, "same_in_same_out": same, "sample": x}


def main():
    bag = Path(__file__).resolve().parent
    ent = stab_entity()
    inten = stab_intent()
    se = same_ent_diff_int()
    un = unrelated_coll()
    pe = perturb()
    adv = adversarial()
    sen = sentinel()
    retr = retrieval()
    pack = packing_law()

    fails = []
    def chk(name, ok, detail):
        if not ok:
            fails.append({"metric": name, "detail": detail})

    chk("same_in_same_out", pack["same_in_same_out"], pack)
    chk("k0_pack", pack["k0_ok"], pack)
    chk("k1_pack", pack["k1_ok"], pack)
    chk("crc_unused", pack["crc_unused_in_k0k1"], pack)
    chk("entity_paraphrase", ent["rate"] >= TH["entity_paraphrase_id_stability"], ent["rate"])
    chk("intent_paraphrase", inten["rate"] >= TH["intent_paraphrase_id_stability"], inten["rate"])
    chk("same_ent_entity", se["entity_same_rate"] >= TH["same_ent_entity_same"], se)
    chk("same_ent_intent", se["intent_diff_rate"] >= TH["same_ent_intent_diff"], se)
    chk("unrelated", un["rate"] <= TH["unrelated_entity_collision"], un["rate"])
    chk("perturb", pe["rate"] >= TH["lexicon_perturbation_changes_entity"], pe["rate"])
    chk("adversarial", adv["rate"] <= TH["adversarial_entity_hit_rate"], adv["rate"])
    chk("sentinel", sen["ok"], sen)
    chk("recall16", retr["recall_at_16"] >= TH["retrieval_recall_at_16"], retr)
    chk("recall64", retr["recall_at_64"] >= TH["retrieval_recall_at_64"], retr)
    chk("n_host", pack["sample"]["n_host"] == 0, pack["sample"]["n_host"])

    out = {
        "gate": "U3Q-R3-STRUCTURED-QUERY-FEATURE-00",
        "law": "qse-v1-lexicon-hdc-00",
        "thresholds": TH,
        "packing": pack,
        "entity_paraphrase": {k: ent[k] for k in ("n", "hit", "rate")},
        "entity_rows": ent["rows"],
        "intent_paraphrase": {k: inten[k] for k in ("n", "hit", "rate")},
        "intent_rows": inten["rows"],
        "same_entity_diff_intent": se,
        "unrelated": un,
        "perturbation": pe,
        "adversarial": adv,
        "sentinel": sen,
        "retrieval": retr,
        "fails": fails,
        "verdict": "FAIL" if fails else "PASS",
        "first_divergence": fails[0]["metric"] if fails else None,
        "crc_is_not_route_authority": True,
        "host_semantic": False,
    }
    (bag / "METRICS.json").write_text(json.dumps(out, indent=2), encoding="utf-8")
    print("ENTITY", ent["rate"], "INTENT", inten["rate"])
    print("SAME_ENT", se)
    print("UNRELATED", un["rate"], "PERTURB", pe["rate"], "ADV", adv["rate"])
    print("SENTINEL", sen, "RETR", retr)
    print("PACK", {k: pack[k] for k in pack if k != "sample"})
    if fails:
        print("FIRST_DIVERGENCE", fails[0]["metric"], fails[0]["detail"])
        print("U3Q_R3_FAIL")
        (bag / "FIRST_DIVERGENCE.md").write_text(
            f"# FIRST_DIVERGENCE\n\nmetric={fails[0]['metric']}\n\n{json.dumps(fails, indent=2)}\n",
            encoding="utf-8",
        )
        raise SystemExit(2)
    print("U3Q_R3_QUALITY_PASS")


if __name__ == "__main__":
    main()
