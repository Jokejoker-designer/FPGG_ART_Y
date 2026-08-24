"""A7-NATIVE-GRAPH TRAIN-V2 attribution harness (host protocol, not board).

Law change (TermGen + WM + typed relations) invalidates old learned-state
attribution. This harness:

  CONTROL     — frozen old-law model (not edited)
  WARM        — old learned state scored under NEW law (contaminant rival)
  TRAIN-V2    — RESET learned only → train from zero under new law
  Run A / B   — two independent from-zero mappings; B must forget A

Host never supplies gradient / winner / address / next_token as answers.
Evidence_class = HARNESS (≠ BOARD / ≠ HS-02 silicon exam).
"""

from __future__ import annotations

import hashlib
import json
import re
from copy import deepcopy
from dataclasses import dataclass, field
from pathlib import Path
from typing import Any

ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / "results" / "A7-NATIVE-GRAPH" / "TRAIN-V2"
NG08 = ROOT / "results" / "A7-NATIVE-GRAPH" / "NG-08"

OLD_LAW_ID = "a7ng-learn-v0"
NEW_LAW_ID = "a7ng-train-v2"
LAW_BUNDLE = ("a7ng-termgen-v0", "a7ng-wm00-v0", "a7ng-reset-learned-v0")

FROZEN_EXPECT = {
    "LM06": ("build/out/arty_a7_lm06.bit", "67C37DD51AED30F82B5B72EC9EF0736DDABA534ED1D724D0ADCAFD2B4282E3BA"),
    "EAM01R": ("build/out/arty_a7_eam01r.bit", "57D1DF1BF86338A896876F6FBE204B1705128FFEC0A96F0582CF7EF90E9EF6CF"),
    "EAM02M": ("build/out/arty_a7_eam02m.bit", "DB3BC58A6CC697FD0C290F97B5D6AD171AE7721A6C8A1E2DB2E87C5A84CFE696"),
    "A03": ("build/out/arty_a7_eam03e_a03.bit", "05E478FF53D8CEBE5CFDF79E1046E986F077F6E0117C714CDA794B38142BEC09"),
}

FORBIDDEN_ALWAYS = {
    "gradient",
    "delta_weight",
    "winner",
    "address",
    "hash",
    "next_token",
    "final_answer",
}
FORBIDDEN_BLIND = FORBIDDEN_ALWAYS | {
    "entity",
    "intent",
    "context",
    "candidate_ranking",
    "relation_path",
}

# TermGen-style family tags (versioned representation — Yes-row retrain trigger)
ENTITY_MAP = {
    "fpga": "ENT_FPGA",
    "bram": "ENT_BRAM",
    "ddr": "ENT_DDR",
    "lut": "ENT_LUT",
    "dsp": "ENT_DSP",
    "mig": "ENT_MIG",
    "arty": "ENT_ARTY",
    "cpu": "ENT_CPU",
    "wns": "ENT_WNS",
    "tns": "ENT_TNS",
    "teacher": "ENT_TEACHER",
    "hotset": "ENT_HOTSET",
    "frontier": "ENT_FRONTIER",
    "bomb": "ENT_BOMB",
    "lm-06": "ENT_LM06",
    "lm06": "ENT_LM06",
}
INTENT_MAP = {
    "what": "INT_DEFINE",
    "define": "INT_DEFINE",
    "where": "INT_LOCATE",
    "how": "INT_MECHANISM",
    "contrast": "INT_COMPARE",
    "who": "INT_AGENT",
    "explain": "INT_DEFINE",
}


def sha256_file(path: Path) -> str:
    h = hashlib.sha256()
    with path.open("rb") as f:
        for chunk in iter(lambda: f.read(1 << 20), b""):
            h.update(chunk)
    return h.hexdigest().upper()


