# CLOSEOUT — U5Q-R2A-RETRIEVAL-OBJECT-GRAIN-AUDIT-00

```text
GATE                 = U5Q-R2A-RETRIEVAL-OBJECT-GRAIN-AUDIT-00
BASE                 = 9755147a11efefc37146257e61fa546dc0a5b334
RTL_EDIT             = NO
BIT                  = NO
PROGRAM              = NO
REPROGRAM_AGAIN      = NO
RESULT               = MEASURE_PASS
EVIDENCE_CLASS       = HOST_MODEL
OVERALL_DIAGNOSIS    = RAW_INSTANCE_RECALL_INCOMPATIBLE_WITH_BOUNDED_CAP
MASTER_OBJECT        = NOT CHOSEN
U5Q                  = STILL FAIL
U7A                  = CLOSED
NEXT                 = U5Q-R2B-QUERY-FEATURE-DISCRIMINABILITY-AUDIT-00
```

At N=800k, chiller gold is 34000 raw nids / 29 class tuples.
Raw recall 0.80 needs ≥27200 candidates. Class recall 0.80 needs ≥24.

U5Q instance-level bar is the wrong grain for a cap-64 sparse retriever
**if** Master meant semantic types. If Master meant raw nids, the bar is
structurally unreachable under CAND_CAP=64. R2B tests whether `{k,v}` can
separate classes. Do not retarget U5Q thresholds here.
