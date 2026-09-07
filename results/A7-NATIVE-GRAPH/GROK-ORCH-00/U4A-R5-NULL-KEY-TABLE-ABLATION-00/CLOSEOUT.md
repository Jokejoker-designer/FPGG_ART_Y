# CLOSEOUT — U4A-R5-NULL-KEY-TABLE-ABLATION-00

```text
GATE                 = U4A-R5-NULL-KEY-TABLE-ABLATION-00
BASE                 = 917f3488e5972cad1fbe92a7510e2541337c6501
SOURCE_COMMIT        = 917f3488e5972cad1fbe92a7510e2541337c6501
RTL_EDIT             = NO
FILES_CHANGED        = results/.../U4A-R5-NULL-KEY-TABLE-ABLATION-00/*
BIT_BUILD            = NO
PROGRAM              = NO
GATE14_PASS          = NO
U5                   = CLOSED
PERSIST              = CLOSED
U4 AXI               = CLOSED
PRIMARY_UNKNOWN      = Which P4 table causes admit-all, and is key=0 absent vs legitimate?
RESULT               = MEASURE_PASS
EVIDENCE_CLASS       = HOST_MODEL
FIRST_DIVERGENCE     = none (measurement completed)
VIOLATED_INVARIANT   = n/a
FALSIFIED_ALTERNATIVES = "k1=0 is the sole root cause"; "entire routing concept is broken"
NEXT                 = If accepted: U4A-R6-ROUTE-VALIDITY-00
                       {k*_valid, k*} ; valid=0 → do not probe that table
                       Do not silently skip in R5. Do not open U4/U5/persist.
```
