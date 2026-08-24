# Ungated DIFF — tested against a matched control, and falsified at horizon

Law tested: `eam03e-a03-ungated-diff-v1` — remove the `d1 < E3_MARG` (4096)
gate so DIFF always repels. Base: `eam03e-a03-signed-h-v1` (RTL XSim- and
silicon-exact). One unknown: the gate.

Implementation note: `E3_MARG` occurs exactly twice in the twin, its definition
at `python/eam/eam03e_twin.py:59` and the gate at line 339. `d1` saturates at
`0xFFFF`, so setting the threshold to `0x10000` makes the condition unreachable.
That is arithmetically identical to deleting the branch and leaves no duplicated
update path to drift out of sync.

Evidence class: **REFERENCE MODEL**. 11 pre-registered seeds, 10 checkpoints to
10,000 updates, same dataset, split and `assert_no_leakage` as every other sweep.

## Why this was run out of the locked order

`MUST_READ_UNBLOCK_H5.md` claims the bottleneck is this gate, not the recurrent
weights, and instructs that ungated DIFF is the next law. Its supporting numbers
(lines 31–32) are seed `0x22222222`: silicon gated `M_L1 = −1258`, hinge `m=0`
`+42`, always-repel `+1545`; and "always-repel 5/8, hinge 1/8".

That contradicted the locked experiment order, which had horizon extension next.
Rather than choose an authority by assertion, the gate was tested directly with a
matched control on the same seed set. One sweep settles it.

## Result: the gate is not the lever

| condition | rank min | sat max | AUC peak (med) | AUC final (med) | ΔAUC>0 | worst M_L1 | M_L1>0 | worst M_cos |
|-----------|--------:|-------:|--------------:|---------------:|-------:|----------:|-------:|-----------:|
| pair, gated, no decay | 1 | 0.609 | 0.695 | 0.500 | 4/11 | −103.96 | 4/11 | −0.778 |
| pair, **ungated**, no decay | 1 | 0.527 | 0.688 | 0.500 | 3/11 | 0.00 | 2/11 | −0.137 |
| pair, gated, S3 `>>3` | 9 | 0.000 | 0.651 | 0.408 | 0/11 | −21.05 | 0/11 | −0.252 |
| pair, **ungated**, S3 `>>3` | 9 | 0.000 | 0.651 | 0.398 | 0/11 | −21.77 | 0/11 | −0.240 |
| **triplet**, gated, S3 `>>3` | 9 | 0.000 | 0.651 | **0.613** | **5/11** | **+0.01** | **11/11** | −0.254 |

Read the pairs of rows that differ only in the gate:

- Without decay: gated 0.500 final, ungated 0.500 final. No difference.
- With decay: gated 0.408, ungated 0.398. Ungated is marginally **worse**.

Ungated DIFF moves the final AUC by at most 0.01 in either direction, on 11
seeds, at both stability regimes. **The gate is not the bottleneck at this
horizon.** Ungated alone still collapses: rank → 1 on 6 of 11 seeds, 10 of 11
flagged as collapse.

## What the same table shows the levers actually are

Two rows differ only in the decay, and two differ only in the hinge:

- **S3 decay is what buys stability.** rank min 1 → 9, saturation 0.609 → 0.000.
  Both no-decay rows end at rank 1 regardless of the gate.
- **The triplet hinge is what converts stability into correct ordering.** Same
  decay, same stability, same seeds: pair gives AUC 0.408 with `M_L1 > 0` on
  **0/11**; triplet gives 0.613 with `M_L1 > 0` on **11/11**.

So the necessary pair is decay **and** hinge. Neither alone is sufficient: decay
alone lands at sub-chance 0.40 on every seed, hinge alone (no decay) collapses to
rank 1. Ungated DIFF is a third lever that measurably does nothing here.

## Reconciling with MUST_READ rather than dismissing it

The two results are not necessarily in contradiction about the same quantity.
`MUST_READ`'s numbers are single-seed margin values from short "copy" runs, and
at short horizon the ungated peaks in this sweep are respectable — 0.732, 0.716,
0.705, 0.697 at 32–1000 updates. What this sweep adds is the 10,000-update
endpoint on the full pre-registered seed set with a matched gated control, and at
that endpoint the gate's effect is inside noise while the hinge's effect is
+0.21 AUC and flips `M_L1` on 11 seeds.

Also worth recording because it changes how its evidence should be read: in this
sweep the ungated no-decay condition has worst `M_L1 = 0.00` with `M_L1 > 0` on
only 2 of 11 seeds. A large positive `M_L1` measured on one seed at short horizon
is not evidence that the law holds, which is exactly the failure mode `final.md`
§8 warns about.

`MUST_READ`'s instruction "next = ungated DIFF (not S2, not glue)" was followed:
it was run, first, before the horizon work. Its prohibition on tightening S2
further also stands and was respected — S3 is a restoring force, not a bound, and
the `A03_S` closeout now carries the correction explaining why those are
different interventions.

## Verdict

`ungated DIFF: FALSIFIED as the bottleneck` at 10,000 updates on 11
pre-registered seeds, with a matched control. Not adopted.

The chosen configuration remains triplet hinge + S3 decay shift 3, selected by
the locked lexicographic criterion in
`results/A7-EAM-03E/A02_L_S3/authority_table.json`.

## Provenance note

The `--diff-gate` flag and its `E3_MARG` wiring appeared in
`tools/a7eam03e_stability.py` between sessions and were not written by this
agent. The peer Grok observer is declared read-only, so that is a boundary
violation worth flagging. The code was inspected before use, is correct, and was
consolidated onto a single named constant `UNGATED_MARG`. Integrity was
re-verified after the fact: twin 10/10 golden tests pass, `golden_check` exact,
`E3_MARG` still 4096 at rest, and the A0.1-T bit `80F2ED9E…`, A0.3 bit
`05E478FF…`, A0.3 core source `BF17D406…` and both golden tables unchanged.

## Not claimed

No RTL, no XSim, no board for the ungated law — correctly, since the twin
pre-check failed. No claim about ungated DIFF at horizons beyond 10,000 updates.
No claim that `MUST_READ`'s short-horizon measurements are wrong on their own
terms.
