# PREREG — U5Q-M10-RETRIEVAL-QUALITY-SCALE-CLOSURE-00

Frozen before exploration metrics. Do not retarget after confirmation.

```text
GATE                     = U5Q-M10-RETRIEVAL-QUALITY-SCALE-CLOSURE-00
BASE                     = 9244912965b50d513c0b324247d33ff49bb9a607
BRANCH                   = grok-orch/v31-canonical-00
DAG_ORDER_DEVIATION      = YES
U6_RESULT                = RETAINED
U6_PROMOTION_STATUS      = CONDITIONAL_ON_U5Q
U6_CLAIM                 = historical PASS for P4_4k_h64 / CAND_CAP=64 in XSim
U4                       = PASS (historical, mechanical AXI)
U5                       = PASS (historical, traffic bound / sentinel)
QUERY_LAW                = qse-v1-lexicon-hdc-00  UNCHANGED
VALIDITY_LAW             = U4A-R6  UNCHANGED
N_TABLES                 = 4
N_BUCKETS                = 4096
CURRENT_PROFILE          = P4_4k_h64
CURRENT_CAND_CAP         = 64
HEAD_CAP                 = 64
RTL_EDIT                 = NO
BIT                      = NO
PROGRAM                  = NO
COM12                    = UNTOUCHED
GATE14_PASS              = NO
U7A                      = CLOSED
U7                       = CLOSED
U8                       = CLOSED
EVIDENCE                 = HOST_MODEL  (quality; not AXI rerun)
```

## Primary unknown

Does the frozen qse-v1-lexicon-hdc-00 + U4A-R6 validity + P4_4k_h64
profile preserve preregistered retrieval quality/selectivity as corpus
scale increases, while candidate count and retrieval traffic stay bounded?

## Independent gold (not router output)

Forbidden: `relevant = router_union`, `relevant = retained_candidates`.

A record `r` is relevant to query `q` iff:

```text
Q_BOUND = {entity_id, intent_id, relation_id, context_id | q.field != 0}
if Q_BOUND is empty:  relevant = FALSE   # no-answer / unknown
else:                 relevant = (r.field == q.field for every field in Q_BOUND)
```

Same entity ≠ relevant evidence when the query also binds intent/relation/context.

Fields come from the frozen extractor (`twin.extract` / qse-v1-lexicon-hdc-00)
applied to registered text. Routing keys are never used as gold.

## Corpus construction (no nid-derived keys)

1. Registered titles: `ENTITY_CANON`, `INTENT_CANON`, `SAME_ENT_DIFF_INT`, `UNRELATED`.
2. Registered LEX 1-word and 2-word phrases (lexicon table only).
3. Scale by repeating those registered texts with new nids.

`nid` is identity only. Keys/validity always `extract(text)`.

## Scale ladder

```text
256, 4096, 16384, 65536, 262144, 800000
```

Physical index: HEAD_CAP=64 per (table,bucket); overflow sticky; CAND_CAP=64.

## Phases

1. EXPLORATION_SET (not the confirmation six) → metrics.
2. Freeze THRESHOLDS.json (Master recall 0.80 + exploration for unspecified).
3. CONFIRMATION_SET untouched. No threshold edit after this file is written.

Master-defined (U4A-R3, not retargeted):

```text
RECALL_MIN_BOUND_QUERY = 0.80
```

Unrelated/no-answer (U4A-R4 law, not retargeted):

```text
UNRELATED_MUST_NOT_RETURN_FULL_CORPUS
UNRELATED_REDUCTION_RATIO > 0 when N > CAND_CAP
NO_ANSWER: empty gold; empty candidates is correct; non-empty is FP
```

Precision / overflow-loss / bytes bounds: written after exploration into
`THRESHOLDS.json` before confirmation. Not after confirmation.

## Overflow falsifier

Relevant omitted by HEAD_CAP or CAND_CAP = semantic miss.
`overflow=1` is not a PASS.

## Cap law

If CAND_CAP=64 fails quality: do not silently raise it.
Optional sweep 64/128/256/512/1024 is evidence only.
U5Q RESULT = FAIL for current profile. Do not open U7A.
