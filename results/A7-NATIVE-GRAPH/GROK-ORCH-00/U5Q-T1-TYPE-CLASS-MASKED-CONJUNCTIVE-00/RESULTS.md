# RESULTS — U5Q-T1-TYPE-CLASS-MASKED-CONJUNCTIVE-00

```text
RESULT = PASS   (TYPE_TABLE host-model)
```

## Type table size vs N

| N | unique TYPE_CLASS |
|---|-------------------|
| 256 | 57 |
| 4096 | 268 |
| 16384 | **443** (catalog saturated) |
| 800000 | **443** |

Not linear in raw N (800k). Bounded by registered catalog classes.

## TYPE_TABLE retrieval (new law) @ N=800k

| query | gold types | cands | recall | prec |
|-------|------------|-------|--------|------|
| chiller | 29 | 29 | 1.0 | 1.0 |
| water chiller | 10 | 10 | 1.0 | 1.0 |
| leak chiller | 4 | 4 | 1.0 | 1.0 |
| leak check | 47 | 47 | 1.0 | 1.0 |
| payroll/soccer/adv/piano | 0 | 0 | n/a | 1.0 |

All bound queries: cands ≤ 64.

## LEGACY_NID_COLLAPSE (P4 CAND_CAP=64, not promoted)

Chiller @800k: 64 nids → 5 types, class recall **0.17**. Water: 64 nids, 46 filtered as class-mismatch, 1 type, recall **0.10**.

Old nid stream + collapse does **not** meet class recall 0.80. The new object needs a **type table**, not a cap raise on nids.

U5Q raw FAIL and U5Q-R1 FAIL stay immutable. U6 old-profile XSim stays historical.
