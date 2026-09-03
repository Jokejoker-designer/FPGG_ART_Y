# GitHub PR — CUE-OVERLAP-READY-00

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

`wf_cons_ready` no longer waits on `core_batch_ready` / `global_topk_busy`. Those stay at `SCH_ISSUE`. One-wave TermGen lookahead. File: `rtl/native_graph/memory/a7ng_cue_soa_mig_top.sv`.

## Numbers (MIG_XSIM)

| | before | after |
| --- | ---: | ---: |
| T_QUERY | 744 | **628** |
| cand/cycle | 0.086022 | **0.101911** |
| OVERLAP3 | 0 | **60** |
| BLK_HOLD | 404 | **193** |

Ownership: accept=tg=issue=merge=4, drop/dup/overwrite/deadlock=0.

HOLD_A C9=`8382238122802120` OUT 653/689/237/60 frozen.

NEXT = `P3P4-ROOFLINE-REMEASURE-02` (C_L still dominant).
