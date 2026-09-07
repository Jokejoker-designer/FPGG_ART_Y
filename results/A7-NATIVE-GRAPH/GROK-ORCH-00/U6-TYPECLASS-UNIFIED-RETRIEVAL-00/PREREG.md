# PREREG — U6-TYPECLASS-UNIFIED-RETRIEVAL-00

```text
GATE                    = U6-TYPECLASS-UNIFIED-RETRIEVAL-00
BASE                    = 6728637056c8c5e646f5d0e8ed191b32718ea7a7
MASTER_RETRIEVAL_OBJECT = TYPE_CLASS
QUERY_LAW               = qse-v1-lexicon-hdc-00 UNCHANGED
RETRIEVAL_LAW           = masked conjunctive (T2 frozen)
CANDIDATE_OWNER         = a7ng_typeclass_scan
LEGACY_NID              = DISCONNECTED (not instantiated in U6 typeclass top)
LEGACY_SYNTHETIC        = DISCONNECTED
LEARN                   = 0
LEARNED_PRIOR           = 0
CONTRADICTION_PENALTY   = 0
PATH_CONFIDENCE         = 0
Q_HEAD                  = FORBIDDEN
CLASS_ID_W              = 16
HEAP_ID_W               = 32  (zero-extend CLASS_ID; [31:16]=0)
CAND_CAP                = 64
K                       = 8
TC_N                    = 443
TYPECLASS_TABLE_SHA256  = B5958D4ADBE96F1D4432915E767BA2C4806594DBB291BBFFBEC95FE588E436C2
CLASS_ID_MAPPING_SHA256 = CEA2B9710D4D5F229BC341DF790E557B20F023F98161464C6C79BEADAE6BD68B
BIT                     = NO
PROGRAM                 = NO
REPROGRAM_AGAIN         = NO
U7A                     = CLOSED
U7                      = CLOSED
U8                      = CLOSED
GATE14_PASS             = NO
```

PRIMARY_UNKNOWN: can the frozen FPGA TYPE_CLASS scanner be the ONE
authoritative production candidate source into materialize → scorer →
exact Top-K, with old NID walker / synthetic paths at zero authority?

## Score-term law (FPGA, learn=0)

All candidates already passed masked-conjunctive match. Ties expected.

```text
entity_match   = (q_eid!=0 && q_eid==T.eid) ? +8 : 0
intent_match   = (q_iid!=0 && q_iid==T.iid) ? +8 : 0
relation_match = (q_rid!=0 && q_rid==T.rid) ? +8 : 0
context_match  = (q_xid!=0 && q_xid==T.xid) ? +8 : 0
path = 0; prior = 0; penalty = 0
```

Compose tree (must match a7ng_scorer_lane, not pkg left-fold):

```text
partial = sat(sat(e,i), sat(r,c))
score   = sat(sat(partial, path), sat(prior, -pen))
```

## Tie law (production a7ng_topk_stream_minheap beats())

```text
valid > score > id < lane <
```

Underfill: pad to K=8 with `v=0`, `id=32'h00FF_FFF0+i`, `s=0`, `lane=0`.
If n_scored >= K: one FINLAST invalid with `in_last` (does not enter K-set).

## Identity

```text
topk_identity = zero_extend(CLASS_ID)
heap_id[15:0] = CLASS_ID
heap_id[31:16] = 0
NOT raw NID
```

## Overflow

Latch scanner `q_overflow_o` / `n_trunc_o`. Truncated search ≠ complete.

## Poison (directed, not production table edit)

A. TB decoy NID register poisoned → U6 Top-K unchanged.
B. Overlay mux replaces eid of one participating CLASS_ID → Top-K/scores change.
