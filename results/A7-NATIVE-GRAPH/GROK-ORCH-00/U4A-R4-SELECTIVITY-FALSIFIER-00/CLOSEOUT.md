# CLOSEOUT — U4A-R4-SELECTIVITY-FALSIFIER-00

```text
GATE                 = U4A-R4-SELECTIVITY-FALSIFIER-00
BASE                 = e54096fa656e1dccc7063fb0e28dd7dc67bfcc00
SOURCE_COMMIT        = e54096fa656e1dccc7063fb0e28dd7dc67bfcc00
RTL_EDIT             = NO
FILES_CHANGED        = results/.../U4A-R4-SELECTIVITY-FALSIFIER-00/* only
BIT_BUILD            = NO
PROGRAM              = NO
GATE14_PASS          = NO
U5                   = CLOSED
PRIMARY_UNKNOWN      = Does P4_4k_h64 discriminate, or admit the whole small corpus?
RESULT               = FAIL
EVIDENCE_CLASS       = HOST_MODEL
FIRST_DIVERGENCE     = UNRELATED_FULL_CORPUS
VIOLATED_INVARIANT   = unrelated queries must not return the entire labeled corpus
FALSIFIED_ALTERNATIVES = U4A-R3 recall-only quality on 42 titles
NEXT                 = STOP. Do not open U4 AXI. Smallest next = measure which P4 table dumps bucket 0 (k1==0), as a new one-unknown router-law experiment. Persist-identity is a separate defect and was not opened because U4A-R4 did not PASS.
```

## BLOCKER pack

```text
BLOCKER                 = ROUTER_SELECTIVITY_FAIL
FIRST_DIVERGENCE        = UNRELATED_FULL_CORPUS
VIOLATED_INVARIANT      = selectivity: reduction_ratio > 0 on unrelated; Jaccard < 1
EVIDENCE_CLASS          = HOST_MODEL
AFFECTED_COMMIT         = e54096f (U4A-R3 quality claim)
AFFECTED_ARTIFACT       = U4A-R3 CHOSEN P4_4k_h64
WHY CONTINUATION IS UNSAFE = AXI directory would reproduce a non-selective admit-all union
SMALLEST_NEXT_EXPERIMENT = table-ablation HOST_MODEL: route on k0-only vs k1-only vs k2/k3; freeze new PREREG; do not silently drop k1
PROGRAM_STATE           = NO
```
