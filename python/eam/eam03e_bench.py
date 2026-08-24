"""A7-SIM-BENCH v0.1 — held-out benchmark for the 03E string encoder.

The only evaluation that existed before this module was a three-string smoke test
(``ALPHA`` / ``BETA.`` / ``OMEGA``, 32 epochs). Train and eval shared all three
strings, so it measured memorisation of three strings, not generalisation. It is
kept here as ``plasticity_unit_test`` because it is a good RTL regression test,
and it is not a benchmark.

Task family: supervised pairwise metric learning over short byte strings, applied
to approximate string matching. The 46-byte input cap excludes the whole
paraphrase / STS family (QQP, PAWS, MRPC, STS-B, SICK are all 2-3x too long and
truncation destroys the label), and places this system in the learned-string-
metric / record-linkage literature instead.

What is measured, and why each metric is here:

* ``auc``       tie-aware ROC-AUC via midranks. Threshold-free and skew-
                insensitive. d1 is quantised by ``>> 5`` so ties are common;
                trapezoidal ROC integration would silently mis-score them.
* ``ap``        average precision, no interpolation (interpolating in PR space
                is wrong). Reported because AUC is optimistic under skew.
* ``trip_acc``  held-out triplet ranking with half credit on ties. This is the
                powered version of the contract's ``M_L1 > 0`` gate, which on a
                single triplet is one Bernoulli draw that a coin passes half the
                time.
* baselines     B0-B8 in pure Python. The one that decides everything is
                ``untrained``: the same encoder, same seed, zero TRAIN
                transactions. E is a xorshift32 expansion, so the untrained
                encoder is already a random projection of byte sequences and
                whatever d1 does at step 0 is free. The claim of the project
                reduces to held-out AUC rising above it.
* diagnostics   saturation, negativity, effective rank, and a length-shortcut
                audit. Dimensional collapse is invisible to accuracy metrics, and
                a metric that is a monotone function of ``|len(a) - len(b)|`` is
                not a string metric.

AUTHORITY: twin numbers are a screen, not evidence. A board run under
``tools/a7eam03e_a0_silicon.py`` is the only thing that can close a gate.
"""
from __future__ import annotations

import hashlib
import math
import random
from dataclasses import dataclass, field
from operator import mul
from typing import Callable, Iterable, Sequence

from python.eam.eam03e_twin import E3_D, E3_TMAX, Eam03eTwin

BENCH_ID = "A7-SIM-BENCH-v0.1"
MAX_BYTES = E3_TMAX


# --------------------------------------------------------------------------- #
# metrics
# --------------------------------------------------------------------------- #

def auc_midrank(scores: Sequence[float], labels: Sequence[int]) -> float:
    """Tie-aware ROC-AUC. ``scores`` higher = more likely positive (use -d1).

    Equals the Wilcoxon-Mann-Whitney statistic over midranks, so a tied
    (positive, negative) cross-pair contributes exactly 0.5. Returns nan when one
    class is absent.
    """
    n = len(labels)
    order = sorted(range(n), key=lambda i: scores[i])
    ranks = [0.0] * n
    i = 0
    while i < n:
        j = i
        while j + 1 < n and scores[order[j + 1]] == scores[order[i]]:
            j += 1
        r = (i + j) / 2.0 + 1.0
        for k in range(i, j + 1):
            ranks[order[k]] = r
        i = j + 1
    n1 = sum(1 for y in labels if y == 1)
    n0 = n - n1
    if n1 == 0 or n0 == 0:
        return float("nan")
    r1 = sum(ranks[i] for i in range(n) if labels[i] == 1)
    return (r1 - n1 * (n1 + 1) / 2.0) / (n1 * n0)


def average_precision(scores: Sequence[float], labels: Sequence[int]) -> float:
    """Average precision, tied blocks consumed whole, no PR interpolation."""
    n_pos = sum(1 for y in labels if y == 1)
    if n_pos == 0:
        return float("nan")
    idx = sorted(range(len(scores)), key=lambda i: -scores[i])
    ap = prev_recall = 0.0
    tp = fp = 0
    i = 0
    while i < len(idx):
        j = i
        while j + 1 < len(idx) and scores[idx[j + 1]] == scores[idx[i]]:
            j += 1
        for k in range(i, j + 1):
            if labels[idx[k]] == 1:
                tp += 1
            else:
                fp += 1
        recall = tp / n_pos
        ap += (recall - prev_recall) * (tp / (tp + fp))
        prev_recall = recall
        i = j + 1
    return ap


def tie_mass(scores: Sequence[float], labels: Sequence[int]) -> float:
    """Fraction of (positive, negative) cross-pairs that share a score.

    This is exactly the share of AUC decided by the 0.5 tie credit rather than by
    the model, so it bounds how much of the result is real ordering.
    """
    pos: dict[float, int] = {}
    neg: dict[float, int] = {}
    for s, y in zip(scores, labels, strict=True):
        (pos if y == 1 else neg)[s] = (pos if y == 1 else neg).get(s, 0) + 1
    n1, n0 = sum(pos.values()), sum(neg.values())
    if not n1 or not n0:
        return float("nan")
    tied = sum(c * neg.get(s, 0) for s, c in pos.items())
    return tied / (n1 * n0)


