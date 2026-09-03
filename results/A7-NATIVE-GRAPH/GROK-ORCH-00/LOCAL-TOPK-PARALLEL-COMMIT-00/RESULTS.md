# RESULTS — LOCAL-TOPK-PARALLEL-COMMIT-00

```text
RTL_EDIT    = YES
  a7ng_topk_stream_minheap.sv  VECTOR_COMMIT default 0; ordered_* ports
  a7ng_ng02_core.sv            VECTOR_COMMIT=1; ST_COLLECT copies vector
BIT_BUILD   = NO
SYNTH_IMPL  = NO
PROGRAM     = NO
ORACLE      = HOLD
GATE14_PASS = NO
M10         = KEEP_OPEN
PHYS        = 4
WAVE        = 16
N           = 64
evidence    = XSIM SET + MIG_XSIM + XSIM C9
```

One unknown: NG02 takes the retained K-set as one vector of 8 register
reads instead of serial drain then reassembly.

Skip-local-sort on the Global path is **already landed**
(`LOCAL-WAVE-ORDER-CONTRACT` PASS, `SORT_BEFORE_DRAIN=0`). This gate is only
the remaining 8-cycle `ST_DRAIN`. Not mixed with score skid.

C9 keeps serial `out_*` (`VECTOR_COMMIT=0`).

---

## Success table

| Check | Result |
| --- | --- |
| LOCAL_TOPK_PARALLEL_COMMIT_SET | **PASS** n=64 |
| T_QUERY | **397** < 432 |
| cand/cycle | **0.161209** > 0.148148 |
| COLLECT/wave | **9 → 1** |
| C_L_MAX | **39 → 31** |
| STREAM/wave | 16 (floor) |
| C_G_MAX / II_PRED | **52** (unchanged limiter) |
| G_SORT | 112 |
| SOA pulses | id=60 score=232 |
| FROZEN_C9 | **PASS** `8382238122802120` OUT 653/689/237/60 |
| LOCAL-TOPK-PARALLEL-COMMIT-00 | **PASS** |

```text
WAVE0-3  FIRE=4 WAIT=8 STREAM=16 COLLECT=1 COMMIT=1 PUSH=8  C_L=31
```

Path @ PHYS=4: 1032 → 744 → 628 → 500 → 432 → **397**.

Do not program. Do not merge as Gate14 pass.

NEXT = `GLOBAL-CORE-LATENCY-AUDIT-00` (C_G=52, G_SORT=112).
SCORER-HEAP-DECOUPLE remains optional, ceiling ~9, split bidx, not this gate.
