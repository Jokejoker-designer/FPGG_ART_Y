# A0.2-L + S3 — the collapse is broken

> **SUPERSEDED IN PART, 2026-08-21.** Every number below is measured at a
> 10,000-update horizon. Extending the same configuration to 100,000 updates
> shows the non-inversion result does **not** hold: seed `0x7A9BE636` reaches
> `M_L1 = -13.316`, `M_cos = -0.301`, AUC 0.479. So the claim in this document
> that the contract A02 hard stop passes is **true at 10k and false at 100k**.
> The stability result (rank 9-11, saturation 0.000) does survive the longer
> horizon on the seeds measured so far. See
> `results/A7-EAM-03E/A02_L_S3/horizon100k/`.
>
> The correction is left in place rather than editing the numbers below, because
> the 10k table is still the correct record of what a 10k horizon shows — and
> the gap between the two horizons is itself the finding.

Law under test: triplet hinge (`eam03e-a02-triplet-v1`) on the signed state
update (`eam03e-a03-signed-h-v1`, RTL XSim- and silicon-exact), plus **S3**: a
power-of-two restoring force on the recurrent weights,
`Wh -= Wh >> 3`, applied on every transaction that writes.

Evidence class: **REFERENCE MODEL**. No RTL for this combination.
11 pre-registered seeds, 10 checkpoints, `m = 4096`, same dataset, split and
`assert_no_leakage` as every other sweep in this program. Decay shift set
`{6, 5, 4, 3}` frozen in `DECAY_SH_SET`; the tool refuses anything outside it.

## Verdict

`A0.2-L+S3: FAIL` on the full §8 stability gate — but the degeneracy that
defeated the previous four law variants is gone, on every seed.

| Check | Requirement | Result |
|-------|-------------|--------|
| `effective_rank` noncollapsed | >= 8 | **PASS 11/11** (9–11) |
| hidden saturation | far below total | **PASS 11/11** (0.000 on every seed) |
| `unique_d1_count` | > 1 | **PASS 11/11** (27–32) |
| worst-seed `M_L1` | >= 0 | **PASS** (+0.011) |
| `M_L1 > 0` per seed | — | **11/11** |
| AUC final | not ~0.5 | 10/11 (0x EC62BC77 at 0.512) |
| AUC_post > AUC_init | all seeds | **FAIL 5/11** |
| worst-seed `M_cos` | >= 0 | **FAIL** (−0.254), positive on 5/11 |

## What changed, and why it worked

Every previous variant ended in the same absorbing state: `‖Wh‖₁` fully
saturated, `h` a bang-bang pattern identical for all inputs, all distances zero,
`effective_rank` 1. The A0.2-L closeout localised the cause to the recurrence
forgetting its input, and the A0.3-S closeout wrongly concluded that a hard
bound covered every way of controlling it.

The distinction it missed: **SignSGD on `Wh` has no fixed point.** Every
transaction writes ±1 into nearly every entry, with nothing pulling back, so
`Wh` random-walks with drift until every entry reaches whatever rail exists —
the `sat8` rail at ±128, or the S2 clamp, whichever is lower. Measured under S2
at clamp ±32, `‖Wh‖₁` ends at exactly 32768 = 1024 × 32: total saturation. A cap
does not remove the drift, it only decides where the drift stops.

`Wh -= Wh >> 3` gives the drift something to balance against. It is zero for
`|Wh| < 8`, so it only pulls back entries that have grown, and it costs one shift
and one subtract in hardware.

Measured equilibrium:

| Seed | `‖Wh‖₁` initial | `‖Wh‖₁` final | full saturation would be |
|------|---------------:|-------------:|-------------------------:|
| 0x11111111 | 64696 | **6081** | 131072 |
| 0x7A9BE636 | 67612 | **5564** | 131072 |
| 0x37410899 | 65382 | **6371** | 131072 |

`Wh` settles at roughly 5% of its saturation value rather than reaching it. With
the recurrence gain held there, `h` never rails: hidden saturation is **0.000 on
all 11 seeds**, where every earlier variant ended between 0.46 and 1.00.

## The headline number

Seed `0x22222222` is the seed this entire investigation started from. It was the
documented discriminative failure, reproduced exactly on silicon:

```
before:  SAME 2135 -> 1487,  DIFF 1679 -> 229,  M_L1 = 229 - 1487 = -1258
now:     M_L1 = +20.185,  effective_rank 10,  AUC 0.567
```

