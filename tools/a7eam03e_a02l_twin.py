"""A0.2-L triplet hinge, tested on the reference twin before any RTL exists.

Law under test: `eam03e-a02-triplet-v1` (contract
`docs/contracts/A7-EAM-03E-A02.md`) layered on the signed state update of
`eam03e-a03-signed-h-v1`, whose RTL is already XSim- and silicon-exact.

Why on the twin first: A0.3 was predicted on the twin and the RTL then matched
the prediction to the integer, so the twin is a trustworthy design surface. A
failing law costs minutes here and a synthesis run there.

One atomic transaction, not two PAIRs. Host sends three byte strings and one
margin constant; it sends no gradient, no weight, no cue, no address.

Evidence class: REFERENCE MODEL. No RTL, no XSim, no board.
"""
from __future__ import annotations

import argparse
import json
import random
import sys
from datetime import datetime, timezone
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT))
sys.path.insert(0, str(ROOT / "tools"))

import a7eam03e_stability as stab  # noqa: E402
import python.eam.eam03e_twin as tw  # noqa: E402
from python.eam.eam03e_bench import (  # noqa: E402
    Dataset,
    confirmation_seeds,
    Pair,
    assert_no_leakage,
    build_name_dataset,
    group_split,
)
from python.eam.eam03e_twin import (  # noqa: E402
    E3_D,
    WH_SIZE,
    Eam03eTwin,
    golden_check,
    s16,
    sat8,
    sgn8,
)

LAW = "eam03e-a02-triplet-v1 on eam03e-a03-signed-h-v1"

# Pre-registered before the first run. The A02 contract names E3_MARG (4096) as
# the starting point; the smaller values are registered here so that the sweep
# is a declared dose-response and not a search for a value that passes.
MARGIN_SET = (4096, 2048, 1024, 512)

# S3 pre-registered decay shifts. None = control (no restoring force).
DECAY_SH_SET = (6, 5, 4, 3)

# Horizon extension. The original checkpoints are kept verbatim and only new
# ones are appended, so every previously reported number stays comparable.
# Question it answers: is AUC 0.55-0.65 a real plateau or a 10k transient?
EXTRA_CHECKPOINTS = (20000, 50000, 100000)

# L2 pre-registered target bands for max|h| after radial equalisation.
SHIFT_NORM_SET = (10, 8, 6)

# S1 pre-registered Wh update-rate divisors. None = every transaction.
WH_RATE_SET = (2, 4, 8, 16)

# Scale-target band for max|h|, pre-registered. 703 was the value at the best
# AUC (0.741) measured on the base law, so the set brackets it.
SCALE_TARGET_SET = (256, 512, 1024, 2048)

# Two-sided controller bands, pre-registered. The 800-3100 window is READ OFF
# the E6 selection-seed data, so a selection-seed run with these bands is
# development, not confirmation. The confirmation seed set exists for that.
BAND_SET = ((800, 3100), (512, 2048), (1024, 4096))


