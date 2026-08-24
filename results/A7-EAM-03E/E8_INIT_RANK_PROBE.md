# Is the residual failure caused by bad initialisation? Mostly no.

Diagnostic only, no intervention. Evidence class: **REFERENCE MODEL**, using
runs already archived plus a 200-seed initialisation scan.

## Why the question was asked

Under the best configuration by the locked order — triplet hinge + unconditional
S3 decay `>>3` at 100k — exactly two of eleven seeds fail the non-inversion hard
stop. Comparing those two against the nine that pass:

| quantity | FAIL (2 seeds) | PASS (9 seeds) |
|----------|--------------:|---------------:|
| **rank at update 0** | **26.5** [26, 27] | **32.0** [32, 32] |
| AUC untrained | 0.5 | 0.7 |
| saturation at update 0 | 0.3 | 0.2 |
| `max|h|` final | 302 | 513 |
| `Wh_l1` final | 4208 | 6525 |
| `d_pos` median final | **1.0** | 34.9 |
| `d_neg` median final | 51 | 124 |
| `unique_d1` final | 20.5 | 28.3 |

All nine passing seeds start at rank exactly 32/32; both failing seeds start
below it. That looked like the whole story: the failure is present in the random
initialisation, before any learning, and no learning law can be blamed for it.

## Tested across every law already run, and it does not hold

`rank at update 0` is a property of the seed alone — confirmed, each seed reports
one value regardless of which law ran:

```
0x7A9BE636 -> 27      0xEC62BC77 -> 26      all nine others -> 32
```

Pooling all 77 archived runs across base S3, S3-10k, S1, E4 attribution, L2, E6
and E7:

| initialisation | runs | `M_L1 < 0` at the end | rate |
|----------------|-----:|---------------------:|-----:|
| rank@0 < 32 | 14 | 6 | **42.9%** |
| rank@0 = 32 | 63 | 16 | **25.4%** |

Low initial rank raises the failure rate from about a quarter to about four
tenths. That is a real effect in the expected direction, but it is **not** an
explanation: seeds that start at full rank 32 still invert a quarter of the time,
and 14 runs is a thin sample for the low-rank arm.

**So the two-seed pattern was over-read.** It is a correlation of modest strength,
not the cause. "Fix the initialisation" is therefore not the lever, and that lane
is closed before any effort went into it.

## How common is a degenerate start

200 seeds derived by the published rule at indices 1000–1199:

| rank@0 | seeds | share |
|-------:|-----:|-----:|
| 32 | 144 | 72.0% |
| 31 | 29 | 14.5% |
| 30 | 12 | 6.0% |
| 28 or below | 15 | 7.5% |

So roughly 28% of seeds start below full rank, and the selection set's 2 of 11
(18%) is unremarkable against that. The pre-registered seed set was not unlucky
in any way that needs correcting.

Worth keeping for later: any worst-seed rule applied to this architecture will
sample a sub-32-rank initialisation about a quarter of the time. That is a
property of the seeding procedure, not of a law, and it should be stated whenever
a worst-seed gate is reported rather than discovered again later.

## What this leaves

The residual failure of the standing candidate is **not** explained by
initialisation rank. It is also not explained by recurrent scale — five
interventions on that (S1 rate, S2 bound, S3 decay, E6 one-sided gate, E7
two-sided band) have been run at 11 seeds and 100k, and unconditional S3 remains
the best of them, with every attempt to improve on it making things worse.

Nothing new is opened here. The standing candidate is unchanged and still not a
PASS: worst-seed `M_L1 = −13.316`, worst-seed `M_cos = −0.301`.

## Not claimed

No claim that initialisation is irrelevant — 42.9% versus 25.4% is a real
difference and a larger low-rank sample might sharpen it. No claim about *why*
the xorshift fill sometimes produces rank 26–31. No RTL, XSim or board evidence.
No intervention was applied and no seed was dropped or added.