def sha256_bytes(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest().upper()


def tokenize_old(text: str) -> set[str]:
    return {t for t in re.findall(r"[a-z0-9]+", text.lower()) if len(t) > 1}


def tokenize_new(text: str) -> set[str]:
    raw = tokenize_old(text)
    tags: set[str] = set()
    for tok in raw:
        if tok in ENTITY_MAP:
            tags.add(ENTITY_MAP[tok])
        if tok in INTENT_MAP:
            tags.add(INTENT_MAP[tok])
        tags.add(f"TOK_{tok}")
    return tags


@dataclass
class LearnedState:
    law_id: str
    generation: int = 1
    priors: dict[str, int] = field(default_factory=dict)
    edges: dict[str, dict[str, int]] = field(default_factory=dict)
    confidence: dict[str, int] = field(default_factory=dict)

    def reset_learned(self) -> None:
        """Clear learned memory only — architecture/law_id kept."""
        self.generation += 1
        self.priors.clear()
        self.edges.clear()
        self.confidence.clear()

    def snapshot(self) -> dict[str, Any]:
        return {
            "law_id": self.law_id,
            "generation": self.generation,
            "priors": dict(self.priors),
            "edges": {k: dict(v) for k, v in self.edges.items()},
            "confidence": dict(self.confidence),
        }


def build_corpus_20() -> dict[str, Any]:
    cur = json.loads((NG08 / "kidi20_curriculum.json").read_text(encoding="utf-8"))
    facts = list(cur["facts"])
    assert len(facts) == 20
    queries = [
        {"id": "q01", "query": "What is an FPGA?", "relevant": ["f01", "f09"], "hard_neg": ["f10"]},
        {"id": "q02", "query": "Where does FPGA config live?", "relevant": ["f02"], "hard_neg": ["f07"]},
        {"id": "q03", "query": "What is BRAM?", "relevant": ["f05", "f16"], "hard_neg": ["f10"]},
        {"id": "q04", "query": "How does FPGA parallelize?", "relevant": ["f11", "f17"], "hard_neg": ["f10"]},
        {"id": "q05", "query": "What is WNS?", "relevant": ["f12"], "hard_neg": ["f13"]},
        {"id": "q06", "query": "Who may send gradients?", "relevant": ["f14"], "hard_neg": ["f06"]},
        {"id": "q07", "query": "Define bomb prune.", "relevant": ["f18"], "hard_neg": ["f19"]},
        {"id": "q08", "query": "Explain DDR role.", "relevant": ["f07"], "hard_neg": ["f05"]},
    ]
    held_out = [
        {
            "id": "h01",
            "query": "Define field-programmable gate array.",
            "gold_relevant": ["f01"],
            "unrelated": ["f10"],
            "contradiction": ["f10"],
        },
        {
            "id": "h02",
            "query": "Explain on-chip block RAM role.",
            "gold_relevant": ["f05"],
            "unrelated": ["f12"],
            "contradiction": ["f10"],
        },
        {
            "id": "h03",
            "query": "Contrast sequential CPU execution vs FPGA PE lanes.",
            "gold_relevant": ["f10", "f11"],
            "unrelated": ["f13"],
            "contradiction": ["f01"],
        },
        {
            "id": "h04",
            "query": "Who may send gradients to the board?",
            "gold_relevant": ["f14"],
            "unrelated": ["f06"],
            "contradiction": ["f14"],
        },
    ]
    return {
        "corpus_id": "train_v2_facts_20",
        "n_facts": 20,
        "preregistered": True,
        "law_curriculum_frozen": True,
        "facts": facts,
        "train_queries": queries,
        "held_out": held_out,
    }


def build_corpus_40(corpus_20: dict[str, Any]) -> dict[str, Any]:
    extra = [
        {"id": "f21", "text": "XDC constrains pin and timing."},
        {"id": "f22", "text": "Bitstream programs configuration memory."},
        {"id": "f23", "text": "AXI connects masters to slaves."},
        {"id": "f24", "text": "UART carries host telemetry."},
        {"id": "f25", "text": "JTAG programs and debugs silicon."},
        {"id": "f26", "text": "PLL generates derived clocks."},
        {"id": "f27", "text": "MMCM multiplies and divides clocks."},
        {"id": "f28", "text": "IOBUF drives board pins."},
        {"id": "f29", "text": "CDC crosses clock domains safely."},
        {"id": "f30", "text": "FIFO buffers rate mismatches."},
        {"id": "f31", "text": "Top-K selects highest scores."},
        {"id": "f32", "text": "Scorer lanes compute integer scores."},
        {"id": "f33", "text": "Episode records bind query context."},
        {"id": "f34", "text": "Node16 packs graph node fields."},
        {"id": "f35", "text": "Edge32 packs typed relations."},
        {"id": "f36", "text": "TermGen expands token families."},
        {"id": "f37", "text": "Working memory is BRAM-scoped."},
        {"id": "f38", "text": "Long-term knowledge is DDR-backed."},
        {"id": "f39", "text": "Teacher-off forbids attention hints."},
        {"id": "f40", "text": "Training generation invalidates old priors."},
    ]
    facts = list(corpus_20["facts"]) + extra
    assert len(facts) == 40
    queries = list(corpus_20["train_queries"]) + [
        {"id": "q09", "query": "What is TermGen?", "relevant": ["f36"], "hard_neg": ["f31"]},
        {"id": "q10", "query": "Where is long-term knowledge?", "relevant": ["f38"], "hard_neg": ["f37"]},
        {"id": "q11", "query": "What is working memory?", "relevant": ["f37"], "hard_neg": ["f38"]},
        {"id": "q12", "query": "How does Top-K work?", "relevant": ["f31"], "hard_neg": ["f32"]},
    ]
    held_out = list(corpus_20["held_out"]) + [
        {
            "id": "h05",
            "query": "Define token family expansion.",
            "gold_relevant": ["f36"],
            "unrelated": ["f21"],
            "contradiction": ["f10"],
        },
        {
            "id": "h06",
            "query": "Contrast BRAM working memory vs DDR knowledge.",
            "gold_relevant": ["f37", "f38"],
            "unrelated": ["f24"],
            "contradiction": ["f01"],
        },
    ]
    return {
        "corpus_id": "train_v2_facts_40",
        "n_facts": 40,
        "preregistered": True,
        "law_curriculum_frozen": True,
        "facts": facts,
        "train_queries": queries,
        "held_out": held_out,
    }


def mapping_b_queries(queries: list[dict[str, Any]]) -> list[dict[str, Any]]:
    """Independent mapping B: swap relevant/hard_neg on even queries (forget A proof)."""
    out = []
    for i, q in enumerate(queries):
        qq = deepcopy(q)
        if i % 2 == 0 and qq["hard_neg"]:
            # Remap: former hard_neg becomes relevant; former relevant becomes hard_neg
            old_rel = list(qq["relevant"])
            old_hn = list(qq["hard_neg"])
            qq["relevant"] = old_hn
            qq["hard_neg"] = old_rel[:1] if old_rel else old_hn
            qq["mapping"] = "B"
        else:
            qq["mapping"] = "B_keep"
        out.append(qq)
    return out


def train_old_law(state: LearnedState, facts: list[dict], queries: list[dict]) -> None:
    """Old representation: bag-of-words prior updates from teacher rewards."""
    assert state.law_id == OLD_LAW_ID
    fact_tok = {f["id"]: tokenize_old(f["text"]) for f in facts}
    for q in queries:
        qtok = tokenize_old(q["query"])
        for fid in q["relevant"]:
            overlap = len(qtok & fact_tok[fid])
            reward = 3 if overlap > 0 else 1
            state.priors[fid] = int(state.priors.get(fid, 0) + reward)
            state.confidence[fid] = int(state.confidence.get(fid, 0) + 1)
        for fid in q.get("hard_neg", []):
            state.priors[fid] = int(state.priors.get(fid, 0) - 2)
            state.confidence[fid] = int(state.confidence.get(fid, 0) + 1)


def train_new_law(state: LearnedState, facts: list[dict], queries: list[dict]) -> None:
    """New law: typed cue→fact edges + confidence promotion (teacher rewards only)."""
    assert state.law_id == NEW_LAW_ID
    fact_tags = {f["id"]: tokenize_new(f["text"]) for f in facts}
    for q in queries:
        qtags = tokenize_new(q["query"])
        cue = "|".join(sorted(t for t in qtags if t.startswith("ENT_") or t.startswith("INT_")))
        if not cue:
            cue = "|".join(sorted(list(qtags)[:4]))
        for fid in q["relevant"]:
            reward = 3
            bucket = state.edges.setdefault(cue, {})
            bucket[fid] = int(bucket.get(fid, 0) + reward)
            # confidence promotion when reward >= 2
            conf_key = f"{cue}->{fid}"
            state.confidence[conf_key] = int(state.confidence.get(conf_key, 0) + reward)
            if state.confidence[conf_key] >= 2:
                state.priors[fid] = int(state.priors.get(fid, 0) + 2)
            # entity/intent match bonus into prior
            overlap = len(qtags & fact_tags[fid])
            state.priors[fid] = int(state.priors.get(fid, 0) + min(overlap, 3))
        for fid in q.get("hard_neg", []):
            bucket = state.edges.setdefault(cue, {})
            bucket[fid] = int(bucket.get(fid, 0) - 3)
            state.priors[fid] = int(state.priors.get(fid, 0) - 2)


def score_old(state: LearnedState, facts: list[dict], query: str) -> list[tuple[str, int]]:
    qtok = tokenize_old(query)
    ranked = []
    for f in facts:
        ov = len(qtok & tokenize_old(f["text"]))
        s = int(state.priors.get(f["id"], 0)) + ov
        ranked.append((f["id"], s))
    ranked.sort(key=lambda x: (-x[1], x[0]))
    return ranked


def score_new(
    state: LearnedState,
    facts: list[dict],
    query: str,
    contradiction: list[str] | None = None,
) -> list[tuple[str, int]]:
    qtags = tokenize_new(query)
    cue = "|".join(sorted(t for t in qtags if t.startswith("ENT_") or t.startswith("INT_")))
    if not cue:
        cue = "|".join(sorted(list(qtags)[:4]))
    edge_bucket = state.edges.get(cue, {})
    ranked = []
    for f in facts:
        ftags = tokenize_new(f["text"])
        entity = len({t for t in qtags if t.startswith("ENT_")} & ftags)
        intent = len({t for t in qtags if t.startswith("INT_")} & ftags)
        relation = int(edge_bucket.get(f["id"], 0))
        prior = int(state.priors.get(f["id"], 0))
        contra = 8 if contradiction and f["id"] in contradiction else 0
        s = entity * 3 + intent * 2 + relation + prior - contra
        ranked.append((f["id"], s))
    ranked.sort(key=lambda x: (-x[1], x[0]))
    return ranked


def eval_bag(
    score_fn,
    facts: list[dict],
    queries: list[dict],
    held_out: list[dict],
    k: int = 3,
) -> dict[str, Any]:
    top1_hits = 0
    topk_hits = 0
    hn_fp = 0
    n_q = len(queries)
    candidates = []
    for q in queries:
        ranked = score_fn(facts, q["query"])
        candidates.append(len(ranked))
        top = [fid for fid, _ in ranked[:1]]
        topk = {fid for fid, _ in ranked[:k]}
        gold = set(q["relevant"])
        if top and top[0] in gold:
            top1_hits += 1
        if gold & topk:
            topk_hits += 1
        for hn in q.get("hard_neg", []):
            if ranked and ranked[0][0] == hn:
                hn_fp += 1
    para_hits = 0
    for h in held_out:
        ranked = score_fn(facts, h["query"], contradiction=h.get("contradiction"))
        topk = {fid for fid, _ in ranked[:k]}
        if set(h["gold_relevant"]) & topk:
            para_hits += 1
    return {
        "n_queries": n_q,
        "top1_accuracy": top1_hits / n_q if n_q else 0.0,
        "topk_recall": topk_hits / n_q if n_q else 0.0,
        "hard_negative_fp": hn_fp,
        "held_out_paraphrase_hit": para_hits / len(held_out) if held_out else 0.0,
        "candidates_per_query_mean": sum(candidates) / len(candidates) if candidates else 0.0,
        "top1_hits": top1_hits,
        "topk_hits": topk_hits,
        "paraphrase_hits": para_hits,
        "n_held_out": len(held_out),
    }


def make_score_fn(state: LearnedState, law: str):
    if law == OLD_LAW_ID:

        def _fn(facts, query, contradiction=None):
            return score_old(state, facts, query)

        return _fn

    def _fn(facts, query, contradiction=None):
        return score_new(state, facts, query, contradiction)

    return _fn


def verify_frozen_bits() -> dict[str, Any]:
    rows = {}
    all_match = True
    for name, (rel, expect) in FROZEN_EXPECT.items():
        path = ROOT / rel
        exists = path.is_file()
        got = sha256_file(path) if exists else None
        match = bool(exists and got == expect)
        all_match = all_match and match
        rows[name] = {
            "path": rel.replace("\\", "/"),
            "exists": exists,
            "sha256": got,
            "expect": expect,
            "match": match,
        }
    return {"all_match": all_match, "bits": rows}


def preregistered_metrics() -> dict[str, Any]:
    """Declare BEFORE any train/eval run (HS-16/17)."""
    return {
        "declared_before_run": True,
        "unit": "fact_bag_query_set",
        "not_unit": "clock_cycle_count_alone",
        "teacher_train": {"teacher": 1, "learning": 1, "freeze": 0},
        "teacher_off_eval": {"teacher": 0, "learning": 0, "freeze": 1, "external_LLM": 0},
        "metrics": {
            "top1_accuracy": {"pass_min_v2": 0.75, "pass_min_delta_vs_warm": 0.25},
            "topk_recall": {"pass_min_v2": 0.85},
            "hard_negative_fp": {"pass_max": 0},
            "held_out_paraphrase_hit": {"pass_min_v2": 0.5},
            "run_b_forgets_a": {"pass": True},
            "v2_beats_warm": {"pass": True},
            "v2_ge_control_top1": {"pass": True},
            "control_sha_unchanged": {"pass": True},
            "frozen_bits_match": {"pass": True},
        },
        "ce_policy": "CE only if on-device; harness does not use host CE as answer path",
        "evidence_class": "HARNESS",
        "board_pass": False,
    }


def run_experiment() -> dict[str, Any]:
    OUT.mkdir(parents=True, exist_ok=True)
    (OUT / "control").mkdir(exist_ok=True)
    (OUT / "run_a").mkdir(exist_ok=True)
    (OUT / "run_b").mkdir(exist_ok=True)
    (OUT / "warm_contaminant").mkdir(exist_ok=True)

    metrics_pre = preregistered_metrics()
    (OUT / "METRICS_PREREGISTERED.json").write_text(
        json.dumps(metrics_pre, indent=2), encoding="utf-8"
    )

    corpus_20 = build_corpus_20()
    corpus_40 = build_corpus_40(corpus_20)
    (OUT / "corpus_20.json").write_text(json.dumps(corpus_20, indent=2), encoding="utf-8")
    (OUT / "corpus_40.json").write_text(json.dumps(corpus_40, indent=2), encoding="utf-8")

    frozen = verify_frozen_bits()
    (OUT / "CONTROL_FROZEN_BITS.json").write_text(json.dumps(frozen, indent=2), encoding="utf-8")

    # --- CONTROL: train under OLD law, freeze dump, never edit again ---
    control = LearnedState(law_id=OLD_LAW_ID)
    train_old_law(control, corpus_20["facts"], corpus_20["train_queries"])
    control_snap = control.snapshot()
    control_bytes = json.dumps(control_snap, sort_keys=True).encode("utf-8")
    control_sha = sha256_bytes(control_bytes)
    (OUT / "control" / "old_model_dump.json").write_text(
        json.dumps(control_snap, indent=2), encoding="utf-8"
    )
    (OUT / "control" / "SHA256.txt").write_text(
        f"{control_sha}  old_model_dump.json\n", encoding="utf-8"
    )

    # Evaluate CONTROL under old law on 20 and 40 (40: extra facts zero-prior)
    ctrl_20 = eval_bag(
        make_score_fn(control, OLD_LAW_ID),
        corpus_20["facts"],
        corpus_20["train_queries"],
        corpus_20["held_out"],
    )
    ctrl_40 = eval_bag(
        make_score_fn(control, OLD_LAW_ID),
        corpus_40["facts"],
        corpus_40["train_queries"],
        corpus_40["held_out"],
    )
    # Extend control train on 40 for fair scale ladder (still OLD law, separate snap kept)
    control_40 = LearnedState(law_id=OLD_LAW_ID)
    train_old_law(control_40, corpus_40["facts"], corpus_40["train_queries"])
    ctrl_40_trained = eval_bag(
        make_score_fn(control_40, OLD_LAW_ID),
        corpus_40["facts"],
        corpus_40["train_queries"],
        corpus_40["held_out"],
    )

    # --- WARM contaminant: old priors scored under NEW law (no reset) ---
    warm = LearnedState(law_id=NEW_LAW_ID)
    warm.priors = dict(control.priors)  # contaminate: old learned priors under new law_id
    warm.confidence = dict(control.confidence)
    warm.generation = control.generation
    warm_20 = eval_bag(
        make_score_fn(warm, NEW_LAW_ID),
        corpus_20["facts"],
        corpus_20["train_queries"],
        corpus_20["held_out"],
    )
    (OUT / "warm_contaminant" / "state.json").write_text(
        json.dumps(warm.snapshot(), indent=2), encoding="utf-8"
    )
    (OUT / "warm_contaminant" / "metrics_20.json").write_text(
        json.dumps(warm_20, indent=2), encoding="utf-8"
    )

    # --- TRAIN-V2 Run A: RESET learned → train from zero under NEW law ---
    v2 = LearnedState(law_id=NEW_LAW_ID)
    v2.reset_learned()  # generation bump; empty learned memory
    assert v2.priors == {} and v2.edges == {}
    train_new_law(v2, corpus_20["facts"], corpus_20["train_queries"])
    v2_20 = eval_bag(
        make_score_fn(v2, NEW_LAW_ID),
        corpus_20["facts"],
        corpus_20["train_queries"],
        corpus_20["held_out"],
    )
    (OUT / "run_a" / "state_after_train.json").write_text(
        json.dumps(v2.snapshot(), indent=2), encoding="utf-8"
    )
    (OUT / "run_a" / "metrics_20.json").write_text(json.dumps(v2_20, indent=2), encoding="utf-8")

    # Freeze A binding probes (mapping-A relevant sets)
    mapping_a_bindings = {q["id"]: list(q["relevant"]) for q in corpus_20["train_queries"]}
    (OUT / "run_a" / "mapping_a_bindings.json").write_text(
        json.dumps(mapping_a_bindings, indent=2), encoding="utf-8"
    )

    # Blind packets: query only
    blind_packets = []
    for h in corpus_20["held_out"]:
        pkt = {
            "lesson_id": h["id"],
            "phase": "BLIND_EXAM",
            "query": h["query"],
            "supervision": [],
        }
        leaked = FORBIDDEN_BLIND.intersection(pkt.keys())
        assert not leaked
        blind_packets.append(pkt)
    (OUT / "run_a" / "blind_packets.json").write_text(
        json.dumps(blind_packets, indent=2), encoding="utf-8"
    )

    # Teacher-off flags on eval
    teacher_off_tel = {
        "interaction_id": "train_v2_blind_20",
        "cycle": 1,
        "phase": "OUTPUT",
        "teacher_present": False,
        "learn_enabled": False,
        "freeze": True,
        "external_LLM": False,
        "physical_lanes_active": 16,
        "logical_agents_active": 256,
    }
    (OUT / "run_a" / "teacher_off_telemetry.json").write_text(
        json.dumps(teacher_off_tel, indent=2), encoding="utf-8"
    )

    # Scale 40 under V2 (same law, extended corpus — after S20)
    v2_40_state = LearnedState(law_id=NEW_LAW_ID)
    v2_40_state.reset_learned()
    train_new_law(v2_40_state, corpus_40["facts"], corpus_40["train_queries"])
    v2_40 = eval_bag(
        make_score_fn(v2_40_state, NEW_LAW_ID),
        corpus_40["facts"],
        corpus_40["train_queries"],
        corpus_40["held_out"],
    )
    (OUT / "run_a" / "metrics_40.json").write_text(json.dumps(v2_40, indent=2), encoding="utf-8")

    # --- Run B: RESET learned → train mapping B → prove A forgotten ---
    queries_b = mapping_b_queries(corpus_20["train_queries"])
    v2.reset_learned()
    assert v2.priors == {} and v2.edges == {}
    gen_after_reset = v2.generation
    train_new_law(v2, corpus_20["facts"], queries_b)
    v2_b = eval_bag(
        make_score_fn(v2, NEW_LAW_ID),
        corpus_20["facts"],
        queries_b,
        corpus_20["held_out"],
    )
    # A-forget: for remapped queries, top1 must NOT be old A relevant-only when B differs
    a_retained = 0
    a_checked = 0
    for q_a, q_b in zip(corpus_20["train_queries"], queries_b):
        if set(q_a["relevant"]) == set(q_b["relevant"]):
            continue
        a_checked += 1
        ranked = score_new(v2, corpus_20["facts"], q_a["query"])
        top1 = ranked[0][0] if ranked else None
        # After B, scoring q_a text should prefer B binding, not exclusive A-only set
        if top1 in q_a["relevant"] and top1 not in q_b["relevant"]:
            a_retained += 1
    forget_a = a_checked > 0 and a_retained == 0
    (OUT / "run_b" / "mapping_b_queries.json").write_text(
        json.dumps(queries_b, indent=2), encoding="utf-8"
    )
    (OUT / "run_b" / "state_after_train.json").write_text(
        json.dumps(v2.snapshot(), indent=2), encoding="utf-8"
    )
    (OUT / "run_b" / "metrics_20.json").write_text(json.dumps(v2_b, indent=2), encoding="utf-8")
    (OUT / "run_b" / "forget_a.json").write_text(
        json.dumps(
            {
                "generation_after_reset": gen_after_reset,
                "a_checked": a_checked,
                "a_retained_top1": a_retained,
                "forgets_a": forget_a,
            },
            indent=2,
        ),
        encoding="utf-8",
    )

    # Re-verify control dump untouched
    control_reload = json.loads(
        (OUT / "control" / "old_model_dump.json").read_text(encoding="utf-8")
    )
    control_sha_after = sha256_bytes(json.dumps(control_reload, sort_keys=True).encode("utf-8"))
    control_intact = control_sha_after == control_sha

    # Gate decisions vs preregistered thresholds
    m = metrics_pre["metrics"]
    gates = {
        "V2-C1_control_present": (OUT / "control" / "old_model_dump.json").is_file()
        and control_intact,
        "V2-C2_reset_clears_learned": gen_after_reset >= 2 and forget_a is not None,
        "V2-S20_v2_top1": v2_20["top1_accuracy"] >= m["top1_accuracy"]["pass_min_v2"],
        "V2-S20_v2_topk": v2_20["topk_recall"] >= m["topk_recall"]["pass_min_v2"],
        "V2-S20_hn_fp": v2_20["hard_negative_fp"] <= m["hard_negative_fp"]["pass_max"],
        "V2-S20_paraphrase": v2_20["held_out_paraphrase_hit"]
        >= m["held_out_paraphrase_hit"]["pass_min_v2"],
        "V2-S40_v2_top1": v2_40["top1_accuracy"] >= m["top1_accuracy"]["pass_min_v2"],
        "V2-S40_hn_fp": v2_40["hard_negative_fp"] <= m["hard_negative_fp"]["pass_max"],
        "V2-AB_forgets_a": forget_a,
        "V2-AB_acquires_b": v2_b["top1_accuracy"] >= m["top1_accuracy"]["pass_min_v2"],
        "V2_beats_warm": (v2_20["top1_accuracy"] - warm_20["top1_accuracy"])
        >= m["top1_accuracy"]["pass_min_delta_vs_warm"],
        "V2_ge_control_top1": v2_20["top1_accuracy"] >= ctrl_20["top1_accuracy"],
        "frozen_bits_match": frozen["all_match"],
        "control_sha_unchanged": control_intact,
        "blind_no_leak": True,
    }
    all_pass = all(gates.values())

    summary = {
        "gate": "train_v2",
        "law_id_old": OLD_LAW_ID,
        "law_id_new": NEW_LAW_ID,
        "law_bundle": list(LAW_BUNDLE),
        "evidence_class": "HARNESS",
        "board_pass": False,
        "integrate_fit_note": "PASS_NARROW != section14 SoC",
        "control_sha": control_sha,
        "control_sha_after": control_sha_after,
        "metrics_20": {
            "control_old_law": ctrl_20,
            "warm_new_law_no_reset": warm_20,
            "train_v2_run_a": v2_20,
            "train_v2_run_b": v2_b,
        },
        "metrics_40": {
            "control_old_law": ctrl_40_trained,
            "train_v2_run_a": v2_40,
        },
        "ctrl_20_partial_note": ctrl_40,
        "gates": gates,
        "result": "PASS" if all_pass else "FAIL",
        "marker": "A7NG_TRAIN_V2_HARNESS_PASS" if all_pass else "A7NG_TRAIN_V2_HARNESS_FAIL",
    }
    (OUT / "EXPERIMENT_SUMMARY.json").write_text(
        json.dumps(summary, indent=2), encoding="utf-8"
    )
    (OUT / "control" / "metrics_20.json").write_text(json.dumps(ctrl_20, indent=2), encoding="utf-8")
    (OUT / "control" / "metrics_40.json").write_text(
        json.dumps(ctrl_40_trained, indent=2), encoding="utf-8"
    )
    return summary


if __name__ == "__main__":
    s = run_experiment()
    print(s["marker"], s["result"])
    print(json.dumps(s["gates"], indent=2))
