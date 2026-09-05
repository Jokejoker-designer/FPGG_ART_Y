# GitHub PR — LOCAL-WAVE-ORDER-CONTRACT-AUDIT-00 + LOCAL-SORT-ELIDE-00

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

NG02 local minheap drains without `ST_SORT`. Parameter `SORT_BEFORE_DRAIN`
defaults to 1 (C9 / learned-prior unchanged). NG02 sets 0.

Director lock: `SCORER-HEAP-DECOUPLE-00` is **not** the C_L fix (ceiling ≈ 9
cycles/wave; split `score_prod_bidx`/`heap_cons_bidx`; 2-bank reservation).

## Numbers (MIG_XSIM)

| | overlap | elide |
| --- | ---: | ---: |
| T_QUERY | 628 | **500** |
| cand/cycle | 0.101911 | **0.128000** |
| C_L_MAX | 96 | **68** |
| COLLECT/wave | 37–40 | **9–12** |
| STREAM/wave | 30–42 | 30–42 (now dominant) |

HOLD_A C9=`8382238122802120` OUT 653/689/237/60 frozen.

NEXT = `HEAP-TAKE-SIFT-00`.
