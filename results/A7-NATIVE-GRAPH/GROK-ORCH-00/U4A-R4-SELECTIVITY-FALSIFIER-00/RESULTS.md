# RESULTS — U4A-R4-SELECTIVITY-FALSIFIER-00

```text
RESULT                    = FAIL
EVIDENCE_CLASS            = HOST_MODEL
FIRST_DIVERGENCE          = UNRELATED_FULL_CORPUS
BLOCKER                   = ROUTER_SELECTIVITY_FAIL
U4A_R3_QUALITY_INVALIDATED = YES
```

P4_4k_h64 / CAND_CAP=64 on the 42-title labeled corpus:

| query | cand | frac | recall | prec | reduction |
|-------|------|------|--------|------|-----------|
| chiller | 42 | 1.00 | 1.0 | 0.095 | 0 |
| water chiller | 42 | 1.00 | 1.0 | 0.095 | 0 |
| leak chiller | 15 | 0.36 | 1.0 | 0.267 | 0.64 |
| payroll tax form | 42 | 1.00 | n/a | 0 | 0 |
| soccer match score | 42 | 1.00 | n/a | 0 | 0 |
| adversarial | 42 | 1.00 | n/a | 0 | 0 |

Unrelated pairwise Jaccard = **1.0** (identical full corpus).
5/6 queries admit the entire corpus. Recall-only was inflated.

Mechanism (observation, not a law change): many records have `k1=0`
(no relation/context), so table-1 bucket 0 unions almost every nid.

Law/profile/CAND_CAP **not** retargeted.
