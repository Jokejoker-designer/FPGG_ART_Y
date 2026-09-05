# PREREG — U5Q-R1-SPARSE-ROUTER-RIVAL-RESELECT-00

Opened because U5Q FAIL on current `P4_4k_h64 / CAND_CAP=64`. One rival-profile gate. Not U7A.

```text
GATE                 = U5Q-R1-SPARSE-ROUTER-RIVAL-RESELECT-00
BASE                 = e9c4fbc403c6bcbe662b25503df84a03ed9658ad
QUERY_LAW            = qse-v1-lexicon-hdc-00  UNCHANGED
VALIDITY_LAW         = U4A-R6  UNCHANGED
GOLD                 = U5Q bound-class descriptor equality  UNCHANGED
THRESHOLDS           = U5Q THRESHOLDS.json  UNCHANGED (not retargeted)
CONTROL              = P4_4k_h64_c64
RTL_EDIT             = NO
BIT                  = NO
PROGRAM              = NO
COM12                = UNTOUCHED
GATE14_PASS          = NO
U6_RESULT            = RETAINED
U6_PROMOTION_STATUS  = CONDITIONAL_ON_U5Q
U7A                  = CLOSED
```

## Forbidden

- nid-derived routing keys (`rec_keys(nid)`, CRC(nid), …)
- synthetic XOR extra tables (U4A-R2 P8 k4..k7)
- `relevant = router_union`
- silently raising CAND_CAP on control P4 without this comparison
- opening U7A
- rewriting U5Q/U6 history

## Keys

Only the four FPGA extract keys `{k0,k1,k2,k3}` with U4A-R6 `v[t]`.
Bucket = `k[t] & (n_buckets-1)`. `n_buckets` in {4096, 8192} (16-bit key).

## Profiles (frozen before run)

| name | tables | buckets | head | cap | combine |
|------|--------|---------|------|-----|---------|
| P4_4k_h64_c64 | 0,1,2,3 | 4096 | 64 | 64 | union |
| P2_T02_4k_h64_c64 | 0,2 | 4096 | 64 | 64 | union |
| P2_T01_4k_h64_c64 | 0,1 | 4096 | 64 | 64 | union |
| P2_T02_8k_h128_c192 | 0,2 | 8192 | 128 | 192 | union |
| P4_4k_h128_c128 | 0,1,2,3 | 4096 | 128 | 128 | union |
| P4_4k_h256_c256 | 0,1,2,3 | 4096 | 256 | 256 | union |
| P4_8k_h64_c64 | 0,1,2,3 | 8192 | 64 | 64 | union |
| P4_4k_h64_c64_AND | 0,1,2,3 | 4096 | 64 | 64 | and |
| P2_T02_4k_h64_c64_AND | 0,2 | 4096 | 64 | 64 | and |

`and` = intersection of probed valid tables (still FPGA keys).

## PASS

A rival **meets U5Q bar** iff confirmation queries at all 6 scales satisfy U5Q `THRESHOLDS.json`.

Gate PASS iff **at least one** non-control rival meets the bar.

Then freeze `ROUTER_PROFILE_CANDIDATE` (host-model only). NEXT = U6 rerun on that profile. Not U7A.

If none meet the bar: **FAIL**, no promotion, no U7A, no CAND_CAP raise on P4.

Among passers: min mean bytes at N=16384, then min mean candidate_count.

Control is included as baseline; it is already known FAIL vs U5Q.
