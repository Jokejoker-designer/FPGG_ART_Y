# CLOSEOUT — U5Q-R1-SPARSE-ROUTER-RIVAL-RESELECT-00

```text
GATE                     = U5Q-R1-SPARSE-ROUTER-RIVAL-RESELECT-00
BASE                     = e9c4fbc403c6bcbe662b25503df84a03ed9658ad
RTL_EDIT                 = NO
FILES_CHANGED            = results/.../U5Q-R1-SPARSE-ROUTER-RIVAL-RESELECT-00/*
QUERY_LAW                = qse-v1-lexicon-hdc-00 UNCHANGED
VALIDITY_LAW             = U4A-R6 UNCHANGED
GOLD                     = U5Q UNCHANGED
THRESHOLDS               = U5Q UNCHANGED
BIT_BUILD                = NO
PROGRAM                  = NO
GATE14_PASS              = NO
COM12                    = UNTOUCHED
U6_RESULT                = RETAINED
U6_PROMOTION_STATUS      = CONDITIONAL_ON_U5Q
U7A                      = CLOSED
U7                       = CLOSED
U8                       = CLOSED
RESULT                   = FAIL
EVIDENCE_CLASS           = HOST_MODEL
FIRST_DIVERGENCE         = NO_RIVAL_MEETS_U5Q_BAR
VIOLATED_INVARIANT       = at least one bounded rival meets frozen U5Q bar
ROUTER_PROFILE_CANDIDATE = none
```

Nine host-model rivals (union/and, 2/4 tables, 4k/8k buckets, head 64..256,
cap 64..256) using only FPGA extract keys. None meet frozen U5Q thresholds
on the confirmation set at all six scales.

Do not promote a profile. Do not raise CAND_CAP on P4. Do not open U7A.
Do not rewrite U5Q or U6.

AND intersection is a diagnostic: it can zero leak/water FPs and still
fails Master recall@256 and 800k instance-recall.

## NEXT

Not U7A. A later gate may change gold grain (instance vs type) or query
features only under a new prereg — not this gate.
