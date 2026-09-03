# RESULTS — HEAP-TAKE-SIFT-00

```text
RTL_EDIT    = YES
  a7ng_topk_stream_minheap.sv  parameter SIFT_ON_TAKE (default 0)
  a7ng_ng02_core.sv            SIFT_ON_TAKE=1 (with SORT_BEFORE_DRAIN=0)
BIT_BUILD   = NO
SYNTH_IMPL  = NO
PROGRAM     = NO
ORACLE      = HOLD
GATE14_PASS = NO
M10         = KEEP_OPEN
PHYS        = 4
WAVE        = 16
N           = 64
evidence    = XSIM (SET seq vs sift) + MIG_XSIM + XSIM (frozen C9)
```

One unknown: can TAKE accept + full K=8 sift-up/sift-down complete in the same
cycle so `ST_HEAPIFY` occupancy leaves NG02 STREAM, without changing the K-set
or C9/OUT?

C9 / `learned_prior_graph` keep `SIFT_ON_TAKE=0` (multi-cycle HEAPIFY).

Forbidden: `beats()`, PHYS, WAVE, Fold6, score skid / `bidx` split, global
`ST_SORT`, parallel heaps, bitstream.

---

## Success table

| Check | Result |
| --- | --- |
| HEAP_TAKE_SIFT_SET | **PASS** n=64 (seq HEAPIFY vs SIFT_ON_TAKE) |
| T_QUERY | **432** < 500 |
| cand/cycle | **0.148148** > 0.128000 |
| C_L_MAX | **68 → 39** |
| STREAM/wave | **42/30 → 16** (WAVE=16 floor) |
| COLLECT/wave | 9 |
| C_G_MAX | 52 |
| C_D_MAX | 45 |
| C_T_MAX | 33 |
| G_SORT | 112 |
| II_PRED | **52 = C_G** (C_L no longer max Ci) |
| OVERLAP3 | 60 → 71 |
| BLK_HOLD | 124 → 79 |
| SOA pulses 1–4 | id=60 score=232 |
| FROZEN_C9_REGRESSION | **PASS** HOLD_A C9=`8382238122802120` |
| FROZEN_OUT_REGRESSION | **PASS** 653 / 689 / 237 / 60 |
| HEAP-TAKE-SIFT-00 | **PASS** |

Do not program. Do not synth/impl this as an intermediate bit. Do not merge as Gate14 pass.

---

## Occupancy (MIG_XSIM)

```text
LOCAL_CORE_AUDIT_DONE waves=4 C_L_MAX=39 ISSUE_TO_IDLE_MAX=47
OCC FIRE=16 WAIT=32 STREAM=64 COLLECT=36 COMMIT=4 PUSH=32
WAVE0-3 C_L=39 FIRE=4 WAIT=8 STREAM=16 COLLECT=9 COMMIT=1 PUSH=8
```

STREAM=16 is one accept per candidate. NG02-internal probe still labels
HEAP_STREAM because 16 > COLLECT 9 > WAIT 8, but roofline II is now C_G.

---

## Roofline after sift

```text
T_QUERY    = 432
T_RUN      = 262
cand/cycle = 0.148148
C_D_MAX    = 45
C_T_MAX    = 33
C_L_MAX    = 39
C_G_MAX    = 52   ← bottleneck
G_SORT     = 112
II_PRED    = 52
OVERLAP3   = 71
BLK_HOLD   = 79
```

Path @ PHYS=4: 1032 → sort-bound 744 → overlap 628 → elide 500 → sift 432.

---

## Not this gate

`SCORER-HEAP-DECOUPLE-00` remains optional (ceiling ≈ 9/wave). FIRE+WAIT is
still 4+8. DECOUPLE is not why C_L fell.

NEXT = `GLOBAL-CORE-LATENCY-AUDIT-00` (measure C_G: ST_CAND vs ST_SORT vs drain).