The inversion is gone, and it is gone on every seed: `M_L1 > 0` on 11 of 11,
worst case +0.011. That is the contract A02 minimum non-inversion hard stop,
met for the first time in the program, on the pre-registered seed set with
nothing dropped and no margin tuning — `m` stayed at the contract's `E3_MARG`
value of 4096 throughout.

## What still fails, stated plainly

**`M_cos` is negative on 6 of 11 seeds**, worst −0.254. The contract requires
worst-seed `M_cos >= 0` for closure. So the L1 distance now orders pairs
correctly while the angular measure does not agree. Per the A02 observation
table, `M_L1 > 0` with `M_cos < 0` is the case where the norm is carrying the
margin rather than the direction — the mirror image of the situation that table
was written for.

**AUC improves on only 5 of 11 seeds.** The five that improve all started low
(0.457, 0.490, 0.519, 0.620, 0.705); the six that decline all started high
(0.633–0.697) and land between 0.567 and 0.668. Training pulls every seed toward
roughly 0.55–0.65 regardless of where it began. That is a ceiling, not a
collapse: the law converges to a modest but real level, and the untrained seed
lottery sometimes starts above it.

**Five of eleven seeds are still improving at 10,000 updates** (peak at the
horizon), so the horizon itself may be too short to characterise the ceiling.
That is a measurement gap, not a result.

## Where this leaves the program

The four-variant sequence is now:

| Variant | Terminal state | Verdict |
|---------|---------------|---------|
| shipped (unsigned `h`) | dead absorbing state, zero weight writes | FAIL |
| signed `h` | `Wh` runaway, rank → 1 | FAIL |
| signed + S2 clamp | `Wh` fully railed at the clamp, sub-chance AUC | FAIL |
| signed + triplet hinge | rank → 1, `M_L1` = 0 | FAIL |
| **signed + triplet + S3 decay** | **rank 9–11, no saturation, `M_L1` > 0 on 11/11** | FAIL on `M_cos` and on AUC_post > AUC_init |

Each earlier repair uncovered the next defect. This one does not: it removes the
degeneracy without introducing a new failure mode, and what remains is a quality
problem rather than a collapse.

`A1`, `Kidi` and `NATIVE-V1` stay **CLOSED**. An encoder at AUC 0.55–0.72 with
`M_cos` negative on half the seeds is not a basis for a retrieval claim, and the
hard stop against gluing frozen 01R/02M/LM-06 onto a weak encoder applies to
weak as well as to degenerate.

Next, one unknown at a time, in this order:

1. **Decay shift sweep on the full seed set.** Only shift 3 was run on all 11
   seeds; shift 4 screened better on two of four seeds (peak at the horizon,
   `M_L1` up to 7386). The set `{6, 5, 4, 3}` is pre-registered, so this is a
   declared dose-response.
2. **Longer horizon.** Five seeds are still improving at 10,000 updates. Extend
   before drawing a ceiling.
3. **The `M_cos` disagreement.** Diagnose whether the margin is carried by norm
   rather than direction, which is what the A02 table predicts for this signature
   and which the cheap shift-norm (L2, `eam03e-a02-triplet-norm-v1`) exists for.
   Note the earlier reason for not opening L2 no longer applies: norms do not
   collapse here, they behave, so L2 must be justified on the `M_cos` evidence
   instead of on norm collapse.
4. **Byte attribution.** The `exclusive` ablation (a byte occurring in more than
   one of A/P/N receives no update) raised peaks from 0.575/0.593/0.651 to
   0.626/0.732/0.677 and made `M_cos` positive on 4 of 4 screened seeds. It did
   not stop the collapse on its own, but combined with S3 it is the most
   promising remaining lever on `M_cos`. Screening only: 4 seeds, not 11.

Only after a law passes both hard stops should RTL be written for it, and then
its own contract must be frozen first.

## Artifacts

| File | Content |
|------|---------|
| `triplet_twin_sweep.json` | 11 seeds × 10 checkpoints, full telemetry |
| `tools/a7eam03e_a02l_twin.py --wh-decay-sh 3` | the experiment |

## Not claimed

No RTL, no XSim, no board for this law combination. The A0.3 signed base is
silicon-exact; S3 and the triplet hinge are reference-model only. No claim that
this encoder is good enough for retrieval. No claim about decay shifts 6, 5 or 4
on the full seed set. `M_cos` is not passed and is not presented as passed.
