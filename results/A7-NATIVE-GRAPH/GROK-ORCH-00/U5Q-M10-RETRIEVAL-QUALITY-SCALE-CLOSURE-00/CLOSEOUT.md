# CLOSEOUT — U5Q-M10-RETRIEVAL-QUALITY-SCALE-CLOSURE-00

```text
GATE                     = U5Q-M10-RETRIEVAL-QUALITY-SCALE-CLOSURE-00
BASE                     = 9244912965b50d513c0b324247d33ff49bb9a607
SOURCE_COMMIT            = 9244912965b50d513c0b324247d33ff49bb9a607
RTL_EDIT                 = NO
FILES_CHANGED            = results/.../U5Q-M10-RETRIEVAL-QUALITY-SCALE-CLOSURE-00/*
DAG_ORDER_DEVIATION      = YES  (U6 executed before U5Q)
U4                       = PASS (historical; not rewritten)
U5                       = PASS (historical; not rewritten)
U6_RESULT                = RETAINED
U6_PROMOTION_STATUS      = CONDITIONAL_ON_U5Q
QUERY_LAW                = qse-v1-lexicon-hdc-00 UNCHANGED
VALIDITY_LAW             = U4A-R6 UNCHANGED
CURRENT_PROFILE          = P4_4k_h64
CURRENT_CAND_CAP         = 64
BIT_BUILD                = NO
PROGRAM                  = NO
GATE14_PASS              = NO
COM12                    = UNTOUCHED
U7A                      = CLOSED
U7                       = CLOSED
U8                       = CLOSED
RESULT                   = FAIL
EVIDENCE_CLASS           = HOST_MODEL
FIRST_DIVERGENCE         = PRECISION_FAIL
VIOLATED_INVARIANT       = preregistered retrieval quality/selectivity at scale
HOST_SEMANTIC_COUNTERS   = 0
OVERFLOW_PROPAGATION     = counted as semantic miss (not a PASS)
```

## Claim boundary

U6 historical claim remains true for the old profile in XSim.

U6 is **not** invalid. Downstream promotion is **blocked** until a profile
that passes U5Q is selected and U6 is re-run on that promoted profile.

Do not call U5 invalid (traffic/sentinel). Do not open U7A.

## Why FAIL (current P4_4k_h64 / CAND_CAP=64)

1. Bound-query precision below frozen 0.10 at N=256 (`leak chiller` 0.05).
2. Record recall vs independent gold collapses as N grows: relevant copies
   overflow HEAD_CAP=64 then CAND_CAP=64 (`chiller` 0.85 @256 → 0.0019 @800k).
3. Cap sweep 64..1024 does not restore min recall; HEAD_CAP is the wall.

Unrelated/no-answer behaviour is correct (0 cands). Traffic is bounded vs N.
Those do not override quality FAIL.

## NEXT

Open one rival-profile gate (U4A-class). Do **not** continue to
`U7A-ROOT-B-REACHABILITY-REAUDIT-00` on this profile.