def quantisation_ceiling(scores: Sequence[float], labels: Sequence[int]) -> float:
    """Best AUC any model could reach with this many distinct score levels.

    Sorts levels by their positive rate, which is the optimal relabelling, then
    scores that. Separates "the model is weak" from "the readout cannot express
    the answer".
    """
    by: dict[float, list[int]] = {}
    for s, y in zip(scores, labels, strict=True):
        by.setdefault(s, []).append(y)
    ranked = sorted(by, key=lambda s: sum(by[s]) / len(by[s]))
    ideal_scores: list[float] = []
    ideal_labels: list[int] = []
    for rank, s in enumerate(ranked):
        for y in by[s]:
            ideal_scores.append(float(rank))
            ideal_labels.append(y)
    return auc_midrank(ideal_scores, ideal_labels)


def triplet_accuracy(triplets: Sequence[tuple[float, float]]) -> float:
    """``(d_pos, d_neg)`` pairs. Half credit on ties, matching the AUC convention."""
    if not triplets:
        return float("nan")
    hits = sum(1.0 if dp < dn else (0.5 if dp == dn else 0.0) for dp, dn in triplets)
    return hits / len(triplets)


def spearman(x: Sequence[float], y: Sequence[float]) -> float:
    def rank(v: Sequence[float]) -> list[float]:
        order = sorted(range(len(v)), key=lambda i: v[i])
        r = [0.0] * len(v)
        i = 0
        while i < len(order):
            j = i
            while j + 1 < len(order) and v[order[j + 1]] == v[order[i]]:
                j += 1
            mid = (i + j) / 2.0 + 1.0
            for k in range(i, j + 1):
                r[order[k]] = mid
            i = j + 1
        return r

    rx, ry = rank(x), rank(y)
    n = len(rx)
    if n < 2:
        return float("nan")
    mx, my = sum(rx) / n, sum(ry) / n
    num = sum((a - mx) * (b - my) for a, b in zip(rx, ry, strict=True))
    dx = math.sqrt(sum((a - mx) ** 2 for a in rx))
    dy = math.sqrt(sum((b - my) ** 2 for b in ry))
    return 0.0 if dx == 0 or dy == 0 else num / (dx * dy)


def paired_bootstrap(scores_a: Sequence[float], scores_b: Sequence[float],
                     labels: Sequence[int], rounds: int = 2000,
                     seed: int = 12345) -> dict:
    """Paired bootstrap over pair indices for ``AUC(a) - AUC(b)``.

    Resamples indices once per round so both systems see the same resample. This
    answers "is the split large enough"; bootstrapping over seeds is a different
    question and is handled by :func:`bench_seeds`.
    """
    rng = random.Random(seed)
    n = len(labels)
    deltas: list[float] = []
    for _ in range(rounds):
        idx = [rng.randrange(n) for _ in range(n)]
        la = [labels[i] for i in idx]
        s = sum(la)
        if s == 0 or s == n:
            continue
        deltas.append(auc_midrank([scores_a[i] for i in idx], la)
                      - auc_midrank([scores_b[i] for i in idx], la))
    if not deltas:
        return {"mean": float("nan"), "lo": float("nan"), "hi": float("nan"), "rounds": 0}
    deltas.sort()
    return {
        "mean": sum(deltas) / len(deltas),
        "lo": deltas[int(0.025 * len(deltas))],
        "hi": deltas[int(0.975 * len(deltas))],
        "rounds": len(deltas),
    }


# --------------------------------------------------------------------------- #
# baselines (pure Python, no dependencies)
# --------------------------------------------------------------------------- #

def levenshtein(a: bytes, b: bytes) -> int:
    if len(a) < len(b):
        a, b = b, a
    prev = list(range(len(b) + 1))
    for i, ca in enumerate(a, start=1):
        cur = [i] + [0] * len(b)
        for j, cb in enumerate(b, start=1):
            cur[j] = min(prev[j] + 1, cur[j - 1] + 1, prev[j - 1] + (ca != cb))
        prev = cur
    return prev[len(b)]


def osa_distance(a: bytes, b: bytes) -> int:
    """Damerau-Levenshtein, optimal string alignment variant (adjacent swaps)."""
    la, lb = len(a), len(b)
    d = [[0] * (lb + 1) for _ in range(la + 1)]
    for i in range(la + 1):
        d[i][0] = i
    for j in range(lb + 1):
        d[0][j] = j
    for i in range(1, la + 1):
        for j in range(1, lb + 1):
            cost = 0 if a[i - 1] == b[j - 1] else 1
            d[i][j] = min(d[i - 1][j] + 1, d[i][j - 1] + 1, d[i - 1][j - 1] + cost)
            if i > 1 and j > 1 and a[i - 1] == b[j - 2] and a[i - 2] == b[j - 1]:
                d[i][j] = min(d[i][j], d[i - 2][j - 2] + 1)
    return d[la][lb]


