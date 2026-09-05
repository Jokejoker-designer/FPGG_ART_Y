# GitHub PR — TOPK-SORT-BOUND-00

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

Do **not** merge this PR as Gate14 pass. Performance microarchitecture only.

## What landed

Triangular `ST_SORT` on the two minheap files only:

- `rtl/native_graph/topk/a7ng_topk_stream_minheap.sv`
- `rtl/native_graph/topk/a7ng_topk_wavefront_minheap.sv`

Pass `p` compares `j=0..K-2-p` (worse-moves-right). Occupancy 28 cycles. `beats()`, heap `h[]`, C9, LM, global recurrence unchanged. Still one global sort per wave.

## Numbers (MIG_XSIM, P3P4 methodology)

| | before | after |
| --- | ---: | ---: |
| T_QUERY | 1032 | **744** |
| cand/cycle | 0.0620 | **0.086022** |
| LOCAL_SORT /wave | 64 | **28** |
| GLOBAL_SORT /wave | 64 | **28** |
| G_SORT | 256 | **112** |
| C_L max | 132 | **96** |
| BLK_HOLD | 621 | **404** |

HOLD_A C9=`8382238122802120` OUT 653/689/237/60 frozen. Local 100k + directed groups DIFF=0. Global waves 1–4 ordered DIFF=0, merge_count=n.

NEXT = `GLOBAL-SORT-FINAL-ONLY-00`.
