# GitHub PR — HEAP-TAKE-SIFT-00

Public: https://github.com/Jokejoker-designer/FPGG_ART_Y

```text
GATE14_PASS  = NO
BOARD_PASS   = NO
PROGRAM      = NO
BIT_BUILD    = NO
SYNTH_IMPL   = NO
M10          = KEEP_OPEN
ORACLE       = HOLD
```

Do **not** merge this PR as Gate14 pass.

## What landed

NG02 local minheap sifts on the TAKE handshake (`SIFT_ON_TAKE=1`). Default 0
keeps C9 on multi-cycle `ST_HEAPIFY`. `beats()` unchanged.

Director lock unchanged: `SCORER-HEAP-DECOUPLE-00` is not the C_L fix.

## Numbers (MIG_XSIM)

| | elide | sift |
| --- | ---: | ---: |
| T_QUERY | 500 | **432** |
| cand/cycle | 0.128000 | **0.148148** |
| C_L_MAX | 68 | **39** |
| STREAM/wave | 42 / 30 | **16** (floor) |
| II_PRED | 68 (C_L) | **52 (C_G)** |

HOLD_A C9=`8382238122802120` OUT 653/689/237/60 frozen.

NEXT = `GLOBAL-CORE-LATENCY-AUDIT-00`.