def jaro(a: bytes, b: bytes) -> float:
    la, lb = len(a), len(b)
    if la == 0 and lb == 0:
        return 1.0
    if la == 0 or lb == 0:
        return 0.0
    window = max(0, max(la, lb) // 2 - 1)
    ma = [False] * la
    mb = [False] * lb
    matches = 0
    for i in range(la):
        for j in range(max(0, i - window), min(i + window + 1, lb)):
            if not mb[j] and a[i] == b[j]:
                ma[i] = mb[j] = True
                matches += 1
                break
    if matches == 0:
        return 0.0
    k = trans = 0
    for i in range(la):
        if ma[i]:
            while not mb[k]:
                k += 1
            if a[i] != b[k]:
                trans += 1
            k += 1
    t = trans / 2.0
    return (matches / la + matches / lb + (matches - t) / matches) / 3.0


def _grams(s: bytes, n: int) -> set[bytes]:
    return {s[i:i + n] for i in range(max(0, len(s) - n + 1))} or {s}


def b0_constant(a: bytes, b: bytes) -> float:
    return 0.0


def b1_length(a: bytes, b: bytes) -> float:
    return -abs(len(a) - len(b))


def b2_jaccard_bytes(a: bytes, b: bytes) -> float:
    sa, sb = set(a), set(b)
    u = len(sa | sb)
    return 0.0 if u == 0 else len(sa & sb) / u


def b3_hist_l1(a: bytes, b: bytes) -> float:
    """Byte-histogram L1: this architecture with the recurrence deleted.

    Same 256-symbol alphabet, same L1 distance, no order. If the trained encoder
    cannot beat this, the Elman step contributed nothing.
    """
    ha = [0] * 256
    hb = [0] * 256
    for x in a:
        ha[x] += 1
    for x in b:
        hb[x] += 1
    return -sum(abs(ha[i] - hb[i]) for i in range(256))


def b4_bigram_dice(a: bytes, b: bytes) -> float:
    ga, gb = _grams(a, 2), _grams(b, 2)
    d = len(ga) + len(gb)
    return 0.0 if d == 0 else 2.0 * len(ga & gb) / d


def b5_levenshtein(a: bytes, b: bytes) -> float:
    m = max(len(a), len(b))
    return 1.0 if m == 0 else 1.0 - levenshtein(a, b) / m


def b6_osa(a: bytes, b: bytes) -> float:
    m = max(len(a), len(b))
    return 1.0 if m == 0 else 1.0 - osa_distance(a, b) / m


def b7_jaro_winkler(a: bytes, b: bytes, p: float = 0.1) -> float:
    j = jaro(a, b)
    prefix = 0
    for x, y in zip(a, b):
        if x != y:
            break
        prefix += 1
        if prefix == 4:
            break
    return j + prefix * p * (1.0 - j)


def b8_suffix(a: bytes, b: bytes) -> float:
    """Common suffix length. d1 reads the final recurrence state, so it should be
    suffix-biased; comparing this against a prefix probe exposes that."""
    n = 0
    for x, y in zip(reversed(a), reversed(b)):
        if x != y:
            break
        n += 1
    return n


BASELINES: dict[str, Callable[[bytes, bytes], float]] = {
    "B0_constant": b0_constant,
    "B1_length": b1_length,
    "B2_jaccard_bytes": b2_jaccard_bytes,
    "B3_hist_l1": b3_hist_l1,
    "B4_bigram_dice": b4_bigram_dice,
    "B5_levenshtein": b5_levenshtein,
    "B6_osa": b6_osa,
    "B7_jaro_winkler": b7_jaro_winkler,
    "B8_suffix": b8_suffix,
}


# --------------------------------------------------------------------------- #
# dataset
# --------------------------------------------------------------------------- #

@dataclass
class Pair:
    a: str
    b: str
    same: bool
    entity_a: int = -1
    entity_b: int = -1


@dataclass
class Dataset:
    name: str
    train: list[Pair] = field(default_factory=list)
    dev: list[Pair] = field(default_factory=list)
    test: list[Pair] = field(default_factory=list)
    note: str = ""

    def counts(self) -> dict:
        def c(rows: list[Pair]) -> dict:
            return {"pairs": len(rows), "positive": sum(1 for p in rows if p.same)}
        return {"train": c(self.train), "dev": c(self.dev), "test": c(self.test)}


_GIVEN = ("An Binh Chi Dung Duong Giang Ha Hai Hanh Hoa Hoang Hung Huy Khanh Kien "
          "Lam Lan Linh Long Mai Minh Nam Nga Ngoc Nhung Phong Phuc Quan Quang Quynh "
          "Son Tam Thanh Thao Thu Thuy Tien Toan Trang Trung Tu Tuan Vinh Vu Yen").split()
_SUR = ("Nguyen Tran Le Pham Hoang Huynh Phan Vu Vo Dang Bui Do Ho Ngo Duong Ly "
        "Cao Mai Truong Dinh").split()
_MID = ("Van Thi Duc Minh Ngoc Quoc Xuan Thanh Anh Huu").split()

_VN_MAP = {
    "a": "\u00e2", "e": "\u00ea", "o": "\u01a1", "u": "\u01b0", "d": "\u0111",
    "i": "\u00ed", "y": "\u00fd",
}
_KEYS = {"a": "sq", "b": "vn", "c": "xv", "d": "sf", "e": "wr", "g": "fh",
         "h": "gj", "i": "uo", "l": "k", "m": "n", "n": "mb", "o": "ip",
         "p": "o", "q": "wa", "r": "et", "s": "ad", "t": "ry", "u": "yi",
         "v": "cb", "y": "tu"}


def _corrupt(name: str, rng: random.Random, vn: bool) -> str:
    """One surface variant of a canonical name. Deterministic under ``rng``."""
    ops = ["typo", "swap", "drop", "dup", "case", "abbrev", "reorder"]
    if vn:
        ops += ["diacritic", "diacritic"]
    s = name
    for _ in range(rng.choice((1, 1, 2))):
        op = rng.choice(ops)
        if op == "typo" and len(s) > 3:
            i = rng.randrange(len(s))
            lo = s[i].lower()
            if lo in _KEYS:
                repl = rng.choice(_KEYS[lo])
                s = s[:i] + (repl.upper() if s[i].isupper() else repl) + s[i + 1:]
        elif op == "swap" and len(s) > 4:
            i = rng.randrange(len(s) - 1)
            s = s[:i] + s[i + 1] + s[i] + s[i + 2:]
        elif op == "drop" and len(s) > 4:
            i = rng.randrange(len(s))
            s = s[:i] + s[i + 1:]
        elif op == "dup" and len(s) > 2:
            i = rng.randrange(len(s))
            s = s[:i + 1] + s[i] + s[i + 1:]
        elif op == "case":
            s = s.upper() if rng.random() < 0.5 else s.lower()
        elif op == "abbrev":
            parts = s.split()
            if len(parts) > 1 and len(parts[0]) > 1:
                parts[0] = parts[0][0] + "."
                s = " ".join(parts)
        elif op == "reorder":
            parts = s.split()
            if len(parts) > 2:
                parts = [parts[-1]] + parts[:-1]
                s = " ".join(parts)
        elif op == "diacritic":
            i = rng.randrange(len(s))
            lo = s[i].lower()
            if lo in _VN_MAP:
                s = s[:i] + _VN_MAP[lo] + s[i + 1:]
    return s.strip() or name


def build_name_dataset(n_entities: int = 260, seed: int = 0, vn: bool = False,
                       hard_negatives: int = 1,
                       fracs: tuple[float, float, float] = (0.6, 0.2, 0.2)) -> Dataset:
    """``NAME-46-SYN`` (or ``NAME-46-VN``): deterministic, runnable with no network.

    Honest scope: this is a smoke-scale stand-in so the harness can run today. The
    real claim needs ``TOPO-46-LAT`` (:func:`load_pairs_tsv`, GeoNames toponym
    matching, 5M pairs, mean 22.7 chars, published baselines from 61.5% to 88.7%
    accuracy). Synthetic corruption is an error model somebody chose; real typos
    are not.

    Positives are two variants of one entity. Negatives are variants of different
    entities, kept only when lexically confusable (mined by OSA distance), because
    easy negatives make any metric look good.
    """
    rng = random.Random(seed)
    variants: list[list[str]] = []
    for _ in range(n_entities):
        parts = [rng.choice(_SUR), rng.choice(_MID), rng.choice(_GIVEN)]
        if rng.random() < 0.35:
            parts.insert(2, rng.choice(_GIVEN))
        canon = " ".join(parts)
        if vn:
            canon = _corrupt(canon, rng, True)
        seen = {canon}
        for _ in range(rng.choice((2, 3, 3, 4))):
            v = _corrupt(canon, rng, vn)
            if len(v.encode("utf-8")) <= MAX_BYTES:
                seen.add(v)
        keep = [v for v in sorted(seen) if 2 <= len(v.encode("utf-8")) <= MAX_BYTES]
        if len(keep) >= 2:
            variants.append(keep)

    pairs: list[Pair] = []
    for ent, vs in enumerate(variants):
        for i in range(len(vs) - 1):
            pairs.append(Pair(vs[i], vs[i + 1], True, ent, ent))

    # hard negatives: for each entity, the lexically closest variant of another
    for ent, vs in enumerate(variants):
        anchor = vs[0]
        ab = anchor.encode("utf-8")
        cands: list[tuple[int, int, str]] = []
        for other in rng.sample(range(len(variants)), min(24, len(variants))):
            if other == ent:
                continue
            cand = variants[other][0]
            cands.append((osa_distance(ab, cand.encode("utf-8")), other, cand))
        cands.sort()
        for dist, other, cand in cands[:hard_negatives]:
            pairs.append(Pair(anchor, cand, False, ent, other))

    splits = group_split(pairs, fracs=fracs, seed=seed)
    return Dataset(
        name="NAME-46-VN" if vn else "NAME-46-SYN",
        train=splits["train"], dev=splits["dev"], test=splits["test"],
        note=("synthetic, deterministic, entity-level group split; "
              "smoke-scale stand-in for TOPO-46-LAT"),
    )


def load_pairs_tsv(path: str, max_rows: int = 200000, latin_only: bool = True,
                   seed: int = 0,
                   fracs: tuple[float, float, float] = (0.6, 0.2, 0.2)) -> Dataset:
    """Load an external pair file: ``str_a<TAB>str_b<TAB>label`` per line.

    Label is truthy for a match (``1``, ``TRUE``, ``true``). Rows are dropped
    when either side is outside 2..46 UTF-8 bytes, and when ``latin_only`` any row
    with a byte >= 0x80 is dropped too. Both retained fractions are returned so a
    reader can see what was thrown away — with GeoNames the excluded CJK / Arabic
    / Cyrillic / Thai pairs are exactly where a learned metric earns its largest
    margin over heuristics, so excluding them is honest but flattering.

    Get the 5M-pair GeoNames set from https://github.com/ruipds/Toponym-Matching
    (``dataset/``); baselines are in https://doi.org/10.1080/13658816.2017.1390119.
    """
    rows: list[Pair] = []
    seen_total = dropped_len = dropped_script = 0
    with open(path, "r", encoding="utf-8", errors="replace") as fh:
        for line in fh:
            parts = line.rstrip("\n").split("\t")
            if len(parts) < 3:
                continue
            seen_total += 1
            a, b, lab = parts[0].strip(), parts[1].strip(), parts[2].strip()
            ab, bb = a.encode("utf-8"), b.encode("utf-8")
            if not (2 <= len(ab) <= MAX_BYTES and 2 <= len(bb) <= MAX_BYTES):
                dropped_len += 1
                continue
            if latin_only and (max(ab) >= 0x80 or max(bb) >= 0x80):
                dropped_script += 1
                continue
            rows.append(Pair(a, b, lab.lower() in ("1", "true", "t", "yes")))
            if len(rows) >= max_rows:
                break
    splits = group_split(rows, fracs=fracs, seed=seed)
    return Dataset(
        name=f"EXT:{path}",
        train=splits["train"], dev=splits["dev"], test=splits["test"],
        note=(f"loaded {len(rows)} of {seen_total} rows; dropped {dropped_len} on "
              f"length, {dropped_script} on script; latin_only={latin_only}"),
    )


def group_split(pairs: Iterable[Pair], fracs: tuple[float, float, float] = (0.6, 0.2, 0.2),
                seed: int = 0) -> dict[str, list[Pair]]:
    """Split by connected component of the pair graph, not by pair.

    A match label is transitively an entity relation, so splitting at pair level
    leaks: a string in a training pair can reappear in a test pair. Every labeled
    pair (positive and negative) becomes an edge; whole components go to one
    split. The disjointness of string sets is asserted by
    :func:`assert_no_leakage`.
    """
    pairs = list(pairs)
    parent: dict[str, str] = {}

    def find(x: str) -> str:
        parent.setdefault(x, x)
        while parent[x] != x:
            parent[x] = parent[parent[x]]
            x = parent[x]
        return x

    for p in pairs:
        ra, rb = find(p.a), find(p.b)
        if ra != rb:
            parent[ra] = rb

    comp: dict[str, list[Pair]] = {}
    for p in pairs:
        comp.setdefault(find(p.a), []).append(p)

    names = ("train", "dev", "test")
    total = len(pairs) or 1
    quota = [f * total for f in fracs]
    out: dict[str, list[Pair]] = {n: [] for n in names}
    order = sorted(comp, key=lambda c: (-len(comp[c]), c))
    for c in order:
        i = max(range(3), key=lambda k: quota[k] - len(out[names[k]]))
        out[names[i]].extend(comp[c])
    rng = random.Random(seed)
    for n in names:
        rng.shuffle(out[n])
    return out


def assert_no_leakage(ds: Dataset) -> dict:
    """Every string must appear in at most one split. Raises on failure."""
    def strings(rows: list[Pair]) -> set[str]:
        s: set[str] = set()
        for p in rows:
            s.add(p.a)
            s.add(p.b)
        return s

    tr, dv, te = strings(ds.train), strings(ds.dev), strings(ds.test)
    bad = {
        "train_dev": sorted(tr & dv)[:5],
        "train_test": sorted(tr & te)[:5],
        "dev_test": sorted(dv & te)[:5],
    }
    if any(bad.values()):
        raise AssertionError(f"split leakage in {ds.name}: {bad}")
    return {"train_strings": len(tr), "dev_strings": len(dv), "test_strings": len(te)}


# --------------------------------------------------------------------------- #
# encoder scoring
# --------------------------------------------------------------------------- #

def encoder_scores(twin: Eam03eTwin, rows: Sequence[Pair]) -> tuple[list[float], list[int], list[int]]:
    """Score rows with the twin in a fixed order, learning disabled.

    Order matters and is not an accident: ``e_ra`` carries across pairs in the
    RTL, so d1 is history dependent. Evaluating in the given order is what the
    board does, and it is reproducible; caching per unique string would not be.
    """
    keep_learn, keep_freeze = twin.learn, twin.freeze
    twin.mode(learn=False, freeze=True)
    scores: list[float] = []
    labels: list[int] = []
    d1s: list[int] = []
    for p in rows:
        tr = twin.measure(p.a, p.b, p.same)
        d1s.append(tr.d1)
        scores.append(-float(tr.d1))
        labels.append(1 if p.same else 0)
    twin.mode(learn=keep_learn, freeze=keep_freeze)
    return scores, labels, d1s


def baseline_scores(fn: Callable[[bytes, bytes], float],
                    rows: Sequence[Pair]) -> tuple[list[float], list[int]]:
    scores = [fn(p.a.encode("utf-8"), p.b.encode("utf-8")) for p in rows]
    labels = [1 if p.same else 0 for p in rows]
    return scores, labels


def score_block(scores: Sequence[float], labels: Sequence[int]) -> dict:
    return {
        "auc": round(auc_midrank(scores, labels), 6),
        "ap": round(average_precision(scores, labels), 6),
        "tie_mass": round(tie_mass(scores, labels), 6),
        "levels": len(set(scores)),
        "n": len(labels),
        "positive_rate": round(sum(labels) / max(1, len(labels)), 6),
    }


def train_stream(twin: Eam03eTwin, rows: Sequence[Pair], epochs: int = 1,
                 shuffle_labels: bool = False, seed: int = 0) -> int:
    """Stream TRAIN transactions. Host sends bytes + one supervision bit only."""
    rng = random.Random(seed)
    twin.mode(learn=True, freeze=False)
    n = 0
    for _ in range(epochs):
        for p in rows:
            same = rng.random() < 0.5 if shuffle_labels else p.same
            twin.measure(p.a, p.b, same)
            n += 1
    twin.mode(learn=False, freeze=True)
    return n


# --------------------------------------------------------------------------- #
# diagnostics
# --------------------------------------------------------------------------- #

def _jacobi_eigenvalues(m: list[list[float]], sweeps: int = 60) -> list[float]:
    """Eigenvalues of a small symmetric matrix. 32x32 makes this trivial."""
    n = len(m)
    a = [row[:] for row in m]
    for _ in range(sweeps):
        off = 0.0
        for i in range(n - 1):
            for j in range(i + 1, n):
                off += a[i][j] * a[i][j]
        if off < 1e-12:
            break
        for p in range(n - 1):
            for q in range(p + 1, n):
                if abs(a[p][q]) < 1e-15:
                    continue
                theta = (a[q][q] - a[p][p]) / (2.0 * a[p][q])
                t = math.copysign(1.0, theta) / (abs(theta) + math.sqrt(theta * theta + 1.0))
                c = 1.0 / math.sqrt(t * t + 1.0)
                s = t * c
                for k in range(n):
                    akp, akq = a[k][p], a[k][q]
                    a[k][p] = c * akp - s * akq
                    a[k][q] = s * akp + c * akq
                for k in range(n):
                    apk, aqk = a[p][k], a[q][k]
                    a[p][k] = c * apk - s * aqk
                    a[q][k] = s * apk + c * aqk
    return sorted((a[i][i] for i in range(n)), reverse=True)


def collapse_report(twin: Eam03eTwin, rows: Sequence[Pair], limit: int = 400) -> dict:
    """Saturation, negativity and effective rank of the held-out state cloud.

    Dimensional collapse does not show up in AUC, so it has to be measured
    directly. ``negativity_rate`` is the cheapest detector for whether the
    unsigned-concatenation defect (twin quirk 2) has been repaired: while it
    stands, the rate is exactly 0.
    """
    seen: dict[str, list[int]] = {}
    for p in rows:
        for s in (p.a, p.b):
            if s not in seen:
                twin.buf(0, s)
                seen[s] = twin.encode(0).h_final
            if len(seen) >= limit:
                break
        if len(seen) >= limit:
            break
    vecs = list(seen.values())
    if not vecs:
        return {"vectors": 0}

    cells = len(vecs) * E3_D
    sat = sum(1 for v in vecs for x in v if x == 32767)
    neg = sum(1 for v in vecs for x in v if x < 0)
    means = [sum(v[i] for v in vecs) / len(vecs) for i in range(E3_D)]
    gram = [[0.0] * E3_D for _ in range(E3_D)]
    for v in vecs:
        d = [v[i] - means[i] for i in range(E3_D)]
        for i in range(E3_D):
            di = d[i]
            if di:
                gi = gram[i]
                for j in range(i, E3_D):
                    gi[j] += di * d[j]
    for i in range(E3_D):
        for j in range(i + 1, E3_D):
            gram[j][i] = gram[i][j]
    eig = [max(0.0, e) for e in _jacobi_eigenvalues(gram)]
    sv = [math.sqrt(e) for e in eig]
    top = sv[0] if sv else 0.0
    eff = sum(1 for s in sv if top > 0 and s > 0.01 * top)
    tot = sum(sv)
    return {
        "vectors": len(vecs),
        "saturation_rate": round(sat / cells, 6),
        "negativity_rate": round(neg / cells, 6),
        "defect_quirk2_active": neg == 0,
        "effective_rank": eff,
        "dims": E3_D,
        "singular_top5": [round(s, 2) for s in sv[:5]],
        "spectrum_share_top1": round(top / tot, 6) if tot else 0.0,
    }


def shortcut_report(rows: Sequence[Pair], d1s: Sequence[int],
                    scores: Sequence[float], labels: Sequence[int]) -> dict:
    """Is d1 just a length detector? Stratifying by |len difference| removes the shortcut."""
    dlen = [abs(len(p.a.encode()) - len(p.b.encode())) for p in rows]
    hist = [abs(b3_hist_l1(p.a.encode(), p.b.encode())) for p in rows]
    buckets: dict[str, list[int]] = {}
    for i, d in enumerate(dlen):
        buckets.setdefault("0" if d == 0 else ("1" if d == 1 else ("2" if d == 2 else ">=3")), []).append(i)
    strat = {}
    weighted = 0.0
    total = 0
    for k, idx in sorted(buckets.items()):
        s = [scores[i] for i in idx]
        y = [labels[i] for i in idx]
        a = auc_midrank(s, y)
        strat[k] = {"n": len(idx), "auc": None if a != a else round(a, 6)}
        if a == a:
            weighted += a * len(idx)
            total += len(idx)
    return {
        "spearman_d1_vs_dlen": round(spearman(list(d1s), dlen), 6),
        "spearman_d1_vs_hist_l1": round(spearman(list(d1s), hist), 6),
        "auc_by_length_delta": strat,
        "length_stratified_auc": round(weighted / total, 6) if total else None,
    }


# --------------------------------------------------------------------------- #
# runners
# --------------------------------------------------------------------------- #

def bench_seed(ds: Dataset, seed: int, epochs: int = 6,
               with_baselines: bool = True, bootstrap: int = 0) -> dict:
    """One seed: untrained, trained, and a shuffled-label control on the same split."""
    test = ds.test
    twin = Eam03eTwin()
    twin.reseed(seed)
    twin.measure(test[0].a, test[0].b, True)          # prime, discarded

    un_scores, labels, un_d1 = encoder_scores(twin, test)
    untrained = score_block(un_scores, labels)

    twin_tr = Eam03eTwin()
    twin_tr.reseed(seed)
    twin_tr.measure(test[0].a, test[0].b, True)
    steps = train_stream(twin_tr, ds.train, epochs=epochs, seed=seed)
    tr_scores, _, tr_d1 = encoder_scores(twin_tr, test)
    trained = score_block(tr_scores, labels)

    twin_sh = Eam03eTwin()
    twin_sh.reseed(seed)
    twin_sh.measure(test[0].a, test[0].b, True)
    train_stream(twin_sh, ds.train, epochs=epochs, shuffle_labels=True, seed=seed)
    sh_scores, _, _ = encoder_scores(twin_sh, test)
    shuffled = score_block(sh_scores, labels)

    trips = _triplets(twin_tr, ds.test)
    out = {
        "seed": f"0x{seed:08X}",
        "train_transactions": steps,
        "epochs": epochs,
        "untrained": untrained,
        "trained": trained,
        "shuffled_labels": shuffled,
        "delta_auc": round(trained["auc"] - untrained["auc"], 6),
        "delta_auc_shuffled": round(shuffled["auc"] - untrained["auc"], 6),
        "quantisation_ceiling": round(quantisation_ceiling(tr_scores, labels), 6),
        "triplet": trips,
        "collapse": collapse_report(twin_tr, ds.test),
        "shortcut": shortcut_report(ds.test, tr_d1, tr_scores, labels),
    }
    if bootstrap:
        out["delta_auc_ci"] = paired_bootstrap(tr_scores, un_scores, labels,
                                               rounds=bootstrap, seed=seed)
    if with_baselines:
        out["baselines"] = {}
        for name, fn in BASELINES.items():
            s, y = baseline_scores(fn, test)
            out["baselines"][name] = score_block(s, y)
        best = max((v["auc"] for k, v in out["baselines"].items()
                    if k not in ("B0_constant", "B1_length")), default=float("nan"))
        out["best_classical_auc"] = round(best, 6)
    return out


def _triplets(twin: Eam03eTwin, rows: Sequence[Pair]) -> dict:
    """Anchor-sharing triplets built from the held-out split only."""
    pos: dict[str, list[str]] = {}
    neg: dict[str, list[str]] = {}
    for p in rows:
        (pos if p.same else neg).setdefault(p.a, []).append(p.b)
    trips: list[tuple[float, float]] = []
    margins: list[int] = []
    for anchor, ps in pos.items():
        ns = neg.get(anchor)
        if not ns:
            continue
        for pp in ps:
            for nn in ns:
                dp = twin.measure(anchor, pp, True).d1
                dn = twin.measure(anchor, nn, False).d1
                trips.append((dp, dn))
                margins.append(dn - dp)
    if not trips:
        return {"n": 0, "note": "no held-out anchor had both a positive and a negative"}
    margins.sort()
    inverted = sum(1 for m in margins if m <= 0)
    return {
        "n": len(trips),
        "trip_acc": round(triplet_accuracy(trips), 6),
        "M_L1_median": margins[len(margins) // 2],
        "M_L1_p05": margins[max(0, int(0.05 * len(margins)) - 1)],
        "M_L1_inverted_frac": round(inverted / len(trips), 6),
    }


def epoch_sensitivity(anchor: str = "ALPHA", pos: str = "BETA.", neg: str = "OMEGA",
                      seed: int = 0x11111111,
                      budgets: Sequence[int] = (4, 8, 16, 32, 64, 128, 256)) -> list[dict]:
    """Sweep the epoch budget on one triplet and report ``M_L1`` at each stop.

    Motivation: the frozen golden fixes 32 epochs, and 32 is a waypoint on a
    non-monotone curve rather than a converged state. On seed 0x11111111 the sign
    of ``M_L1`` is negative at 8 epochs and positive at 16-64, and past ~128 the
    positive pair collapses to a single point (``d1 = 0``). Any gate on the sign
    of ``M_L1`` therefore also gates the epoch budget, which is an unregistered
    hyperparameter unless it is reported.
    """
    out = []
    for ep in budgets:
        t = Eam03eTwin()
        t.reseed(seed)
        t.mode(learn=False, freeze=False)
        t.measure(anchor, pos, True)            # prime
        t.mode(learn=True, freeze=False)
        for _ in range(ep):
            t.measure(anchor, pos, True)
            t.measure(anchor, neg, False)
        t.mode(learn=False, freeze=True)
        tp = t.measure(anchor, pos, True)
        tn = t.measure(anchor, neg, False)
        out.append({
            "epochs": ep,
            "train_transactions": ep * 2,
            "d1_pos": tp.d1,
            "d1_neg": tn.d1,
            "M_L1": tn.d1 - tp.d1,
            "saturated_anchor": tp.a.h_saturated,
            "positive_pair_collapsed": tp.d1 == 0,
        })
    return out


def frozen_seeds(count: int = 10) -> list[int]:
    """Seeds derived from a published rule, plus the known inversion case.

    Deriving them removes the option of picking seeds after seeing results. The
    count must be frozen too: the worst-seed rule is monotone decreasing in the
    number of seeds, so it is gameable in both directions otherwise.
    """
    seeds = []
    for i in range(count - 1):
        h = hashlib.sha256(f"{BENCH_ID}|{i}".encode()).digest()
        seeds.append(int.from_bytes(h[:4], "big"))
    seeds.append(0x22222222)   # known inversion, deliberately included
    return seeds


def confirmation_seeds(count: int = 11, offset: int = 100) -> list[int]:
    """Seeds for confirmation runs, disjoint from every selection seed.

    A law chosen on a seed set and then confirmed on the same set proves only
    that the choice was consistent with the data it was chosen from. Confirmation
    needs seeds that were never available to the selection.

    Same published rule as :func:`frozen_seeds`, shifted to indices
    ``offset..offset+count-1``. The offset is far above any plausible ``count``,
    so no selection run can ever have touched these, and they are *derived* rather
    than picked, which is what keeps the confirmation honest. `0x22222222` is
    deliberately **not** appended here: it is a selection seed and including it
    would leak.
    """
    return [int.from_bytes(
        hashlib.sha256(f"{BENCH_ID}|{offset + i}".encode()).digest()[:4], "big")
        for i in range(count)]


GATES = {
    "G1_delta_auc": {"median": 0.02, "worst": 0.0,
                     "why": "0.02 is about 5 standard errors on a 20k-pair split; "
                            "worst-seed at 0 says training may fail to help but must not harm"},
    "G2_beats_hist_l1": {"slack": 0.02,
                         "why": "B3 is this architecture with the recurrence deleted"},
    "G3_beats_classical": {"slack": 0.0,
                           "why": "a learned metric that cannot beat a 1990s heuristic "
                                  "is not doing the thing learned metrics exist for"},
    "G4_auc_floor": {"median": 0.65, "worst": 0.60,
                     "why": "tuned classical metrics sit at 61.5-65.2% accuracy on hard "
                            "negatives; below this the system is not competitive with Jaro"},
    "G5_triplet": {"median": 0.65, "worst": 0.60, "max_inverted": 0.35,
                   "why": "two of three held-out triplets ordered correctly is a claim; "
                          "one triplet is a coin flip"},
    "G6_not_length": {"max_abs_spearman": 0.7, "strat_slack": 0.02,
                      "why": "a monotone function of |length difference| is not a string metric"},
    "G7_not_collapsed": {"max_saturation": 0.50, "min_effective_rank": 8,
                         "why": "asserts the '32-dim' description is not fiction"},
    "G9_no_inversion": {"why": "inherits the contract worst-seed rule"},
}


def evaluate_gates(rows: Sequence[dict]) -> dict:
    """Apply the A7-SIM-BENCH gates across seeds. Screening only, never a PASS."""
    if not rows:
        return {"error": "no seeds"}

    def med(vals: list[float]) -> float:
        v = sorted(vals)
        return v[len(v) // 2]

    d = [r["delta_auc"] for r in rows]
    auc = [r["trained"]["auc"] for r in rows]
    trip = [r["triplet"].get("trip_acc") for r in rows if r["triplet"].get("n")]
    inv = [r["triplet"].get("M_L1_inverted_frac") for r in rows if r["triplet"].get("n")]
    sat = [r["collapse"].get("saturation_rate", 1.0) for r in rows]
    rank = [r["collapse"].get("effective_rank", 0) for r in rows]
    sc = [abs(r["shortcut"]["spearman_d1_vs_dlen"]) for r in rows]
    hist = [r["baselines"]["B3_hist_l1"]["auc"] for r in rows if "baselines" in r]
    best = [r.get("best_classical_auc") for r in rows if r.get("best_classical_auc") is not None]

    g: dict[str, dict] = {}
    g["G1_delta_auc"] = {"median": round(med(d), 6), "worst": round(min(d), 6),
                         "pass": med(d) >= 0.02 and min(d) >= 0.0}
    if hist:
        g["G2_beats_hist_l1"] = {"model_median": round(med(auc), 6),
                                 "B3_median": round(med(hist), 6),
                                 "pass": med(auc) >= med(hist) + 0.02}
    if best:
        g["G3_beats_classical"] = {"model_median": round(med(auc), 6),
                                   "best_classical_median": round(med(best), 6),
                                   "pass": med(auc) > med(best)}
    g["G4_auc_floor"] = {"median": round(med(auc), 6), "worst": round(min(auc), 6),
                         "pass": med(auc) >= 0.65 and min(auc) >= 0.60}
    if trip:
        g["G5_triplet"] = {"median": round(med(trip), 6), "worst": round(min(trip), 6),
                           "max_inverted": round(max(inv), 6),
                           "pass": med(trip) >= 0.65 and min(trip) >= 0.60 and max(inv) < 0.35}
    # A collapsed d1 correlates with nothing, which would score G6 as a pass for
    # the worst possible reason. Degenerate runs cannot pass a shortcut test.
    degenerate = [r["seed"] for r in rows if r["trained"]["levels"] <= 2]
    g["G6_not_length"] = {
        "max_abs_spearman": round(max(sc), 6),
        "degenerate_seeds": degenerate,
        "pass": max(sc) <= 0.7 and not degenerate,
        "note": ("d1 collapsed to <=2 distinct levels on some seed, so the "
                 "correlation is vacuous" if degenerate else ""),
    }
    g["G7_not_collapsed"] = {"mean_saturation": round(sum(sat) / len(sat), 6),
                             "min_effective_rank": min(rank),
                             "pass": sum(sat) / len(sat) <= 0.50 and min(rank) >= 8}
    g["G9_no_inversion"] = {"seeds_with_negative_delta":
                            [r["seed"] for r in rows if r["delta_auc"] < 0],
                            "pass": all(r["delta_auc"] >= 0 for r in rows)}

    verdict = "PROMISING" if all(v.get("pass") for v in g.values()) else (
        "PLASTIC_NOT_DISCRIMINATIVE" if g["G1_delta_auc"]["pass"] else "DOES_NOT_WORK")
    return {
        "gates": g,
        "screen_verdict": verdict,
        "authority": "TWIN SCREEN ONLY — not a BOARD_PASS and not evidence",
        "thresholds": GATES,
    }
