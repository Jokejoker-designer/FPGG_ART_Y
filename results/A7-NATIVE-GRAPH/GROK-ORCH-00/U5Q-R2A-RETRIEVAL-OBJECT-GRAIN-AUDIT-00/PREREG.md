# PREREG — U5Q-R2A-RETRIEVAL-OBJECT-GRAIN-AUDIT-00

Diagnostic only. No RTL. No profile sweep. No threshold retarget. No U7A.

```text
GATE            = U5Q-R2A-RETRIEVAL-OBJECT-GRAIN-AUDIT-00
BASE            = 9755147a11efefc37146257e61fa546dc0a5b334
QUERY_LAW       = qse-v1-lexicon-hdc-00 UNCHANGED
VALIDITY_LAW    = U4A-R6 UNCHANGED
GOLD            = U5Q bound-class descriptor match UNCHANGED
CAND_CAP_REF    = 64   (budget reference only; not a new cap)
RTL_EDIT        = NO
BIT             = NO
PROGRAM         = NO
REPROGRAM_AGAIN = NO
U7A             = CLOSED
U7              = CLOSED
U8              = CLOSED
```

## Primary unknown

Is the Master retrieval object a **raw episode instance** (nid) or a
**semantic evidence type**?

Do not decide before measurement.

## Grains (frozen before run)

```text
RAW        = nid  (U5Q instance gold)
TYPE_CLASS = (eid, iid, rid, xid)   extractor class tuple, not route keys
TYPE_TEXT  = unique registered catalog text
```

`TYPE_ROUTE = (k0..k3, v0..v3)` is recorded as a diagnostic count only.
R2B owns discriminability of those fields.

## Metrics per query × scale

```text
N_RELEVANT_RAW_INSTANCES
N_UNIQUE_TYPE_CLASS
N_UNIQUE_TYPE_TEXT
DUPLICATION_RATIO_CLASS = RAW / TYPE_CLASS
DUPLICATION_RATIO_TEXT  = RAW / TYPE_TEXT
MIN_CANDS_FOR_RAW_RECALL_0.80  = ceil(0.80 * RAW)     # perfect relevant-only ranking
MIN_CANDS_FOR_CLASS_RECALL_0.80 = ceil(0.80 * TYPE_CLASS)
MIN_CANDS_FOR_TEXT_RECALL_0.80  = ceil(0.80 * TYPE_TEXT)
RAW_EXCEEDS_CAND_CAP64
CLASS_FITS_CAND_CAP64
```

Queries = U5Q confirmation set. Scales = U5Q ladder.

## Diagnosis labels (after numbers)

```text
RAW_INSTANCE_RECALL_INCOMPATIBLE_WITH_BOUNDED_CAP
  RAW min-cands@0.80 > 64 and CLASS min-cands@0.80 <= 64

BOTH_GRAINS_EXCEED_CAP
  both min-cands@0.80 > 64

RAW_GRAIN_BUDGET_OK
  RAW min-cands@0.80 <= 64

NO_ANSWER
  RAW = 0
```

This does not change U5Q FAIL. It does not promote a profile.