class TripletTwin(Eam03eTwin):
    """Adds one atomic (A, P, N) transaction. PAIR is left untouched.

    ``attribution`` selects how E is credited:

    ``broadcast``  the shipped rule. Every byte occurrence of every string gets
                   the delta of the vector it came from. A byte present in more
                   than one of A/P/N therefore receives contradictory signs in
                   succession, and since ``sgn(gA) = sgn(hN - hP)`` the shared
                   rows are dragged by the *negative*.
    ``exclusive``  a byte is updated only if it occurs in exactly one of the
                   three strings. Tests whether the contradictory-sign path is
                   what produces sub-chance ordering once the recurrence is
                   bounded. Single variable; nothing else changes.
    """

    attribution = "broadcast"
    wh_clamp: int | None = None
    # S3: power-of-two restoring force on Wh, applied every transaction that
    # writes. `Wh -= Wh >> sh` is one shift and one subtract in hardware, and it
    # is zero for |Wh| < 2^sh, so it only pulls back entries that have grown.
    # A hard bound caps magnitude but still permits every entry to sit on the
    # rail; a decay gives Wh an interior fixed point where drift balances pull.
    wh_decay_sh: int | None = None
    # L2 (`eam03e-a02-triplet-norm-v1`): cheap radial equalisation. Right-shift
    # the whole state vector by a power of two until max|h| falls inside a target
    # band, so every vector carries comparable radial magnitude. Shift-only: no
    # divide, no sqrt. The +-1 projection is homogeneous in positive scale, so a
    # positive rescale cannot change the 64-bit cue.
    #
    # Justified by results/A7-EAM-03E/E3_NORM_DIAG/: the L1/cosine disagreement
    # bucket carries ~2.8x the radial asymmetry of the agreement bucket, on all
    # three probed seeds, with spearman(M_L1, rP-rN) and spearman(M_cos, rP-rN)
    # of opposite sign.
    shift_norm_band: int | None = None
    # S1 (roadmap section 6 E2-A): reduce the *rate* at which Wh moves, leaving
    # the step size at +-1 and the E law untouched. Wh is written only on every
    # Nth updating transaction. Distinct from S2, which bounds magnitude and then
    # saturates at the bound, and from S3, which applies a restoring force every
    # step. Purpose is to falsify the recurrent-drift hypothesis by a third,
    # independent route rather than leaving it half-tested.
    wh_rate_div: int | None = None
    # Scale-targeted decay. Measured in results/A7-EAM-03E/A02_L_S3/horizon100k:
    # AUC tracks max|h| almost monotonically (150 -> 0.45, 419 -> 0.61,
    # 703 -> 0.74, back to 291 -> 0.50). Too large saturates at 32767, too small
    # is destroyed by the >>5 quantisation in d1. A fixed decay rate cannot hold
    # a band: >>3 overshoots down to ~150 within 32 updates, gentler shifts let
    # Wh run away instead. So gate the decay on the measured state scale rather
    # than applying it unconditionally. One comparison against an existing
    # register on chip.
    scale_target: int | None = None
    _last_scale: int = 0
    # Two-sided Wh regulation with a deadband. E6 falsified the one-sided gate:
    # removing decay below a threshold is *worse* than unconditional decay,
    # because nothing then raises scale and nothing bounds it either. Measured in
    # results/A7-EAM-03E/E6_SCALE_TARGET1024: best AUC sits at max|h| between
    # roughly 800 and 3100, unconditional S3 regulates tightly but at 275-611,
    # i.e. below the band, and weakening the decay loses control entirely.
    #
    #   max|h| > t_hi : Wh -= Wh >> decay_sh      (pull down, as S3)
    #   max|h| < t_lo : |Wh| += 1                 (push up, mirror of S3)
    #   otherwise     : leave Wh alone            (deadband)
    #
    # The upward action is one increment on the magnitude, saturating at the
    # existing sat8 rail, so it costs a sign test and an add on chip.
    band_lo: int | None = None
    band_hi: int | None = None

    def _radial_equalise(self, h: list[int]) -> list[int]:
        if self.shift_norm_band is None:
            return h
        m = max((abs(v) for v in h), default=0)
        if m == 0:
            return h
        target = 1 << self.shift_norm_band
        sh = 0
        while (m >> sh) > target:
            sh += 1
        if not sh:
            return h
        return [v >> sh if v >= 0 else -((-v) >> sh) for v in h]

    def triplet(self, a: str, p: str, n: str, margin: int) -> dict:
        ta = self._fwd_text(a)
        tp = self._fwd_text(p)
        tn = self._fwd_text(n)

        d_pos = self._d1(ta.h_final, tp.h_final)
        d_neg = self._d1(ta.h_final, tn.h_final)

        # hinge: L = max(0, d_pos - d_neg + m). Satisfied margin => no write,
        # which is the contract's anti-overtraining requirement.
        active = (d_pos - d_neg + margin) > 0
        rec = {"d_pos": d_pos, "d_neg": d_neg, "active": active,
               "e_writes": 0, "wh_writes": 0}

        if not (self.learn and not self.freeze) or not active:
            self.pair_count += 1
            return rec

        hA, hP, hN = ta.h_final, tp.h_final, tn.h_final
        # pull A and P together, push A and N apart, in one combined step
        gP = [s16(hP[k] - hA[k]) for k in range(E3_D)]
        gN = [s16(hA[k] - hN[k]) for k in range(E3_D)]
        gA = [s16((hA[k] - hP[k]) + (hN[k] - hA[k])) for k in range(E3_D)]

        seqs = (list(a.encode("utf-8")), list(p.encode("utf-8")), list(n.encode("utf-8")))
        skip: set[int] = set()
        if self.attribution == "exclusive":
            sets = [set(s) for s in seqs]
            for b in sets[0] | sets[1] | sets[2]:
                if sum(1 for s in sets if b in s) > 1:
                    skip.add(b)
            rec["bytes_skipped"] = len(skip)

        for seq, g in zip(seqs, (gA, gP, gN)):
            for b in seq:
                if b in skip:
                    continue
                base = b * E3_D
                for i in range(E3_D):
                    self.e_ra = base + i
                    s = sgn8(g[i])
                    if s:
                        self.E[base + i] = sat8(self.E[base + i] - s)
                        rec["e_writes"] += 1

        # Wh from the anchor only. The anchor is the one vector present in both
        # hinge terms, so it is the single defensible choice that keeps this
        # patch to one unknown; widening it to P and N is a separate experiment.
        skip_wh = (self.wh_rate_div is not None
                   and (self.update_count % self.wh_rate_div) != 0)
        for i in range(0 if skip_wh else E3_D):
            gi = gA[i]
            if sgn8(gi) == 0:
                continue
            row = i * E3_D
            for j in range(E3_D):
                hj = ta.hprev[j]
                if hj == 0:
                    continue
                wdelta = 1 if (gi < 0) == (hj < 0) else -1
                self.Wh[row + j] = sat8(self.Wh[row + j] - wdelta)
                rec["wh_writes"] += 1

        self._last_scale = max((abs(v) for v in hA), default=0)

        if self.band_lo is not None and self._last_scale < self.band_lo:
            # below the band: raise the recurrent gain by one step
            wh = self.Wh
            for k in range(WH_SIZE):
                v = wh[k]
                if v > 0:
                    wh[k] = sat8(v + 1)
                elif v < 0:
                    wh[k] = sat8(v - 1)
                else:
                    wh[k] = 1
            rec["band"] = "below"
        elif self.band_hi is not None and self._last_scale <= self.band_hi:
            rec["band"] = "inside"          # deadband: leave Wh alone

        decay_now = self.wh_decay_sh is not None and (
            (self.band_hi is not None and self._last_scale > self.band_hi)
            if self.band_hi is not None
            else (self.scale_target is None or self._last_scale > self.scale_target))
        if decay_now:
            rec["band"] = "above"
            sh = self.wh_decay_sh
            wh = self.Wh
            for k in range(WH_SIZE):
                v = wh[k]
                if v > 0:
                    wh[k] = v - (v >> sh)
                elif v < 0:
                    nv = -v
                    wh[k] = -(nv - (nv >> sh))

        if self.wh_clamp is not None:
            lo, hi = -self.wh_clamp, self.wh_clamp
            wh = self.Wh
            for k in range(WH_SIZE):
                v = wh[k]
                if v > hi:
                    wh[k] = hi
                elif v < lo:
                    wh[k] = lo

        self.update_count += 1
        self.pair_count += 1
        return rec

    # helpers ------------------------------------------------------------
    def _fwd_text(self, text: str):
        self.buf(0, text)
        tr = self._forward(self.seqA, text)
        if self.shift_norm_band is not None:
            tr.h_final = self._radial_equalise(tr.h_final)
            tr.hprev = self._radial_equalise(tr.hprev)
        return tr

    @staticmethod
    def _d1(ha, hb) -> int:
        d = 0
        for i in range(E3_D):
            v = ha[i] - hb[i]
            ad = ((-v) if v < 0 else v) >> 5
            d = 0xFFFF if d > 0xFFFF - ad else d + ad
        return d


