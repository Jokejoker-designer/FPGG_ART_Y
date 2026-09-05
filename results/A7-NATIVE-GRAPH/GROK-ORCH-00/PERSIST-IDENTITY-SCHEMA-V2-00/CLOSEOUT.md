# CLOSEOUT — PERSIST-IDENTITY-SCHEMA-V2-00

```text
GATE                 = PERSIST-IDENTITY-SCHEMA-V2-00
BASE                 = bf59f05778305e88586e0723ecc2625b2a38569b
RTL_EDIT             = YES
FILES_CHANGED        = rtl/native_graph/learn/a7ng_learned_prior_store.sv
                       results/.../PERSIST-IDENTITY-SCHEMA-V2-00/*
QUERY_LAW            = n/a
VALIDITY_LAW         = n/a
INDEX_VALIDITY       = n/a
QUERY_VALIDITY       = n/a
BIT_BUILD            = NO
PROGRAM              = NO
GATE14_PASS          = NO
COM12                = UNTOUCHED
U4_AXI               = CLOSED
U5                   = CLOSED
RESULT               = PASS
EVIDENCE_CLASS       = RTL_FACT + XSIM
FIRST_DIVERGENCE     = none
VIOLATED_INVARIANT   = n/a
NEXT                 = U4-MEM02-AXI-DIRECTORY-00
                       (only after this persist identity PASS is accepted)
```

Option A: two-beat DDR record `{subj[31:0],obj[31:0]}` then `{rel,pri,pen,stp,32'd0}`.
Did not force IDs to 16-bit. Did not hash identity. Did not mix router/AXI/U5.

PERSIST-IDENTITY-WIDTH-00 remains FAIL (measurement). This gate repairs it.
R6 commits were not amended.
