"""A7-EAM-02H — raw hidden geometry. No RTL, no retrain, no Q2.

Grid and candidate rule are frozen in docs/contracts/A7-EAM-02H.md
before this script writes numbers. HOLD is not an input to selection.
"""
from __future__ import annotations

import json
import math
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT))

from python.ref.a7lm06_fixed_ref import D, TinyGPT803k, last_token_corpus  # noqa: E402

sys.path.insert(0, str(ROOT / "tools"))
from a7eam02q_lm06_geometry import HOLD, PARA, UNREL, utf8_tokens  # noqa: E402

OUT = ROOT / "results" / "A7-EAM-02H" / "audit.json"
MD = ROOT / "results" / "A7-EAM-02H" / "audit.md"

LAYERS = (0, 1, 2, 3)
POOLS = ("last", "mean4", "mean8", "mean16")
# Frozen priority — do not sort by measured gap after the fact.
PRIORITY = (
    tuple(f"L{ly}_mean8" for ly in (3, 2, 1, 0))
    + tuple(f"L{ly}_mean16" for ly in (3, 2, 1, 0))
    + tuple(f"L{ly}_mean4" for ly in (3, 2, 1, 0))
    + tuple(f"L{ly}_last" for ly in (3, 2, 1, 0))
)


def mean_last(xs: list[list[int]], n: int) -> list[float]:
    k = min(n, len(xs))
    sl = xs[-k:]
    return [sum(row[d] for row in sl) / k for d in range(D)]


def reps_from_tokens(model: TinyGPT803k, tokens: list[int]) -> dict[str, list[float]]:
    x = model.embed(tokens)
    out: dict[str, list[float]] = {}
    for ly_i, ly in enumerate(model.layers):
        x, _ = model.block(x, ly)
        out[f"L{ly_i}_last"] = [float(v) for v in x[-1]]
        out[f"L{ly_i}_mean4"] = mean_last(x, 4)
        out[f"L{ly_i}_mean8"] = mean_last(x, 8)
        out[f"L{ly_i}_mean16"] = mean_last(x, 16)
    return out


def l1(a: list[float], b: list[float]) -> float:
    return float(sum(abs(x - y) for x, y in zip(a, b, strict=True)))


def l2(a: list[float], b: list[float]) -> float:
    return math.sqrt(sum((x - y) ** 2 for x, y in zip(a, b, strict=True)))


def cosine(a: list[float], b: list[float]) -> float:
    num = sum(x * y for x, y in zip(a, b, strict=True))
    na = math.sqrt(sum(x * x for x in a))
    nb = math.sqrt(sum(y * y for y in b))
    if na == 0.0 or nb == 0.0:
        return 0.0
    return num / (na * nb)


def sign_agree(a: list[float], b: list[float]) -> float:
    n = len(a)

    def s(v: float) -> int:
        return 0 if v == 0 else (1 if v > 0 else -1)

    return sum(1 for x, y in zip(a, b, strict=True) if s(x) == s(y)) / n


def pearson(a: list[float], b: list[float]) -> float:
    n = len(a)
    ma = sum(a) / n
    mb = sum(b) / n
    num = sum((x - ma) * (y - mb) for x, y in zip(a, b, strict=True))
    da = math.sqrt(sum((x - ma) ** 2 for x in a))
    db = math.sqrt(sum((y - mb) ** 2 for y in b))
    if da == 0.0 or db == 0.0:
        return 0.0
    return num / (da * db)


def pair_metrics(a: list[float], b: list[float]) -> dict:
    return {
        "l1": round(l1(a, b), 4),
        "l2": round(l2(a, b), 4),
        "cosine": round(cosine(a, b), 4),
        "sign_agree": round(sign_agree(a, b), 4),
        "pearson": round(pearson(a, b), 4),
    }


