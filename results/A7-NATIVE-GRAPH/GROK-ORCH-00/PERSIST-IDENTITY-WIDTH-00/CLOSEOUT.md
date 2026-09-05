# CLOSEOUT — PERSIST-IDENTITY-WIDTH-00

```text
GATE                 = PERSIST-IDENTITY-WIDTH-00
BASE                 = a0a923d02153fb7a396e03edc6f055955ad45e41
REMOTE_HEAD          = a0a923d02153fb7a396e03edc6f055955ad45e41
SOURCE_COMMIT        = bf59f05778305e88586e0723ecc2625b2a38569b
RTL_EDIT             = NO
FILES_CHANGED        = results/.../PERSIST-IDENTITY-WIDTH-00/*
QUERY_LAW            = n/a (persist identity, not qse)
VALIDITY_LAW         = n/a
INDEX_VALIDITY       = n/a
QUERY_VALIDITY       = n/a
BIT_BUILD            = NO
PROGRAM              = NO
GATE14_PASS          = NO
COM12                = UNTOUCHED
U4_AXI               = CLOSED
U5                   = CLOSED
RESULT               = FAIL
EVIDENCE_CLASS       = RTL_FACT + XSIM
FIRST_DIVERGENCE     = DDR persistence serialization
VIOLATED_INVARIANT   = canonical learned identity must survive persistence bit-exact
BLOCKER              = PERSIST_IDENTITY_ALIAS
NEXT                 = PERSIST-IDENTITY-SCHEMA-V2-00
```

Do not continue to U4-MEM02-AXI-DIRECTORY-00 until persist identity PASS.
Do not force canonical IDs to 16-bit. Do not use a lossy hash as identity.

R6 remains published at REMOTE_HEAD `a0a923d` and is not amended.
