# RESULTS — U5Q-R2A-RETRIEVAL-OBJECT-GRAIN-AUDIT-00

```text
RESULT              = MEASURE_PASS
OVERALL_DIAGNOSIS   = RAW_INSTANCE_RECALL_INCOMPATIBLE_WITH_BOUNDED_CAP
MASTER_OBJECT       = NOT CHOSEN (diagnosis only)
```

N=800000, U5Q confirmation queries, gold unchanged.

| query | RAW | TYPE_CLASS | TYPE_TEXT | dup_class | min_cands raw@0.80 | min_cands class@0.80 |
|-------|-----|------------|-----------|-----------|--------------------|----------------------|
| chiller | 34000 | 29 | 323 | 1172 | 27200 | 24 |
| water chiller | 12828 | 10 | 122 | 1283 | 10263 | 8 |
| leak chiller | 1368 | 4 | 13 | 342 | 1095 | 4 |
| payroll / soccer / adv / piano | 0 | 0 | 0 | — | 0 | 0 |

`CAND_CAP=64`: raw@0.80 needs 27200 IDs for chiller; class@0.80 needs **24**.

Bounded sparse retrieval cannot hit Master **raw-instance** recall 0.80 at this corpus grain.
TYPE_CLASS still fits the cap budget. TYPE_TEXT (323 unique phrases) does **not** (min 259 > 64).

Does not rewrite U5Q FAIL. Does not pick Master object. Does not open U7A.
