# E2-A — S1 rate reduction: FAIL, and the recurrent-drift branch is now closed

Law: triplet hinge on signed `h`, single change `wh_rate_div = 16` — `Wh` is
written only on every 16th updating transaction, step size unchanged at ±1, `E`
law untouched. No S2, no S3, no attribution, no normalization.

Purpose, per `NATIVE_AI_V1_ROADMAP.md` §6 E2-A: falsify the recurrent-drift
hypothesis by a third independent route rather than leaving it half-tested.

Divisor set `{2, 4, 8, 16}` pre-registered in `WH_RATE_SET`; the tool refuses
anything outside it, verified (`--wh-rate 3` → REFUSE). `N = 16` was chosen and
the choice stated before the run: it is the most extreme member, closest to
freezing `Wh`, so if even it fails to hold stability the rate route is cleanly
falsified.

11 pre-registered seeds, 100,000 updates, `m = 4096`. Evidence class:
**REFERENCE MODEL**.

## Verdict: FAIL 11/11

| Seed | AUC init | peak | at | AUC final | rank | M_L1 | M_cos |
|------|--------:|-----:|---:|---------:|-----:|-----:|------:|
| 0x11111111 | 0.519 | 0.721 | 2000 | 0.500 | 1 | 0.0 | +0.105 |
| 0x7A9BE636 | 0.457 | 0.631 | 512 | 0.500 | 1 | 0.0 | −0.299 |
| 0x37410899 | 0.651 | 0.695 | 512 | **0.663** | 4 | +80.6 | −0.239 |
| 0xAE7C9805 | 0.695 | 0.727 | 128 | 0.500 | 3 | 0.0 | +0.221 |
| 0x68323257 | 0.697 | 0.714 | 512 | 0.500 | 3 | 0.0 | +0.505 |
| 0xEC62BC77 | 0.490 | 0.712 | 512 | 0.500 | 1 | 0.0 | +0.444 |
| 0xE6C4400D | 0.697 | 0.710 | 128 | 0.500 | 1 | 0.0 | −0.229 |
| 0xFB8CACAA | 0.620 | 0.679 | 512 | 0.500 | 1 | 0.0 | −0.202 |
| 0xB2B49299 | 0.705 | **0.765** | 256 | 0.500 | 1 | 0.0 | −0.299 |
| 0xCCAC16C3 | 0.633 | **0.756** | 256 | 0.500 | 1 | 0.0 | −0.242 |
| 0x22222222 | 0.688 | 0.688 | 0 | 0.429 | 6 | **−55.2** | −0.176 |

Nine of eleven reach total degeneracy: rank 1–3, `M_L1` exactly 0, AUC exactly
0.500. Worst-seed `M_L1 = −55.176`, four times worse than S3's −13.316.

Slowing `Wh` by 16× delays the collapse. It does not prevent it.

## The recurrent-drift branch, complete

All three §8 interventions have now been run on 11 seeds at the full horizon:

| intervention | what it does to `Wh` | outcome at 100k |
|--------------|---------------------|-----------------|
| **S1** rate ÷16 | writes 16× less often, same step | collapse 9/11, worst `M_L1` −55.2 |
| **S2** clamp ±8…±128 | bounds magnitude | `‖Wh‖₁` bounded and every entry saturates at the bound; AUC below chance on 11/11 |
| **S3** decay `>>3` | restoring force every step | **only one that holds**: rank 8–11, saturation 0.000, `M_L1 > 0` on 9/11, AUC to 0.753 |

The three are not interchangeable and the difference is now measured rather than
argued. A bound stops growth at a ceiling and lets every weight sit on it. A rate
divisor stretches the same trajectory over more transactions. Only a decay
creates an interior fixed point where drift balances pull, and only that produces
a state that does not rail.

This also completes the correction recorded in `A03_S/closeout.md`, where I
argued S2 was an upper envelope on S1 and S3 and therefore neither needed
running. Both have now been run. S3 beat S2 decisively and S1 lost to both. The
original inference was wrong in both directions.

## The observation that matters more than any single verdict

Every configuration tested in this program — six laws now, at 11 seeds and
100,000 updates — reaches a peak AUC between roughly **0.68 and 0.78** and then
leaves it.

| configuration | best peak observed |
|---------------|------------------:|
| pair, gated, signed | 0.804 |
| pair, ungated | 0.732 |
| **S1 rate ÷16** | **0.765** |
| triplet + S3 `>>3` | 0.753 |
| triplet + S3 + L2 | 0.711 |
| triplet + attribution | 0.560 |

The peak arrives anywhere from update 0 to 20000 depending on seed and law, and
nothing holds it. The two facts together say something specific: **the
representation this architecture can reach is worth about 0.75 AUC, and no
learning law tested can stay there.**

That reframes the remaining problem. It is not "can the encoder learn" — it
demonstrably can, repeatedly, on every seed. It is that every law tested keeps
updating past its own optimum and destroys what it found. The hinge was supposed
to stop when the margin is satisfied, and it does go inactive — `hinge_on` here
ranges 0.43–0.82 — yet the collapse still happens. Under S3 the hinge is active
on 100% of transactions and the collapse is slower but still present on 2 seeds.

So the missing mechanism is plausibly a **stopping or consolidation criterion**
computable on-chip, not another way to shape the update. That direction has not
been tested and is not in any current contract. It would need its own
pre-registration, and it is the first hypothesis in this program that is about
*when* to stop rather than *how* to step.

Stated as a hypothesis, not a result: if the peak is real and reachable, a law
that freezes on a satisfied objective should hold 0.70–0.75 rather than 0.50.
Testing it requires an on-chip criterion, since a host-side early stop would put
the decision outside the FPGA and violate the hardware learning boundary.

## Standing state

Candidate unchanged: **triplet hinge + S3 decay `>>3`**. Not a PASS —
worst-seed `M_L1 = −13.316`, worst-seed `M_cos = −0.301`. It remains the best of
six, and it is the only configuration where the terminal state is not degenerate
on the majority of seeds.

`A1`, `Kidi`, `NATIVE-V1` stay **CLOSED**. No RTL for any law beyond A0.3, whose
bit `05E478FF…` is XSim- and silicon-exact and untouched.

## Methodological record: four short-screen reversals

| screen | screen said | full run at 100k × 11 said |
|--------|------------|---------------------------|
| S3, 10k | non-inversion 11/11 | worst `M_L1` −13.3 |
| ungated DIFF, short horizon | `M_L1 +1545` on one seed | 11/11 total collapse |
| byte attribution, 10k × 4 | `M_cos` positive 4/4 | `M_L1 > 0` on 0/11 |
| **S1, 2000 updates × 1 seed** | **PASS, `M_L1 +3208`, rank 24** | **collapse 9/11, worst `M_L1` −55.2** |

The S1 screen is the sharpest case: it stopped at update 2000, which turned out
to be almost exactly that seed's peak. The screen was not merely optimistic, it
sampled the maximum.

In this system a short screen is not weak evidence — it is frequently
sign-reversed, because every law peaks early and then degrades. Only the full
pre-registered horizon is admissible, and any future screen should be read as
locating a peak rather than as predicting an outcome.

## Not claimed

No RTL, XSim or board evidence for S1. No claim about divisors 2, 4 or 8 — they
remain pre-registered and untested, and given `N = 16` was the most extreme
member, weaker divisors are expected to collapse sooner rather than later. No
claim that a stopping criterion works; it is an untested hypothesis stated as
such.
