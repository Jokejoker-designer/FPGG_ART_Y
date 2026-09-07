# PREREG — U5Q-T2-FPGA-TYPE-CLASS-TABLE-00

```text
GATE            = U5Q-T2-FPGA-TYPE-CLASS-TABLE-00
BASE            = 7ef5b1c370023280f4ffe2d2a4740195cb8b7b2e
OBJECT          = TYPE_CLASS
QUERY_LAW       = qse-v1-lexicon-hdc-00 UNCHANGED
RETRIEVAL_LAW   = masked conjunctive
SCAN            = sequential TYPE_CLASS catalog (not 800k nids)
CLASS_ID_W      = 16
CAND_CAP        = 64
RTL_EDIT        = YES (new typeclass table/scan only)
BIT             = NO
PROGRAM         = NO
REPROGRAM_AGAIN = NO
U7A             = CLOSED
```

CLASS_ID = 16'd1 + rank of sorted (eid,iid,rid,xid). Not from NID.
member_ptr = first catalog index (16-bit). member_count >= 1 or row illegal.
