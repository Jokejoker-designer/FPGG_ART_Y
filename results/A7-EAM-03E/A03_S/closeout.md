# A0.3-S — stability under the signed law, and the falsification of S2

Law: `eam03e-a03-signed-h-v1` (RTL exists, XSim + silicon exact, see
`results/A7-EAM-03E/A03_SIGNED/`).
Evidence class: **REFERENCE MODEL**. 55 runs = 11 pre-registered seeds × 5
pre-registered clamp levels, same checkpoints, dataset, split and
`assert_no_leakage` as Phase S.
Experiment: **S2 only** (symmetric per-weight bound on `Wh`). S1 not run — S2's
result makes the shared premise of both untestable in the way §8 assumes.

## Verdict

`A0.3-S: FAIL` — 0 of 55 runs pass the §8 stability gate.

The S2 hypothesis is **FALSIFIED**, and not by S2 failing at its own job. S2
does exactly what it was designed to do:

| clamp | `‖Wh‖₁` final (median) | rank final | AUC init | AUC final | peak at update 0 | AUC final < 0.5 |
|------:|----------------------:|-----------:|---------:|----------:|-----------------:|----------------:|
| ±128 (control) | 123265 | 3 | 0.651 | 0.500 | 3/11 | 1/11 |
| ±64 | 54875 | 1 | 0.651 | 0.500 | 6/11 | 0/11 |
| ±32 | 17705 | 16 | 0.651 | 0.500 | 8/11 | 5/11 |
| ±16 | 8818 | 13 | 0.651 | 0.468 | 10/11 | 9/11 |
| ±8 | **4554** | **11** | 0.651 | **0.403** | **11/11** | **11/11** |

At ±8 the recurrence is fully controlled: `‖Wh‖₁` is 27× smaller than the
uncontrolled 123265, and `effective_rank` holds at 11 instead of collapsing to
1–3. Both stated S2 targets are met.

And the encoder is **worse**. AUC lands at 0.403 median with every one of the 11
seeds below chance: 0.404, 0.377, 0.390, 0.404, 0.395, 0.413, 0.401, 0.429,
0.398, 0.409, 0.403. That is a systematic ordering inversion, not scatter.

The decisive number is the last column but one. At ±8, the peak AUC occurs at
**update 0 on 11 of 11 seeds**, and there is **no seed at all** where
`auc_final > auc_init`. Once the recurrence is bounded, training never helps.
The untrained seeded encoder is the best this law ever is.

## What that means

The Wh runaway is real (Phase S measured it appear only after the signedness
repair) and S2 controls it. Controlling it does not produce a useful metric. So
recurrence scale was never the thing standing between this law and a working
encoder — it was one of two failures, and the smaller one.

Reading the clamp column as a dose-response curve makes the mechanism visible:
as `Wh` is squeezed, rank is preserved and AUC moves *monotonically away from*
useful, ending below chance. A tamed recurrence lets the update rule express
itself cleanly, and what it expresses is the wrong ordering.

Stated as a chain, with the evidence for each link:

1. Shipped law: unsigned concat rails the state. Learning dies in an absorbing
   fixed point. (XSim + reference model, `A02_STABILITY`.)
2. Signed law: state is genuinely 32-dimensional, untrained AUC rises to 0.65
   median and peaks at 0.804. `Wh` then runs away and rank collapses.
   (Reference model, `A03_SIGNED`.)
3. Bounded `Wh`: runaway stopped, rank held, and training becomes reliably
   harmful. (Reference model, this document.)

Each repair uncovered the next defect rather than fixing the encoder. That is
progress, and it is not a PASS.

## Consequence for §8

`final.md` §8 offers S1 (reduce Wh update rate), S2 (bound Wh) and S3 (Wh decay)
as the stability remedies, one at a time.

**This section originally argued that S2 is an upper envelope on S1 and S3, so
neither needed running. That argument was wrong, and S3 later disproved it.**
See `results/A7-EAM-03E/A02_L_S3/closeout.md`.

The error was treating all three as acting on the same quantity — the magnitude
of `Wh` — when a bound and a decay are qualitatively different. A hard bound
caps magnitude but still permits *every* entry to sit on the cap: measured here,
clamp ±32 ends with `‖Wh‖₁ = 32768`, which is exactly 1024 × 32, i.e. total
saturation at the bound. A decay instead creates a restoring force, so `Wh`
settles at an interior equilibrium where drift balances pull. Under S3 with
shift 3, `‖Wh‖₁` settles near 6000 out of a possible 131072 and `h` stops
saturating entirely.

So S2 did not bound S3's best case. It occupied a different regime, and the
regime it produced — a fully railed `Wh` acting as a constant sign matrix — is
the one that drives the state to a bang-bang fixed point independent of input.

The measured facts in the table above stand. Only the inference about S1/S3
was wrong, and it is corrected here rather than quietly rewritten.

## Where the bottleneck actually is

The update rule, not the recurrence. Specifically the two forces named in
`A03_SIGNED/second_defect.md`:

- SAME pull is unconditional; DIFF push is gated by `d1 < E3_MARG`, so early
  training is a pure attraction field on a globally shared embedding table.
- The gradient is broadcast to every byte of the sequence, and bytes shared
  between A and B receive `−sgn(g)` and `+sgn(g)` in succession. Net motion is
  therefore driven by byte multiplicity differences rather than by the
  discriminative content of the pair.

`A0.2-L` is aimed exactly at the first of those: the triplet hinge makes
repulsion conditional on the *margin* rather than on an absolute distance
threshold, so attraction and repulsion arrive in the same transaction and cannot
run unopposed. That makes it the next experiment, and it was already the next
queue item — the measurement did not choose it to avoid this gate, it arrived at
it.

Per the same discipline used for A0.3, the triplet law will be tested on the
reference twin **before** any RTL is written, so that a failing law costs
minutes rather than a synthesis run.

## Artifacts

| File | Content |
|------|---------|
| `stability_sweep.json` | all 55 runs, full per-checkpoint telemetry |
| `tools/a7eam03e_stability.py --rule signed --wh-clamp …` | the experiment |

Clamp set `{128, 64, 32, 16, 8}` was written into `WH_CLAMP_SET` in the tool and
the tool refuses any clamp outside it, so the levels could not be chosen after
seeing results. 128 is the control: it equals the existing `sat8` rail and
reproduces A0.3 unchanged.

## Not claimed

No board evidence. The A0.3 *bit* is silicon-exact against its pre-registered
golden bag, but nothing in this document was measured on silicon: the 10,000-
update sweeps are reference-model only. No claim that the signed law is a good
encoder. No claim that S1 or S3 were tested.
