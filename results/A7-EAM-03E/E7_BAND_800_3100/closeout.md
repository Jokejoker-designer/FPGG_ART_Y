# E7 — two-sided band controller: worse than doing nothing

Law: triplet hinge on signed `h`, decay shift 3, single change — a two-sided
regulator on `max|h|` with a deadband:

```
max|h| > 3100 :  Wh -= Wh >> 3     (pull down, as S3)
max|h| <  800 :  |Wh| += 1         (push up, mirror of S3)
otherwise     :  leave Wh alone    (deadband)
```

Band set `{(800,3100), (512,2048), (1024,4096)}` pre-registered in `BAND_SET`;
the tool refuses anything outside it, verified. 11 **selection** seeds, 100,000
updates, `m = 4096`. Evidence class: **REFERENCE MODEL**.

The 800–3100 window was read off E6's data, so this run is development by
construction and could never have been the confirmation.

## Verdict by the locked decision order

| # | criterion | base S3 unconditional | E6 gate 1024 | **E7 band 800-3100** |
|---|-----------|---------------------:|-------------:|---------------------:|
| 1 | no collapse | **11/11** | 10/11 | 10/11 |
| 2 | no saturation | 11/11 | 11/11 | 11/11 |
| 3 | rank >= 8 | **10/11** | 1/11 | **0/11** |
| 4 | no inversion | 9/11 | 9/11 | 8/11 |
| 5 | `M_cos >= 0` | 5/11 | **9/11** | 6/11 |
| 6 | worst ΔAUC | **−0.097** | −0.169 | −0.180 |
| 7 | median ΔAUC | +0.001 | **+0.108** | **−0.011** |
| — | AUC median | 0.655 | **0.721** | 0.631 |
| — | `max|h|` spread | **275…611** | 384…24399 | **3230…32768** |

E7 fails criterion 1 alongside E6 and then loses criterion 3 outright at 0/11.
**Base — unconditional S3 decay — wins the locked order.** It is first on
criterion 1, ties on 2, and wins criterion 3 decisively.

Median ΔAUC also goes negative for the first time among the scale-control
attempts: training under E7 makes the median seed worse than not training.

## What went wrong, specifically

`max|h|` reaches **32768 on seven of eleven seeds** — the `sat16` rail. The
original defect that A0.3 was built to fix has come back, not through unsigned
arithmetic this time but because the controller drove it there. Saturation rates
follow: 0.44, 0.34, 0.21, 0.10, 0.09 against 0.00 everywhere under base S3.

The upward action is far too strong. Adding 1 to the magnitude of **every one of
the 1024** `Wh` entries on every transaction where `max|h| < 800` is an enormous
aggregate gain increase, nothing undoes it, and the deadband then suppresses all
action from 800 to 3100 — so by the time `h` crosses 3100 and the decay engages,
the state has already blown past it to the rail.

A restoring force and a driving force are not symmetric just because their
arithmetic looks symmetric. `Wh -= Wh >> 3` is proportional, so it self-limits.
`|Wh| += 1` is constant-rate, so it does not.

## What is falsified and what is not

**Falsified:** this controller. A constant-rate upward action with a deadband is
worse than no scale control at all, on every criterion in the locked order.

**Not falsified:** the band hypothesis itself. E7 did not test the 800–3100 band,
it overshot past it — the seeds ended at 3230 and above, mostly at the rail, so
the run contains almost no observations *inside* the window it was meant to hold.
E6's evidence that best AUC sits at `max|h|` 800–3100 stands untouched by this.

What E7 does establish, taken with E6, is a bracket:

- Unconditional proportional decay regulates tightly, at 275–611, **below** the
  productive band. AUC median 0.655.
- Removing decay below a threshold loses control upward, 384–24399. AUC median
  0.721, rank 1/11.
- Adding a constant-rate push loses control worse, 3230–32768 with the rail
  reached. AUC median 0.631, rank 0/11.

So both attempts to move the operating point above 611 have cost rank, and the
one that raised AUC (E6) did so while rank fell to 1/11. Whether the 800–3100
band can be held *with* rank intact remains genuinely open, and nothing tested so
far holds it.

If that is pursued, the honest next form of the upward action is proportional
rather than constant-rate — something like `|Wh| += |Wh| >> k`, so it self-limits
the way the decay does. That is one unknown and it is not opened here.

## Scale-control branch: closed with a negative result

Three interventions on the recurrent scale have now been run at 11 seeds and
100,000 updates:

| intervention | outcome |
|--------------|---------|
| S2 hard bound | AUC below chance on 11/11 |
| S3 unconditional decay `>>3` | **best by the locked order**: rank 10/11, `max|h|` 275–611 |
| E6 one-sided gate | rank 1/11, `max|h|` spread 64× |
| E7 two-sided band | rank 0/11, rail reached on 7/11 |

Plus S1 rate reduction, which collapsed 9/11. Unconditional S3 remains the best
scale controller found, and every attempt to improve on it has made things worse.

## Standing state

Best configuration by the locked order is unchanged and remains **triplet hinge +
unconditional S3 decay `>>3`**: rank >= 8 on 10/11, `M_L1 >= 0` on 9/11,
`max|h|` 275–611, AUC median 0.655, worst-seed `M_L1 = −13.316`, worst-seed
`M_cos = −0.301`. Not a PASS — both hard stops still fail.

No configuration has yet earned a confirmation run on the untouched seed set.
`A1`, `Kidi`, `NATIVE-V1` stay CLOSED. No RTL beyond A0.3, whose bit
`05E478FF…` is XSim- and silicon-exact and untouched.

## Not claimed

No RTL, XSim or board evidence. No claim about bands (512,2048) or (1024,4096) —
pre-registered, unrun, and given that (800,3100) already reached the rail, a
lower band is expected to push harder and rail sooner. No claim that the 800–3100
band is unreachable; only that this controller does not reach it.
