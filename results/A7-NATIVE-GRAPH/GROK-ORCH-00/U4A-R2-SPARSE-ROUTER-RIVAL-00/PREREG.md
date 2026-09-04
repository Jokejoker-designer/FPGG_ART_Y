# PREREG — U4A-R2-SPARSE-ROUTER-RIVAL-00

```text
GATE        = U4A-R2-SPARSE-ROUTER-RIVAL-00
N           = 800000
EVIDENCE    = HOST_MODEL
BIT         = NO
PROGRAM     = NO
FULL_SCAN   = NO

FORBIDDEN =
  relevant = set(union_of_admitted_heads)
  hard-coded CAND_CAP = 256 as freeze
  dropping overflowed records from gold
  freezing a profile with unacceptable corpus coverage

GOLD (independent, built BEFORE router output) =
  For query keys qk[t], table t, buckets B:
    gold = { nid | exists t: rec_keys(nid)[t] % B == qk[t] % B }
  Overflowed nids (did not fit head_cap) REMAIN in gold.

METRIC =
  true recall@K = |gold ∩ cands[:K]| / |gold|
  coverage     = unique nids stored in any head / N
  head_hit     = |gold ∩ stored_heads| / |gold|
  bytes_q      = |cands| * 16 + n_tables * 16

REJECT_PROFILE if coverage < 0.20 or head_hit mean < 0.15

CAND_CAP =
  Pareto over K in {64,128,256,512,1024,2048}:
    maximize recall@K, then minimize mean_bytes, then overflow.
  Do not hard-code 256.

NOT_THIS_GATE = SoC wiring, bitstream, U5 800k silicon
```
