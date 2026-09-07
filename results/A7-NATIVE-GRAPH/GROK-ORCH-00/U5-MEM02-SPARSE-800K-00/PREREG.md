# PREREG — U5-MEM02-SPARSE-800K-00

Opened after U4-MEM02 remote PASS `4677ad2`.

```text
GATE            = U5-MEM02-SPARSE-800K-00
BASE            = 4677ad26762d3ccc81e3fe204a236c43d7c90b55
QUERY_LAW       = qse-v1-lexicon-hdc-00  UNCHANGED
VALIDITY_LAW    = U4A-R6  UNCHANGED
N_TABLES        = 4
N_BUCKETS       = 4096
CAND_CAP        = 64
HEAD_CAP        = 64
SENTINEL        = 20'hC34FF = 799999
BIT             = NO
PROGRAM         = NO
COM12           = UNTOUCHED
U6              = CLOSED
GATE14_PASS     = NO
```

PRIMARY_UNKNOWN:

> As corpus N grows, does the same FPGA qse→AXI directory/posting path
> keep dir_ar ≤ 4, candidates ≤ CAND_CAP, bytes/query independent of N,
> and retrieve sentinel 799999 — with no full scan?

Not this gate: 800k DRAM fill, U6 unified retrieval, scorer/Top-K quality, board.

## Scale law

```text
SPREAD: extra records in unprobed buckets
  → chiller dir_ar, bytes, emit stay constant vs N

COLLIDE: extra records in the probed bucket
  → emit saturates at CAND_CAP; overflow explicit
  → still no loop over TOTAL_N

SENTINEL: ID 799999 lives at a high posting address and is emitted.
```

STOP at first: TRAFFIC_GROWS_WITH_N, FULL_SCAN, SENTINEL_MISS, CAP_ERROR.