def summarize(rows: list[dict], key: str) -> dict:
    xs = sorted(r[key] for r in rows)
    n = len(xs)
    if n == 0:
        return {"n": 0}
    return {
        "n": n,
        "mean": round(sum(xs) / n, 4),
        "p50": xs[n // 2],
        "min": xs[0],
        "max": xs[-1],
    }


def cell_ok(para: list[dict], unrel: list[dict]) -> tuple[bool, str]:
    cp = [r["cosine"] for r in para]
    cu = [r["cosine"] for r in unrel]
    lp = [r["l2"] for r in para]
    lu = [r["l2"] for r in unrel]
    mp, mu = sum(cp) / len(cp), sum(cu) / len(cu)
    mlp, mlu = sum(lp) / len(lp), sum(lu) / len(lu)
    unrel_med = sorted(cu)[len(cu) // 2]
    rank = sum(1 for c in cp if c > unrel_med)
    cos_ok = mp >= mu + 0.20 and mp >= 0.35
    l2_ok = mlu >= 1.5 * mlp if mlp > 0 else False
    rank_ok = rank >= 6
    why = f"cos {mp:.3f} vs {mu:.3f}; L2 {mlp:.2f} vs {mlu:.2f}; rank {rank}/8"
    return (rank_ok and (cos_ok or l2_ok), why)


def per_dim_sep(para_pairs: list[tuple[list[float], list[float]]], unrel_pairs: list[tuple[list[float], list[float]]]) -> dict:
    better = 0
    for d in range(D):
        mp = sum(abs(a[d] - b[d]) for a, b in para_pairs) / len(para_pairs)
        mu = sum(abs(a[d] - b[d]) for a, b in unrel_pairs) / len(unrel_pairs)
        if mp < mu:
            better += 1
    return {"dims_para_tighter": better, "dims": D, "frac": round(better / D, 4)}


def native_pairs(model: TinyGPT803k, name: str) -> tuple[list[dict], list[dict]]:
    raw = last_token_corpus(48, seed=7)
    by: dict[int, list[list[int]]] = {}
    for pref, tgt in raw:
        by.setdefault(tgt, []).append(pref)
    cache: dict[tuple[int, ...], dict[str, list[float]]] = {}

    def get(seq: list[int]) -> list[float]:
        key = tuple(seq)
        if key not in cache:
            cache[key] = reps_from_tokens(model, seq)
        return cache[key][name]

    same: list[dict] = []
    diff: list[dict] = []
    tgts = list(by)
    for tgt, seqs in by.items():
        vecs = [get(s) for s in seqs]
        for i in range(len(vecs)):
            for j in range(i + 1, len(vecs)):
                same.append(pair_metrics(vecs[i], vecs[j]))
        others = [s for t, ss in by.items() if t != tgt for s in ss[:2]]
        ov = [get(s) for s in others]
        for v in vecs[:2]:
            for o in ov:
                diff.append(pair_metrics(v, o))
    return same, diff


def hold_confirm(hold_rows: list[dict], kind: str) -> bool:
    # HOLD[0] paraphrase; HOLD[1], HOLD[2] unrelated — frozen in 02Q.
    if len(hold_rows) < 3:
        return False
    p, u1, u2 = hold_rows[0], hold_rows[1], hold_rows[2]
    if kind == "cosine":
        return p["cosine"] > u1["cosine"] and p["cosine"] > u2["cosine"]
    return p["l2"] < u1["l2"] and p["l2"] < u2["l2"]


def md_table(cells: dict) -> str:
    lines = [
        "| cell | PARA cos | UNREL cos | Δcos | PARA L2 | UNREL L2 | L2 ratio | rank | cand |",
        "|------|----------|-----------|------|---------|----------|----------|------|------|",
    ]
    for name in PRIORITY:
        c = cells[name]
        p, u = c["PARA"], c["UNREL"]
        ratio = (u["l2"]["mean"] / p["l2"]["mean"]) if p["l2"]["mean"] else 0
        lines.append(
            f"| `{name}` | {p['cosine']['mean']:.3f} | {u['cosine']['mean']:.3f} | "
            f"{p['cosine']['mean']-u['cosine']['mean']:+.3f} | "
            f"{p['l2']['mean']:.1f} | {u['l2']['mean']:.1f} | {ratio:.2f} | "
            f"{c['rank_above_unrel_median']}/8 | {c['candidate']} |"
        )
    return "\n".join(lines)


def main() -> int:
    model = TinyGPT803k(2)
    uniq_txt = {s for bag in (PARA, UNREL, HOLD) for pair in bag for s in pair}
    cache_txt = {t: reps_from_tokens(model, utf8_tokens(t)) for t in uniq_txt}

    cells: dict = {}
    for name in PRIORITY:
        para_v = [(cache_txt[a][name], cache_txt[b][name]) for a, b in PARA]
        unrel_v = [(cache_txt[a][name], cache_txt[b][name]) for a, b in UNREL]
        para_m = [pair_metrics(a, b) for a, b in para_v]
        unrel_m = [pair_metrics(a, b) for a, b in unrel_v]
        ok, why = cell_ok(para_m, unrel_m)
        unrel_med = sorted(r["cosine"] for r in unrel_m)[len(unrel_m) // 2]
        rank = sum(1 for r in para_m if r["cosine"] > unrel_med)
        cells[name] = {
            "PARA": {k: summarize(para_m, k) for k in ("l1", "l2", "cosine", "sign_agree", "pearson")},
            "UNREL": {k: summarize(unrel_m, k) for k in ("l1", "l2", "cosine", "sign_agree", "pearson")},
            "PARA_rows": para_m,
            "UNREL_rows": unrel_m,
            "rank_above_unrel_median": rank,
            "per_dim": per_dim_sep(para_v, unrel_v),
            "candidate": ok,
            "why": why,
        }

    # NATIVE after text grid (diagnostic).
    for name in PRIORITY:
        same, diff = native_pairs(model, name)
        cells[name]["NATIVE_same_k"] = {k: summarize(same, k) for k in ("l2", "cosine", "sign_agree")}
        cells[name]["NATIVE_diff_k"] = {k: summarize(diff, k) for k in ("l2", "cosine", "sign_agree")}

    # HOLD last — confirmation only.
    hold_by_cell = {}
    for name in PRIORITY:
        hm = [pair_metrics(cache_txt[a][name], cache_txt[b][name]) for a, b in HOLD]
        hold_by_cell[name] = hm

    first = next((n for n in PRIORITY if cells[n]["candidate"]), None)
    hold_ok = False
    if first:
        hold_ok = hold_confirm(hold_by_cell[first], "cosine") or hold_confirm(hold_by_cell[first], "l2")

    q1p = bool(first and hold_ok)
    report = {
        "lane": "A7-EAM-02H",
        "law": "eam02h-audit-v1",
        "weights": "TinyGPT803k(seed=2) unchanged",
        "tokenizer": "utf8-bytes",
        "hold_unused_for_selection": True,
        "priority": list(PRIORITY),
        "cells": cells,
        "HOLD": hold_by_cell,
        "decision": {
            "first_candidate": first,
            "hold_confirmed": hold_ok,
            "open_q1p": q1p,
            "open_q2": False,
            "open_eam02a": False,
            "reason": (
                f"Q1P candidate {first} confirmed on HOLD"
                if q1p
                else (
                    f"candidate {first} failed HOLD — no Q1P"
                    if first
                    else "no cell separates PARA/UNREL under the frozen rule — do not learn a 64-bit hash of this hidden"
                )
            ),
        },
    }
    OUT.parent.mkdir(parents=True, exist_ok=True)
    OUT.write_text(json.dumps(report, ensure_ascii=False, indent=2), encoding="utf-8")

    md = [
        "# A7-EAM-02H hidden audit",
        "",
        f"**Decision:** `{report['decision']['reason']}`",
        "",
        "Weights frozen. HOLD not used to pick layer/`N`. Q2 stays closed.",
        "",
        "## Cosine / L2 grid",
        "",
        md_table(cells),
        "",
        "## Native last-token corpus (diagnostic, not PARA)",
        "",
        "| cell | same-k cos | diff-k cos | Δ |",
        "|------|------------|------------|---|",
    ]
    for name in PRIORITY:
        s = cells[name]["NATIVE_same_k"]["cosine"]["mean"]
        d = cells[name]["NATIVE_diff_k"]["cosine"]["mean"]
        md.append(f"| `{name}` | {s:.3f} | {d:.3f} | {s-d:+.3f} |")
    md.append("")
    md.append("HOLD paraphrase must beat both HOLD unrelated if a candidate exists.")
    MD.write_text("\n".join(md) + "\n", encoding="utf-8")
    print(json.dumps(report["decision"], indent=2))
    print(md_table(cells))
    print("WROTE", OUT)
    print("Q1P_OPEN" if q1p else "Q1P_NOGO")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
