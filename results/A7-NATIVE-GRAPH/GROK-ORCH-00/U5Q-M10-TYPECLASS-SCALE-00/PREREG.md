# PREREG — U5Q-M10-TYPECLASS-SCALE-00

Frozen before metrics. Do not retarget after this file.

```text
GATE                     = U5Q-M10-TYPECLASS-SCALE-00
BASE                     = 2a3bca3991b29657a5a74c69a6ef0872b8c3e5c0
MASTER_RETRIEVAL_OBJECT  = TYPE_CLASS
QUERY_LAW                = qse-v1-lexicon-hdc-00 UNCHANGED
RETRIEVAL_LAW            = masked conjunctive TYPE_CLASS (U5Q-T1 / U6)
U5Q_M10_NID              = FAIL immutable (P4_4k_h64 / CAND_CAP=64)
U5Q_T1                   = PASS host-model (table exact)
RTL_EDIT                 = NO
BIT                      = NO
PROGRAM                  = NO
GATE14_PASS              = NO
COM12                    = UNTOUCHED
EVIDENCE                 = HOST_MODEL
```

## Primary unknown

On TYPE_CLASS grain (unique `{eid,iid,rid,xid}` rows, members = provenance
only), does masked-conjunctive retrieval meet the **already frozen** M10
thresholds as corpus N scales 256 → 800000, while the type table saturates
(does not grow ~linear with N) and |cands| ≤ 64?

## Frozen thresholds (copied, not fit)

From `U5Q-M10-RETRIEVAL-QUALITY-SCALE-CLOSURE-00/THRESHOLDS.json`:

```text
recall_min              = 0.80
precision_min_bound     = 0.10
no_answer_max_cands     = 0
CAND_CAP                = 64
```

## Gold (independent of NID router)

```text
Q_BOUND = {eid,iid,rid,xid | query.field != 0}
type T is relevant iff Q_BOUND nonempty AND T matches every bound field
```

Retrieval = scan of unique types present at that N (complete class index).
Not `relevant = router_union`. Not NID heap.

## CONTROL (must remain FAIL)

Legacy NID P4_4k_h64 collapse at 800k — U5Q-M10 FAIL immutable.

## Not this gate

FPGA heap timing (P2). Learn-store DEPTH (P3). Silicon. HOLD_A retarget. U8R.
