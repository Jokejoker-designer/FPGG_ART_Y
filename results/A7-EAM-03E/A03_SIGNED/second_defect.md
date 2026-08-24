# A0.3 second-defect diagnosis — why the signed encoder still collapses

Evidence class: **REFERENCE MODEL** ablation. No RTL exists for this law.
Law under ablation: `eam03e-a03-signed-h-v1` (contract
`docs/contracts/A7-EAM-03E-A03.md`, frozen before this run).
Same pre-registered seeds, checkpoints, dataset and split as Phase S. The twin
passed `golden_check()` against the shipped law **before** the rule was patched,
so the ablation cannot be hiding a drifted oracle.

## What the signedness repair buys

| Quantity | shipped law | signed law |
|----------|------------:|-----------:|
| untrained saturation | 0.79–0.89 | **0.17–0.23** |
| untrained `negativity_rate` | 0.000 | **~0.50** |
| untrained `effective_rank` | 12–29 | **32/32 on 8 of 11 seeds** |
| untrained AUC, median | ~0.47 | **~0.65** |
| best AUC reached | 0.582 | **0.804** |

The repair is real and substantial. The state becomes genuinely 32-dimensional
and genuinely signed, and the encoder reaches AUC 0.80 where the shipped law
never passed 0.58.

## But it still fails, on 11 of 11 seeds

Final AUC returns to 0.500 on 6 seeds, and one seed inverts to 0.360.
`effective_rank` falls from 32 to 1 on 5 seeds. `unique_d1_count` falls to 1.
The collapse is later and takes a different route, but it is still total.

## Hypotheses tested in one experiment

| ID | Hypothesis | Discriminating readout | Verdict |
|----|-----------|------------------------|---------|
| H3 | `d1` degenerates into a bag-of-bytes metric because the gradient is broadcast to every byte of the string | `spearman(d1, byte-histogram L1)` rises with training | **FALSIFIED** — stays 0.09–0.37, no upward trend, drops to 0.00 at collapse |
| H4 | shared bytes between A and B cancel, so only the symmetric difference moves | would show as `d_pos` shrinking while `d_neg` holds | **NOT SUPPORTED** — both shrink together |
| H5 | unopposed global attraction: SAME always pulls on a globally shared embedding table, so every distance contracts | `d_pos` and `d_neg` medians fall together with ratio near 1 | **CONFIRMED** |

Trajectory, seed `0xB2B49299`:

| updates | AUC | rank | `d_pos` med | `d_neg` med | neg/pos | `Wh_l1` | E rails |
|--------:|----:|-----:|-----------:|-----------:|--------:|--------:|--------:|
| 0 | 0.705 | 32 | 12292 | 13727 | 1.27 | 65277 | 61 |
| 128 | 0.695 | 31 | 11279 | 12742 | 1.31 | 64502 | 54 |
| 512 | 0.570 | 21 | 3830 | 4057 | 1.14 | 60029 | 53 |
| 1000 | 0.587 | 6 | 1816 | 2269 | 1.11 | 58136 | 57 |
| 2000 | 0.581 | 1 | 1 | 2 | 0.91 | 69320 | 71 |
| 5000 | 0.500 | 1 | 0 | 0 | — | **129464** | 108 |
| 10000 | 0.500 | 1 | 0 | 0 | — | 128440 | **177** |

Both distance populations contract by four orders of magnitude while their ratio
stays near 1. The metric does not become wrong; it becomes **empty**. Nothing is
separated from anything because everything occupies one point.

## The part that corrects my own Phase S conclusion

Phase S concluded that H1 "recurrent scale runaway" is falsified. That
conclusion stands **for the shipped law**: `Wh_l1` there moves under 0.4% over
10,000 updates and `acc` never wraps.

Under the signed law it is a different story. `Wh_l1` roughly **doubles**:
65277 → 129464 on seed `0xB2B49299`, and 64886 → 123265 on `0xE6C4400D`.
Embedding rail count nearly triples, 61 → 177.

So the rail was clamping the very feedback loop that would otherwise amplify the
recurrence. Remove the rail and the runaway appears. The `final.md` §8 remedies
S1 (reduce Wh update rate) and S2 (bound Wh) are therefore **not** dead — they
target a mechanism that is absent before the repair and present after it. They
were the right medicine prescribed for the wrong patient.

This is stated as a correction rather than buried, because the Phase S closeout
tells a reader not to apply S1/S2/S3, and that instruction must now be scoped to
the shipped law only.

## Mechanism, stated plainly

1. Signed arithmetic frees the state, so the recurrence `acc = Wh · h` can carry
   real signed magnitude instead of being clamped at a rail.
2. SignSGD writes `±1` into `Wh` on every active coordinate pair with no scale
   control, no decay and no normalisation, so `‖Wh‖₁` grows monotonically once
   training gets going.
3. A larger `Wh` amplifies `h` between tokens, pushing coordinates toward the
   rails again and reducing the number of independent directions: rank 32 → 1.
4. Meanwhile SAME pull is unconditional while DIFF push is gated by
   `d1 < E3_MARG`. Early on, most DIFF pairs sit above the margin and receive no
   repulsion at all, so the net field is pure attraction on a globally shared
   embedding table.
5. Attraction with no counterforce contracts every distance toward zero.
   `d_pos` reaches 0 first, then `d_neg` follows, and `d1` loses all resolution.

Steps 2–3 and steps 4–5 are two distinct forces arriving at the same endpoint.
Both are visible in the table above: rank collapse tracks `Wh_l1` growth, and
distance contraction tracks the attraction asymmetry.

## What this means for the plan

The A0.3 contract stands as written: repair signedness, one unknown, its own
golden bag. Nothing here changes it.

What changes is the phase *after* A0.3. It is not A0.2-L. Running a triplet
hinge on an encoder whose `‖Wh‖₁` doubles and whose rank falls to 1 would
produce a margin number with nothing behind it. The order becomes:

1. **A0.3** — signedness repair. RTL, XSim against the pre-registered bag,
   timing, silicon.
2. **A0.3-S** — re-run Phase S under A0.3, then apply S1 or S2 (not both, one
   at a time) against the measured `Wh_l1` growth. Gate: `‖Wh‖₁` bounded,
   `effective_rank` holds, `d_pos`/`d_neg` do not co-contract to zero.
3. **A0.2-L** — only then the triplet hinge, which is also the natural fix for
   the attraction asymmetry, since the hinge makes repulsion unconditional
   inside the margin rather than gated by an absolute distance threshold.

A0.2-L may well be the cure for force 4–5. It is not a cure for force 2–3, and
the two must not be bundled.

## Artifacts

| File | Content |
|------|---------|
| `stability_sweep.json` | 11-seed signed-rule sweep, same pre-registration as Phase S |
| `golden_a03_predicted.json` | pre-registered A0.3 golden bag |
| `tools/a7eam03e_stability.py --rule signed` | the experiment |
| `tools/a7eam03e_a03_predict.py` | the prediction |

## Not claimed

No XSim evidence. No board evidence. No RTL. The signed rule is an ablation on
the host twin and nothing more. Whether the A0.3 RTL reproduces
`739/581 → 164/1957 → 742 → 137/1370` is an open question until it is built.
