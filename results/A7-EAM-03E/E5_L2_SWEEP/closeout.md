# E5 sweep — L2 radial equalisation is dropped

11 pre-registered seeds, 100,000 updates, `m = 4096`, triplet hinge + S3 decay
`>>3`, single change `shift_norm_band = 8`. Control is the identical
configuration without the shift, `results/A7-EAM-03E/A02_L_S3/horizon100k/`.
Separate `--out` directory, so no run shared a path this time.

Evidence class: **REFERENCE MODEL**.

## Verdict: DROP

| metric | control (no L2) | L2 band 8 |
|--------|---------------:|----------:|
| `M_L1 > 0` | **9/11** | 8/11 |
| worst `M_L1` | −13.316 | −10.971 |
| `M_cos > 0` | **5/11** | **1/11** |
| worst `M_cos` | −0.301 | −0.333 |
| AUC final, median | **~0.655** | 0.536 |
| AUC final, best | **0.753** | 0.711 |
| ΔAUC > 0 | **5/11** | 4/11 |
| rank final | 8–11 (one at 3) | 9–11 (one at 2) |

L2 loses on every axis that matters except worst-case `M_L1`, which improves by
2.3. The decision rule was stated before the run — drop if the number of passing
seeds falls — and both counts fell.

The striking part: **L2 makes `M_cos` worse, from 5/11 to 1/11**, despite being
introduced specifically to repair `M_cos`. The causal test in
`results/A7-EAM-03E/E5_L2_DIAG/` had already shown that L2 closes the radial
channel into `M_L1` and leaves the angular disagreement untouched; the sweep now
shows it also degrades angular ordering in aggregate.

## A mechanism I proposed and then falsified

My first explanation was that the equalisation is an integer right-shift, so
components below `2^sh` truncate to zero and direction information is destroyed —
which would be fatal for a cosine metric. That is testable, and it is wrong:

| band | mean shift | zeroed components / 32 | cosine vs unshifted |
|------|----------:|----------------------:|--------------------:|
| none | 0.0 | 0.0 | 0.9846 |
| 10 | 3.2 | 0.0 | 0.9846 |
| 8 | 5.2 | 0.2 | 0.9846 |
| 6 | 7.2 | 0.8 | 0.9841 |

At band 8 the shift zeroes 0.2 of 32 components and leaves direction at 0.9846 —
identical to the no-shift baseline. The shift is direction-preserving to
measurement precision. **Hypothesis falsified.**

So the degradation is not a measurement artifact. It is a training-dynamics
effect: the equalisation sits inside the forward path, so `h_final` and `hprev`
are both rescaled before the gradients and the `Wh` update see them. Removing
magnitude information changes what the update rule can express. That is the
honest description of where the effect comes from; the specific mechanism is
**not diagnosed**, and I am not going to invent one.

## A noise floor that affects every `M_cos` number in this program

The table above has a finding hiding in its first row. Two forwards of the *same
string* with no shift applied return vectors at cosine **0.9846**, not 1.0.

The cause is known and documented: `e_ra` has no reset in the RTL and carries
the previous access address into the next forward, so coordinate 0 of the
embedding read differs between two otherwise identical calls. What was not
previously quantified is the size: roughly **1.5% angular noise on every
encode**.

Consequence for interpretation. Several `M_cos` values reported across this
program sit inside or near that band: `+0.048`, `+0.071`, `−0.009`, `−0.016`.
Those should not be read as signed evidence. The large ones — `+0.246`, `−0.301`,
`+0.814`, `−0.333` — are safely outside it.

This does not change any verdict already recorded, because every gate decision
turned on large-magnitude values or on counts dominated by them. It does mean
future `M_cos` claims need a stated noise floor, and it strengthens the case for
fixing the `e_ra` reset in its own lane, which was already flagged as a separate
latent defect in `docs/contracts/A7-EAM-03E-A03.md`.

## Standing state

Candidate unchanged and unimproved: **triplet hinge + S3 decay `>>3`**, no
attribution, no L2. Not a PASS. Worst-seed `M_L1 = −13.316` and worst-seed
`M_cos = −0.301` both fail the contract A02 hard stop.

Four interventions have now been tested at the full pre-registered horizon on
all 11 seeds and none closes the gate:

| intervention | result |
|--------------|--------|
| S2 clamp on `Wh` | falsified; bounds `‖Wh‖₁` and drives AUC below chance |
| ungated DIFF | falsified; 11/11 total collapse, sanity gate passing |
| byte attribution | falsified; `M_L1 > 0` on 0/11 |
| L2 radial equalisation | dropped; `M_cos` 5/11 → 1/11 |

What did work, and remains the only thing that has: the S3 restoring force
(stability, 11/11 rank held, saturation 0.000) plus the triplet hinge (ordering,
`M_L1 > 0` on 9/11 at 100k).

The one pre-registered item on the recurrent-drift branch never tested is **S1**
— reduce the `Wh` update *rate* rather than its magnitude. S2 bounded magnitude
and saturated at the bound; S3 added a restoring force and settled at ~5% of
saturation. S1 is a third, distinct intervention and is the honest way to finish
that branch rather than leaving it half-falsified.

## Not claimed

No RTL, no XSim, no board for L2 or for the triplet law. No claim about bands 10
or 6 at 11 seeds. No diagnosis of why equalisation degrades angular ordering. No
claim that the `e_ra` noise floor invalidates prior verdicts — it does not, and
the reasoning is given above rather than asserted.
