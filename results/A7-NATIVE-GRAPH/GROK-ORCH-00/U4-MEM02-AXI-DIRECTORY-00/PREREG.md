# PREREG — U4-MEM02-AXI-DIRECTORY-00

Opened after U4-PRE0 `ROUTER_TO_AXI_GEOMETRY_COMPATIBILITY` PASS.
Geometry is now P4_4k_h64. This gate is the **semantic path**, not a second geometry rewrite.

```text
GATE            = U4-MEM02-AXI-DIRECTORY-00
BASE            = d166ca8edc8c01630efbcc648df8001f40dca572
PRE0            = PASS  ROUTER_TO_AXI_GEOMETRY_COMPATIBILITY
QUERY_LAW       = qse-v1-lexicon-hdc-00  KEY VALUES UNCHANGED
VALIDITY_LAW    = U4A-R6 bind-state; NOT (key != 0)
N_TABLES        = 4
N_BUCKETS       = 4096
BUCKET_W        = 12
CAND_CAP        = 64
BIT             = NO
PROGRAM         = NO
COM12           = UNTOUCHED
U5              = CLOSED
GATE14_PASS     = NO
```

PRIMARY_UNKNOWN:

> Can FPGA-generated valid qse-v1-lexicon-hdc-00 route keys drive the real
> MEM02 AXI directory/posting path and produce exactly the expected bounded
> candidate identities without host semantic help?

Required path:

```text
raw query
→ U3Q feature extractor
→ {k*_valid,k*}
→ valid-table selection
→ AXI directory lookup
→ posting fetch
→ union/dedup
→ CAND_CAP bounded stream
```

Must prove (stop at first divergence):

1. invalid table is not probed
2. valid=1,key=0 still probes
3. directory address matches host golden
4. posting IDs match host golden before scorer
5. no duplicate IDs after dedup
6. candidate_count <= CAND_CAP
7. no hidden full scan
8. AXI traffic is bounded independent of corpus N
9. no drop/dup/order error
10. fully unknown query produces zero candidates

Do not: reopen U4A law; change qse keys; remove T3; use key!=0 as validity;
use host bucket/candidate/winner/address; open U5; build bit; program board.