def build_triplets(rows: list[Pair], seed: int = 0) -> list[tuple[str, str, str]]:
    """(anchor, positive, negative) with the negative drawn from another entity."""
    rng = random.Random(seed)
    pos = [p for p in rows if p.same]
    pool: dict[int, list[str]] = {}
    for p in rows:
        pool.setdefault(p.entity_a, []).append(p.a)
        pool.setdefault(p.entity_b, []).append(p.b)
    ents = sorted(pool)
    out = []
    for p in pos:
        for _ in range(8):
            e = rng.choice(ents)
            if e != p.entity_a and e != p.entity_b and pool[e]:
                out.append((p.a, p.b, rng.choice(pool[e])))
                break
    rng.shuffle(out)
    return out


def sweep_seed(seed: int, triplets, eval_rows, checkpoints, margin: int,
               attribution: str = "broadcast", wh_clamp: int | None = None,
               wh_decay_sh: int | None = None,
               shift_norm: int | None = None,
               wh_rate: int | None = None,
               scale_target: int | None = None,
               band: tuple | None = None) -> dict:
    t = TripletTwin(seed)
    t.attribution = attribution
    t.wh_clamp = wh_clamp
    t.wh_decay_sh = wh_decay_sh
    t.shift_norm_band = shift_norm
    t.wh_rate_div = wh_rate
    t.scale_target = scale_target
    if band is not None:
        t.band_lo, t.band_hi = band
    writes = {"E": 0, "Wh": 0}
    series = []
    todo = sorted(set(checkpoints))
    if todo and todo[0] == 0:
        series.append(stab.measure(t, eval_rows, writes))
        todo.pop(0)
    idx = 0
    active = 0
    seen = 0
    while todo:
        target = todo[0]
        t.mode(learn=True, freeze=False)
        while t.update_count < target:
            a, p, n = triplets[idx % len(triplets)]
            idx += 1
            r = t.triplet(a, p, n, margin)
            seen += 1
            active += 1 if r["active"] else 0
            writes["E"] += r["e_writes"]
            writes["Wh"] += r["wh_writes"]
            if seen > 400000:
                break
        series.append(stab.measure(t, eval_rows, writes))
        todo.pop(0)
    return {"seed": f"0x{seed:08X}", "margin": margin, "series": series,
            "attribution": attribution, "wh_clamp": wh_clamp, "wh_decay_sh": wh_decay_sh, "shift_norm": shift_norm, "wh_rate": wh_rate, "scale_target": scale_target, "band": list(band) if band else None,
            "transactions": seen, "hinge_active": active,
            "hinge_active_frac": round(active / max(1, seen), 4)}


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--margins", default=",".join(str(m) for m in MARGIN_SET))
    ap.add_argument("--seeds", type=int, default=len(stab.SEEDS))
    ap.add_argument("--max-updates", type=int, default=stab.CHECKPOINTS[-1])
    ap.add_argument("--long-horizon", action="store_true",
                    help="checkpoints 0/10k/20k/50k/100k to separate a real plateau"
                         " from a 10k transient")
    ap.add_argument("--out", default="results/A7-EAM-03E/A02_L")
    ap.add_argument("--attribution", choices=("broadcast", "exclusive"),
                    default="broadcast")
    ap.add_argument("--band", default="",
                    help=f"two-sided controller 'lo,hi', pre-registered {BAND_SET}")
    ap.add_argument("--seed-set", choices=("selection", "confirmation"),
                    default="selection",
                    help="'confirmation' uses seeds never available to any law "
                         "selection; required before calling a threshold a property "
                         "of the law rather than a development fit")
    ap.add_argument("--scale-target", type=int, default=None,
                    help=f"gate S3 decay on max|h| > target, pre-registered {SCALE_TARGET_SET}")
    ap.add_argument("--wh-rate", type=int, default=None,
                    help=f"S1 Wh update-rate divisor, pre-registered {WH_RATE_SET}")
    ap.add_argument("--shift-norm", type=int, default=None,
                    help=f"L2 radial equalisation band, pre-registered {SHIFT_NORM_SET}")
    ap.add_argument("--wh-decay-sh", type=int, default=None,
                    help=f"S3 restoring force: Wh -= Wh>>sh. Pre-registered {DECAY_SH_SET}")
    ap.add_argument("--wh-clamp", type=int, default=None,
                    help=f"from the pre-registered set {stab.WH_CLAMP_SET}")
    args = ap.parse_args()

    band = None

    if args.band:

        band = tuple(int(x) for x in args.band.split(','))

        if band not in BAND_SET:

            print(f"REFUSE: band {band} not in pre-registered set {BAND_SET}")

            return 2

    if args.scale_target is not None and args.scale_target not in SCALE_TARGET_SET:

        print(f"REFUSE: scale-target not in pre-registered set {SCALE_TARGET_SET}")

        return 2

    if args.wh_rate is not None and args.wh_rate not in WH_RATE_SET:

        print(f"REFUSE: wh-rate not in pre-registered set {WH_RATE_SET}")

        return 2

    if args.shift_norm is not None and args.shift_norm not in SHIFT_NORM_SET:

        print(f"REFUSE: shift-norm band not in pre-registered set {SHIFT_NORM_SET}")

        return 2

    if args.wh_decay_sh is not None and args.wh_decay_sh not in DECAY_SH_SET:

        print(f"REFUSE: decay shift not in pre-registered set {DECAY_SH_SET}")

        return 2

    if args.wh_clamp is not None and args.wh_clamp not in stab.WH_CLAMP_SET:
        print(f"REFUSE: clamp not in pre-registered set {stab.WH_CLAMP_SET}")
        return 2

    margins = [int(x) for x in args.margins.split(",")]
    bad = [m for m in margins if m not in MARGIN_SET]
    if bad:
        print(f"REFUSE: margin {bad} not in pre-registered set {MARGIN_SET}")
        return 2

    gc = golden_check()
    if not gc["pass"]:
        print("REFUSE: twin drifted from A0.1-T goldens", gc["mismatch"])
        return 2
    tw.h_update = stab.h_update_signed   # A0.3 base, validated by RTL + silicon

    base = build_name_dataset(n_entities=stab.DATASET["n_entities"],
                              seed=stab.DATASET["dataset_seed"])
    parts = group_split(base.train + base.dev + base.test,
                        fracs=stab.DATASET["split_fracs"],
                        seed=stab.DATASET["split_seed"])
    ds = Dataset(name="a02l", train=parts["train"], dev=parts["dev"], test=parts["test"])
    leak = assert_no_leakage(ds)
    eval_rows = ds.test[:stab.EVAL_CAP]
    triplets = build_triplets(ds.train, seed=0)
    if args.long_horizon:
        cps = [0, 10000, 20000, 50000, 100000]
    else:
        cps = [c for c in tuple(stab.CHECKPOINTS) + EXTRA_CHECKPOINTS
           if c <= args.max_updates]

    out_dir = ROOT / args.out
    out_dir.mkdir(parents=True, exist_ok=True)
    partial = out_dir / "partial_by_seed.jsonl"
    partial.write_text("", encoding="utf-8")

    rows = []
    seeds_used = (stab.SEEDS if args.seed_set == "selection"
                  else confirmation_seeds(11))
    for m in margins:
        print(f"--- triplet hinge, margin m = {m}"
              f"{'  (contract default E3_MARG)' if m == 4096 else ''} ---", flush=True)
        for seed in seeds_used[:args.seeds]:
            r = sweep_seed(seed, triplets, eval_rows, cps, m,
                           attribution=args.attribution, wh_clamp=args.wh_clamp,
                           wh_decay_sh=args.wh_decay_sh,
                           shift_norm=args.shift_norm, wh_rate=args.wh_rate,
                           scale_target=args.scale_target, band=band)
            r["verdict"] = stab.verdict(r["series"])
            rows.append(r)
            # Append as we go. A long run killed part-way (terminal reset, machine
            # sleep) otherwise loses every completed seed, which happened once.
            with partial.open("a", encoding="utf-8") as fh:
                fh.write(json.dumps(r) + "\n")
            v = r["verdict"]
            last = r["series"][-1]
            print(f"{r['seed']}  auc {v['auc_init']:.3f} -> peak {v['auc_peak']:.3f}"
                  f" @{v['auc_peak_at_updates']} -> final {v['auc_final']:.3f}"
                  f"  rank {v['rank_init']}->{v['rank_final']}"
                  f"  M_L1 {last['M_L1']}  M_cos {last['M_cos']}"
                  f"  hinge_on {r['hinge_active_frac']:.2f}"
                  f"  {'PASS' if v['pass'] else 'FAIL'}", flush=True)

    n_pass = sum(1 for r in rows if r["verdict"]["pass"])
    # contract A02 hard stop: worst-seed M_L1 >= 0 and M_cos >= 0, no inversion
    def worst(m: int, key: str):
        vals = [r["series"][-1][key] for r in rows
                if r["margin"] == m and r["series"][-1][key] is not None]
        return min(vals) if vals else None

    hard = {str(m): {"worst_M_L1": worst(m, "M_L1"),
                     "worst_M_cos": worst(m, "M_cos")} for m in margins}

    rec = {
        "phase": "A7-EAM-03E-A0.2-L (twin pre-check)",
        "law": LAW,
        "evidence_class": "REFERENCE_MODEL",
        "rtl_exists": False,
        "base": "eam03e-a03-signed-h-v1 (RTL XSim + silicon exact)",
        "margins_preregistered": list(MARGIN_SET),
        "margins_run": margins,
        "attribution": args.attribution,
        "wh_clamp": args.wh_clamp,
        "wh_decay_sh": args.wh_decay_sh,
        "shift_norm": args.shift_norm,
        "wh_rate": args.wh_rate,
        "scale_target": args.scale_target,
        "band": list(band) if band else None,
        "band_preregistered": [list(b) for b in BAND_SET],
        "scale_target_preregistered": list(SCALE_TARGET_SET),
        "wh_rate_preregistered": list(WH_RATE_SET),
        "shift_norm_preregistered": list(SHIFT_NORM_SET),
        "decay_preregistered": list(DECAY_SH_SET),
        "wh_update_source": "anchor only",
        "seed_set": args.seed_set,
        "seeds": [f"0x{s:08X}" for s in seeds_used[:args.seeds]],
        "checkpoints_updates": cps,
        "dataset": {**stab.DATASET, "counts": ds.counts(), "leakage": leak,
                    "triplets": len(triplets), "eval_rows": len(eval_rows)},
        "summary": {"runs": len(rows), "stability_pass": n_pass,
                    "worst_seed_hard_stop": hard},
        "runs": rows,
        "ts": datetime.now(timezone.utc).isoformat(),
    }
    out = ROOT / args.out
    out.mkdir(parents=True, exist_ok=True)
    path = out / "triplet_twin_sweep.json"
    path.write_text(json.dumps(rec, indent=2), encoding="utf-8")
    print()
    print(f"runs={len(rows)} stability_pass={n_pass}")
    print("worst-seed hard stop per margin:", json.dumps(hard))
    print(path)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
