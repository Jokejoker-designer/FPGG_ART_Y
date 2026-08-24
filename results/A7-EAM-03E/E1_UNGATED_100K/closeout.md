# E1 — ungated DIFF at the 100k horizon: NO-GO, 11/11

Law: `eam03e-a03-ungated-diff-v1`. Base `eam03e-a03-signed-h-v1` (RTL XSim- and
silicon-exact). No decay, no clamp, no triplet, no glue — exactly the freeze list
in `NATIVE_AI_V1_ROADMAP.md` §3.

Evidence class: **REFERENCE MODEL**. 11 pre-registered seeds, checkpoints
`0 … 10000` plus `20000, 50000, 100000`, `m` untouched, same dataset, split and
`assert_no_leakage` as every other sweep.

## Hard sanity gate: PASS

Roadmap §3 requires proof that the law really is ungated:

```
diff_seen = 284251   diff_push_count = 284251   diff_suppressed_count = 0   PASS
```

For contrast, the same telemetry on the shipped gated law over a short run gives
`seen 63, pushed 18, suppressed 45`. **71% of negatives receive no repulsive
update under the gated law.** That is the H5 mechanism, measured directly for the
first time rather than inferred, and it confirms the mechanism description in
`MUST_READ_UNBLOCK_H5.md` lines 13-21 is accurate.

So the implementation is correct and the diagnosis of *what the gate does* is
correct. What follows is about whether removing it is the remedy.

## Result: total collapse on every seed

| Seed | AUC init | peak | at | AUC final | rank | unique d1 |
|------|--------:|-----:|---:|---------:|-----:|----------:|
| 0x11111111 | 0.519 | 0.662 | 32 | 0.500 | 1 | 1 |
| 0x7A9BE636 | 0.457 | 0.675 | 256 | 0.500 | 1 | 1 |
| 0x37410899 | 0.651 | 0.679 | 32 | 0.500 | 3 | 1 |
| 0xAE7C9805 | 0.695 | 0.716 | 32 | 0.500 | 3 | 1 |
| 0x68323257 | 0.697 | 0.732 | 1000 | 0.500 | 1 | 1 |
| 0xEC62BC77 | 0.490 | 0.684 | 512 | 0.500 | 1 | 1 |
| 0xE6C4400D | 0.697 | 0.697 | 0 | 0.500 | 3 | 1 |
| 0xFB8CACAA | 0.620 | 0.697 | 128 | 0.500 | 1 | 1 |
| 0xB2B49299 | 0.705 | 0.705 | 0 | 0.500 | 1 | 1 |
| 0xCCAC16C3 | 0.633 | 0.644 | 32 | 0.500 | 1 | 1 |
| 0x22222222 | 0.688 | 0.688 | 0 | 0.500 | 1 | 1 |

`effective_rank` falls to 1 or 3, `unique_d1_count` to 1, AUC to exactly 0.500 —
on all eleven seeds. Peaks land at 32–1000 updates and nothing survives to 100k.

Per roadmap §4, any seed showing rank collapse or distance degeneration is a
NO-GO and means **H5 is not the sole cause**. Eleven of eleven show it.

## Side-by-side at the same horizon

Both runs are 11 seeds, 100k updates, identical dataset, split, seeds and eval
set. The only differences are the two levers named in each row.

| configuration | rank final | unique d1 | AUC final | M_L1 > 0 | best AUC |
|---------------|-----------:|----------:|----------:|---------:|---------:|
| **ungated DIFF, no decay** | 1–3 | 1 | 0.500 on 11/11 | — (all distances 0) | 0.500 |
| triplet hinge + S3 `>>3` | 8–11 on 9/11 | 27–32 | 0.479–0.753 | **9/11** | **0.753** |

Ungated DIFF alone is the **worst** configuration measured in this program: it is
the only one where every seed lands exactly at chance. The configuration the
roadmap schedules last is the only one that holds rank and reaches 0.75.

## Reconciling with the H5 thesis, precisely

Three separate tests now bear on "the DIFF gate is the bottleneck":

1. 10k, matched gated-vs-ungated control, no decay: final AUC 0.500 both ways.
2. 10k, matched control with S3 decay: 0.408 gated vs 0.398 ungated — ungated
   marginally worse.
3. 100k, ungated alone, sanity gate passing: 11/11 total collapse.

The gate's *description* in `MUST_READ` is right, and the 71%-suppression number
confirms it quantitatively. The *inference* that removing it fixes the encoder is
falsified at every horizon tested, with the ungated implementation verified
correct by its own sanity gate.

Why the short-horizon evidence pointed the other way is visible in the table
above: ungated peaks are genuinely good (0.716, 0.732, 0.697) at 32–1000 updates.
A margin read at that point looks excellent. `MUST_READ`'s `+1545` on seed
`0x22222222` is consistent with a short-horizon read; that seed's ungated peak
here is 0.688 at update 0 and it is at 0.500 by 100k. Short-horizon margin is not
evidence that a law holds — the same lesson the S3 10k result taught.

## What the evidence says the mechanism is

Removing the gate makes repulsion unconditional, which raises the early peak, and
it also removes the only thing that was throttling the update stream. With
`E` and `Wh` both driven on every transaction and no restoring force, `Wh`
saturates and the recurrence converges to an input-independent fixed point. The
gate was accidentally acting as a crude rate limiter.

This is consistent with, and does not replace, the earlier finding: the two
levers that matter are a restoring force on `Wh` (S3) and a hinge that makes
attraction and repulsion arrive in the same transaction (triplet). Ungated DIFF
supplies unconditional repulsion without either, which is why it collapses
fastest.

## Verdict and next branch

`E1: NO-GO`. Ungated DIFF is not adopted. No RTL, correctly — the twin
pre-check failed, which is what the pre-check is for.

Roadmap §22 failure branch for this case reads: measure recurrent drift, then
test S1 independently, and test S3 only after H5 is isolated. Two of those three
are already answered by measurement:

- Recurrent drift is measured and real (`A03_SIGNED`: `‖Wh‖₁` doubles;
  `A03_S`: a hard bound saturates at the bound; `A02_L_S3`: a decay settles it at
  ~5% of saturation with hidden saturation 0.000).
- S3 has been run on 11 seeds at four shifts and at 100k on the winner.

So the open item on that branch is **S1** (reduce the `Wh` update rate rather
than its magnitude), which remains pre-registered and untested. It is a
different intervention from both S2 and S3 and is the honest way to finish
falsifying the recurrent-drift family.

Current standing candidate remains triplet + S3 `>>3`, which at 100k gives
9/11 non-inversion, rank 8–11, and two seeds still climbing at the horizon
(0x37410899 at 0.753 and 0xCCAC16C3 at 0.730, both peaking at 100k). It is not a
PASS: worst `M_L1 = -13.316`, worst `M_cos = -0.301`.

## Not claimed

No RTL, no XSim, no board for this law. No claim that the H5 mechanism
description is wrong — it is confirmed. No claim about ungated DIFF combined with
a restoring force beyond the 10k matched control already recorded in
`results/A7-EAM-03E/A03_UNGATED/closeout.md`.
