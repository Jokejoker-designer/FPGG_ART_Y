# PREREG — U5Q-T1-TYPE-CLASS-MASKED-CONJUNCTIVE-00

Implements the owner decision in **host-model only**. No RTL. No QSE change.
No NID profile sweep.

```text
GATE                      = U5Q-T1-TYPE-CLASS-MASKED-CONJUNCTIVE-00
BASE                      = 0fe16a0787fa7b7b1dd0ebcc70921607b64a9832
MASTER_RETRIEVAL_OBJECT   = TYPE_CLASS
RAW_EPISODE_ID            = provenance only
QUERY_LAW                 = qse-v1-lexicon-hdc-00 UNCHANGED
RETRIEVAL_LAW             = masked conjunctive TYPE_CLASS
RTL_EDIT                  = NO
BIT                       = NO
PROGRAM                   = NO
U7A                       = CLOSED
U5Q_RAW                   = FAIL immutable
U6_OLD_PROFILE            = historical XSim PASS only
```

## Retrieval law (frozen)

```text
Q_BOUND = {eid, iid, rid, xid | query.field != 0}
type T is a hit iff
  Q_BOUND empty → no hit   (no-answer)
  else every field in Q_BOUND: T.field == query.field
```

Index = unique TYPE_CLASS rows present in the corpus at that N.
Members (nids) hang off each type as provenance. They are not recall keys.

## Primary unknown

Does TYPE_CLASS masked-conjunctive retrieval:

- keep candidate_count = |matching types| bounded vs N (not vs 34k nids)
- recall_class = 1.0 on the type table (complete class index)
- precision_class = 1.0 (conjunctive filter)
- no-answer → 0
- |TYPE_TABLE| saturates with catalog, not with N

without QSE redesign and without NID cap/head sweep?

## Compatibility (not a promotion of P4)

Also report LEGACY_NID_COLLAPSE: P4 union nids at frozen CAND_CAP=64/HEAD=64
→ map to TYPE_CLASS → conjunctive filter → unique types.
That is the old profile collapsing to the new object. It may miss types.
It does **not** retarget U5Q. It does **not** un-fail P4 instance recall.

## PASS

TYPE_TABLE path:

1. bound queries: recall_class = 1.0, precision_class = 1.0
2. candidate_count <= 64
3. no-answer candidate_count = 0
4. N_TYPE_TABLE at 800k is not ~linear in N (saturates vs 256/4096)
5. n_host = 0

FAIL if type table grows like raw N, or no-answer emits types, or
candidate_count > 64 on confirmation queries.
