# E5 — L2 radial equalisation as a falsification experiment

Prediction under test, stated before the run: if the L1 margin is partly bought
with radial scale, then equalising the radius must remove the dependence of
`M_L1` on radial asymmetry, and the L1/cosine disagreement bucket must shrink.

Base: triplet hinge + S3 decay `>>3` on the signed state update, trained to
100,000 updates. Single change: `shift_norm_band = 8` — right-shift the whole
state vector by a power of two until `max|h|` falls inside the target band.
Shift-only, no divide, no square root. The ±1 projection is homogeneous in
positive scale, so the 64-bit cue is unchanged by construction.

Band set `{10, 8, 6}` pre-registered in `SHIFT_NORM_SET`; the tool refuses
anything outside it. Three seeds, chosen to span the measured `M_cos` range so
the diagnostic is not run only where it flatters. 285 held-out triplets from
`dev + test`, both disjoint from train.

Evidence class: **REFERENCE MODEL**.

## The prediction is confirmed on its own terms

`spearman(M_L1, rP − rN)` measures how much the L1 margin tracks radial
asymmetry. It is the number the hypothesis is about.

| seed | without L2 | with L2 |
|------|----------:|--------:|
| 0x11111111 | −0.189 | **+0.001** |
| 0xAE7C9805 | −0.167 | **+0.063** |
| 0xFB8CACAA | −0.091 | **−0.029** |

The dependence collapses to zero on all three seeds. The radial channel into the
L1 margin is closed.

The equalisation itself did what it should. Mean `rN` inside the disagreement
bucket:

| seed | without L2 | with L2 |
|------|----------:|--------:|
| 0x11111111 | 5.07 | 1.20 |
| 0xAE7C9805 | 3.11 | 1.57 |
| 0xFB8CACAA | 2.67 | 1.60 |

Radii that were 3–5× the anchor are now within 1.2–1.6×.

The sign of the disagreement also flips, which is the clearest single sign that
the diagnosis was right. Without L2, the disagreement bucket had mean
`M_L1 = +95.5 / +38.0 / +50.4` against negative `M_cos` — large L1 margins that
angle did not support, i.e. false positives inflated by radius. With L2 the same
bucket has mean `M_L1 = −9.6 / −14.9 / +4.2`. Removing the radial inflation
removed the spurious positive margins.

## And the remedy is only partial

`spearman(M_cos, rP − rN)` barely moves: +0.205/+0.110/+0.130 becomes
+0.157/+0.124/+0.174. The disagreement fraction does not clear:

| seed | DISAGREE without L2 | with L2 |
|------|-------------------:|--------:|
| 0x11111111 | 14.7% | **7.0%** |
| 0xAE7C9805 | 8.4% | **6.0%** |
| 0xFB8CACAA | 5.6% | **10.9%** |

Two seeds improve, one gets worse. The residual disagreement carries no radial
signature — median `|rP − rN|` in the disagreement bucket is down from ~1.4–1.9
to ~0.47–0.87, yet disagreement persists. By construction a radial equalisation
cannot touch an angular disagreement, and what is left is angular.

So the honest reading is: the radial channel was **a** cause and is now closed;
it was not **the** cause. The `M_cos` gate is not rescued by normalization alone.

This is why the diagnostic was worth running before the sweep. Had L2 been run
as "let us see if AUC improves", the 2-of-3 improvement in disagreement fraction
plus a mixed AUC result would have been ambiguous. Because the causal quantity
was named in advance, the result is unambiguous about the mechanism and
unambiguous that the mechanism is insufficient.

## Standing state after the four locked experiments

| # | experiment | outcome |
|---|-----------|---------|
| 1 | S3 decay sweep, 11 seeds, 4 shifts | shift 3 chosen by the locked lexicographic rule; stability 11/11, no-inversion 11/11 **at 10k** |
| 2 | horizon 10k → 100k | 10k was transient. At 100k: rank 8–11 on 9/11, `M_L1 > 0` on 9/11, worst `M_L1 = −13.316`, best AUC 0.753 with two seeds still climbing at the horizon |
| 3 | byte attribution, 11 seeds, 100k | FAIL. `M_L1 > 0` on 0/11, ΔAUC negative on 11/11. Dropped |
| 4 | L2 radial equalisation | mechanism confirmed, remedy partial. `M_cos` gate still open |

Standing candidate is unchanged: **triplet hinge + S3 decay `>>3`**, without
attribution and without L2. It is not a PASS. Worst-seed `M_L1 = −13.316` and
worst-seed `M_cos = −0.301` both fail the contract A02 hard stop.

Whether to keep L2 in the candidate is genuinely open on this evidence: it makes
the L1 margin honest, which is a property worth having even though it does not
close the gate, and it costs one shift in hardware. That decision should be made
on an 11-seed sweep, not on three probe seeds — that sweep has not been run.

## Method note worth carrying forward

Three times in this program a short-horizon or few-seed screen pointed the
opposite way from the full pre-registered run: S3 (10k non-inversion vanished at
100k), ungated DIFF (short-horizon margin `+1545`, total collapse at 100k), and
byte attribution (`M_cos` positive 4/4 at 10k, negative 10/11 at 100k). The L2
smoke run at 2000 updates on one seed also looked bad while the causal test
confirmed the mechanism.

Screens in this system are not weak evidence in the usual sense — they are
frequently sign-reversed. Only the full pre-registered configuration is
admissible for a verdict.

## Not claimed

No RTL, no XSim, no board for L2 or for the triplet law. No claim that L2
improves AUC — that was not measured here and the one short screen that touched
it was unfavourable. No claim about bands 10 or 6. No claim that the `M_cos`
gate can be closed by normalization; the evidence says it cannot.
