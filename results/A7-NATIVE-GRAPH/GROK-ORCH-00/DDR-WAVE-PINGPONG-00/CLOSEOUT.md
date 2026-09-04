# CLOSEOUT — DDR-WAVE-PINGPONG-00

```text
RTL_EDIT     = YES  wavefront ping-pong + ISSUE waits core only
BIT          = NO
PROGRAM      = NO
SYNTH_IMPL   = NO
GATE14_PASS  = NO
M10          = KEEP_OPEN
ORACLE       = HOLD
PHYS         = 4
WAVE         = 16
N            = 64
BURST        = 16
R_FIFO_DEPTH = 4

DUAL_BANK                 = YES
MAX_INFLIGHT_WAVES        = 2
SAME_RID                  = YES (arid=0)
AR(N+1) before LAST_R(N)  = YES
waves / AR / beats / bytes= 4 / 4 / 64 / 1024
outstanding_HW            = 2
AR_OVERLAP                = 3
drop / dup / ovw / OOO    = 0 / 0 / 0 / 0
RRESP / RLAST / RID       = 0 / 0 / 0
II_STEADY                 = 40 < 46
T_QUERY                   = 281 < 310
SOA_TOPK                  = id=60 score=232
SORT_FINAL                = PASS (md=4 gv=1 sort=28 drop=0)
FROZEN_C9                 = PASS 8382238122802120
FROZEN_OUT                = PASS 653/689/237/60

DDR_WAVE_PINGPONG         = PASS
NEXT                      = ROOFLINE-REMEASURE-05
```

DDR RTT is hidden after W0 (C_D=0 on W1–W3). II is C_T=33, not FETCH_SERVICE=42.

Do not program. Do not merge as Gate14 pass.
