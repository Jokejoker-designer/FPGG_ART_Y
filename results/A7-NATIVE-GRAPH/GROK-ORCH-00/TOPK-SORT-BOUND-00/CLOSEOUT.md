# CLOSEOUT — TOPK-SORT-BOUND-00

```text
RTL_EDIT     = YES  ST_SORT only (two minheap files)
BIT          = NO
SYNTH_IMPL   = NO
PROGRAM      = NO
GATE14_PASS  = NO
M10          = KEEP_OPEN
ORACLE       = HOLD

LOCAL_TOPK_DIFF       = PASS
GLOBAL_TOPK_DIFF      = PASS
FROZEN_C9_REGRESSION  = PASS   HOLD_A C9=8382238122802120
FROZEN_OUT_REGRESSION = PASS   653 / 689 / 237 / 60

LOCAL_SORT            = 64 -> 28
GLOBAL_SORT           = 64 -> 28

T_QUERY_NEW           = 744   < 1032
CAND_PER_CYCLE_NEW    = 0.086022  > 0.0620

DEADLOCK              = 0
DROP                  = 0
DUP                   = 0
accepted              = 64
global merges         = 4

TOPK_SORT_BOUND       = PASS
```

H_CANDIDATE **SUPPORTED**. First (wrong-end) triangular bound FALSIFIED vs bitonic; corrected worse-moves-right bound is bit-exact and cuts wall-clock.

Do not program. Do not retarget oracle. Do not start overlap or PHYS in this gate.

NEXT = `GLOBAL-SORT-FINAL-ONLY-00`.
