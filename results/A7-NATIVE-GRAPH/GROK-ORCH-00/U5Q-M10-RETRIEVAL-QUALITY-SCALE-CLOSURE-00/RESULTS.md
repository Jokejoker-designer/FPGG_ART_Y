# RESULTS — U5Q-M10-RETRIEVAL-QUALITY-SCALE-CLOSURE-00

```text
RESULT              = FAIL
FIRST_DIVERGENCE    = PRECISION_FAIL
PROFILE             = P4_4k_h64
CAND_CAP            = 64
U6_RESULT           = RETAINED
U6_PROMOTION_STATUS = CONDITIONAL_ON_U5Q  (blocked)
DAG_ORDER_DEVIATION = YES
```

Independent gold = bound-class descriptor equality. Not router union.
Unrelated/no-answer (payroll, soccer, adversarial, piano): **0 candidates**, precision 1.0 at every N.
That is the U4A-R6 validity effect. U4A-R4 “full corpus” does **not** recur.

## Confirmation (required queries)

| N | query | recall | prec | gold | cands | lost | bytes |
|---|-------|--------|------|------|-------|------|-------|
| 256 | chiller | 0.853 | 1.000 | 75 | 64 | 11 | 464 |
| 256 | water chiller | 1.000 | 0.281 | 18 | 64 | 0 | 736 |
| 256 | leak chiller | 1.000 | 0.050 | 3 | 60 | 0 | 336 |
| 256 | payroll / soccer / adv | n/a | 1.000 | 0 | 0 | 0 | 0 |
| 4096 | chiller | 0.435 | 1.000 | 147 | 64 | 83 | 544 |
| 4096 | water chiller | 0.450 | 0.281 | 40 | 64 | 22 | 816 |
| 16384 | chiller | 0.087 | 1.000 | 736 | 64 | 672 | 544 |
| 800000 | chiller | 0.0019 | 1.000 | 34000 | 64 | 33936 | 544 |
| 800000 | water chiller | 0.0014 | 0.281 | 12828 | 64 | 12810 | 816 |

Traffic: directory beats ≤ 4, bytes/query 0..816, independent of N after postings saturate. No full scan. `n_host=0`.

## water chiller

Broad set is **false positives sharing bound context** (T1 = `{rel,ctx}`), not “all chillers”.
Precision stays 0.281 (18/64 at N=256; 46 FP). Same-entity ≠ relevant: query binds entity+context.

## Fail classes (76)

- `PRECISION_FAIL` (4): leak_chiller / air condenser / supply duct at small N
- `RECALL_FAIL` (36): bound queries once gold > CAND_CAP/HEAD_CAP
- `OVERFLOW_RELEVANT_LOSS` (36): relevant omitted by HEAD_CAP then CAND_CAP

`overflow=1` is not treated as PASS.

## Cap sweep (N=16384, evidence only)

Raising CAND_CAP 64→1024 does **not** restore min recall (~0.034). HEAD_CAP=64 posting truncation dominates. Do not silently raise CAND_CAP.

## Thresholds (frozen after exploration, before confirmation)

Master recall_min=0.80 (U4A-R3). precision_min=0.10 a priori. no_answer_max_cands=0. max_relevant_overflow_frac=0.20. Not retargeted after confirmation.
