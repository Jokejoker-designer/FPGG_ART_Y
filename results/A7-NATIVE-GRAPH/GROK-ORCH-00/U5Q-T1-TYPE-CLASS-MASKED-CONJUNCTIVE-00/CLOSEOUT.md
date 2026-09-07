# CLOSEOUT — U5Q-T1-TYPE-CLASS-MASKED-CONJUNCTIVE-00

```text
GATE                   = U5Q-T1-TYPE-CLASS-MASKED-CONJUNCTIVE-00
MASTER_RETRIEVAL_OBJECT= TYPE_CLASS
RETRIEVAL_LAW          = masked conjunctive (bound fields; unbound wildcards)
QUERY_LAW              = qse-v1-lexicon-hdc-00 UNCHANGED
RTL_EDIT               = NO
BIT                    = NO
PROGRAM                = NO
REPROGRAM_AGAIN        = NO
RESULT                 = PASS
EVIDENCE_CLASS         = HOST_MODEL
FIRST_DIVERGENCE       = none
U5Q_RAW                = FAIL immutable
U5Q_R1                 = FAIL immutable
U6_OLD_PROFILE         = historical XSim PASS only
U6_SILICON_RETRIEVAL   = NOT PROVEN
U7A                    = CLOSED
```

Claim only: host-model unique TYPE_CLASS table + masked conjunctive match
returns the exact gold type set, with |cands| = |matching types| ≤ 64 and
type-table size saturating at 443 (not 800k).

Not claimed: FPGA type index, U6 silicon, QSE redesign, Gate14, un-failing U5Q raw.

NEXT: FPGA/index implementation of TYPE_CLASS table (not nid-cap sweep).
Not U7A until that path exists and is measured.
