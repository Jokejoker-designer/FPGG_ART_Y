# CLOSEOUT — U5Q-M10-TYPECLASS-SCALE-00

```text
GATE                     = U5Q-M10-TYPECLASS-SCALE-00
HEAD                     = 2a3bca3991b29657a5a74c69a6ef0872b8c3e5c0
MASTER_RETRIEVAL_OBJECT  = TYPE_CLASS
QUERY_LAW                = qse-v1-lexicon-hdc-00 UNCHANGED
RESULT                   = PASS
EVIDENCE_CLASS           = HOST_MODEL
FIRST_DIVERGENCE         = none
N_TYPE_TABLE_256         = 57
N_TYPE_TABLE_800K        = 443
CONFIRMATION_RECALL      = 1.0 (all bound queries, all N)
CONFIRMATION_PRECISION   = 1.0
NO_ANSWER_CANDS          = 0
MAX_GOLD_TYPES           = 47 (wrong_intent_leak_check) ≤ CAND_CAP 64
U5Q_M10_NID              = FAIL immutable (CONTROL; 32 rows below recall 0.80)
RTL_EDIT                 = NO
BIT                      = NO
PROGRAM                  = NO
GATE14_PASS              = NO
HOLD_A_ORACLE_RETARGET   = NO
```

## Allowed claim

On TYPE_CLASS grain, masked-conjunctive retrieval over the unique class
table meets frozen M10 thresholds (recall≥0.80, precision≥0.10, no-answer
cands=0, |cands|≤64) at N=256…800000. The type table saturates at 443
(not ~linear in N). Host semantic counters 0.

## Forbidden claims (not made)

FPGA heap timing closed · silicon retrieval · U5Q-M10 NID un-failed ·
LM understands TYPE_CLASS · GATE14_PASS · BOARD_PASS · 800k physical agents

## CONTROL

Legacy NID P4_4k_h64 type-collapse stays below recall 0.80 on chiller and
several confirmation queries as N grows (e.g. chiller 0.727@256 → 0.172@800k).
That FAIL remains immutable.

## NEXT

`U6T-TYPECLASS-HEAP-TIMING-00` (OOC WNS −4.103 ns). Not U8R. Not PROGRAM.
