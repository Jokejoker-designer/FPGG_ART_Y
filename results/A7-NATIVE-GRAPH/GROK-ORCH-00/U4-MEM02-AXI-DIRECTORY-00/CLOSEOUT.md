# CLOSEOUT — U4-MEM02-AXI-DIRECTORY-00

```text
GATE                 = U4-MEM02-AXI-DIRECTORY-00
BASE                 = d166ca8edc8c01630efbcc648df8001f40dca572
REMOTE_HEAD_AT_OPEN  = d166ca8edc8c01630efbcc648df8001f40dca572
PRE0                 = PASS
RTL_EDIT             = NO (walker/extractor unchanged after PRE0)
FILES_CHANGED        = results/.../U4-MEM02-AXI-DIRECTORY-00/*
QUERY_LAW            = qse-v1-lexicon-hdc-00  KEY VALUES UNCHANGED
VALIDITY_LAW         = U4A-R6 bind-state; NOT (key != 0)
N_TABLES             = 4
N_BUCKETS            = 4096
CAND_CAP             = 64
BIT_BUILD            = NO
PROGRAM              = NO
GATE14_PASS          = NO
COM12                = UNTOUCHED
U5                   = CLOSED
RESULT               = PASS
EVIDENCE_CLASS       = HOST_MODEL + XSIM
FIRST_DIVERGENCE     = none (final)
VIOLATED_INVARIANT   = n/a
```

Claim only:

> FPGA-owned query features successfully drive the 4x4096 AXI sparse
> directory/posting path and reproduce host-golden candidate identities.

Not claimed: 800k semantic retrieval, P4 final quality, U5 PASS, board PASS.
