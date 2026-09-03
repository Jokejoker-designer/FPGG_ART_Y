# CLOSEOUT — HEAP-TAKE-SIFT-00

```text
RTL_EDIT     = YES  SIFT_ON_TAKE param; NG02 = 1
BIT          = NO
SYNTH_IMPL   = NO
PROGRAM      = NO
GATE14_PASS  = NO
M10          = KEEP_OPEN
ORACLE       = HOLD

HEAP_TAKE_SIFT_SET    = PASS n=64
T_QUERY_NEW           = 432   < 500
CAND_PER_CYCLE_NEW    = 0.148148
C_L_MAX               = 68 → 39
STREAM                = 42/30 → 16
II_PRED               = 52 = C_G_MAX
FROZEN_C9_REGRESSION  = PASS   HOLD_A C9=8382238122802120
FROZEN_OUT_REGRESSION = PASS   653 / 689 / 237 / 60

HEAP_TAKE_SIFT        = PASS
```

H_CANDIDATE **SUPPORTED**. Combinational 3-level sift on TAKE matches sequential
HEAPIFY SET. STREAM hit WAVE=16 floor. C_L is no longer the roofline limiter.

Do not program. Do not treat DECOUPLE as this result.

NEXT = `GLOBAL-CORE-LATENCY-AUDIT-00`.
