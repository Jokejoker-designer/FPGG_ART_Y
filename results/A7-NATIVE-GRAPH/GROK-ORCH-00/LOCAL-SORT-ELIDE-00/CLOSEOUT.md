# CLOSEOUT — LOCAL-SORT-ELIDE-00

```text
RTL_EDIT     = YES  SORT_BEFORE_DRAIN param; NG02 = 0
BIT          = NO
SYNTH_IMPL   = NO
PROGRAM      = NO
GATE14_PASS  = NO
M10          = KEEP_OPEN
ORACLE       = HOLD

LOCAL_SORT_ELIDE_SET  = PASS n=64
T_QUERY_NEW           = 500   < 628
CAND_PER_CYCLE_NEW    = 0.128000
C_L_MAX               = 96 → 68
COLLECT               = 37–40 → 9–12
DOMINANT              = HEAP_STREAM
FROZEN_C9_REGRESSION  = PASS   HOLD_A C9=8382238122802120
FROZEN_OUT_REGRESSION = PASS   653 / 689 / 237 / 60

LOCAL_SORT_ELIDE      = PASS
```

H_CANDIDATE **SUPPORTED**. Local `ST_SORT` was presentation order, not the
K-set. Global already re-sorts. C9 instance unchanged (default=1).

Do not program. Do not treat `SCORER-HEAP-DECOUPLE-00` as this result.

NEXT = `HEAP-TAKE-SIFT-00`.
