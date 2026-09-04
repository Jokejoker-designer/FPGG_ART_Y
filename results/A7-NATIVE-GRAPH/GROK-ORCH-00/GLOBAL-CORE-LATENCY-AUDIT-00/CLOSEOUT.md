# CLOSEOUT — GLOBAL-CORE-LATENCY-AUDIT-00

```text
RTL_EDIT     = NO
SYNTH_IMPL   = NO
BIT          = NO
PROGRAM      = NO
GATE14_PASS  = NO
M10          = KEEP_OPEN
ORACLE       = HOLD
PHYS         = 4
WAVE         = 16

waves                 = 4
global_merge_count    = 4
candidates_to_global  = 8 / wave
ST_SORT               = 28 / wave
drop / dup / deadlock = 0 / 0 / 0

C_G_CAND max/avg      = 23 / 18.5     (ST_CAND+HEAPIFY+NEXT)
C_G_SORT max/avg      = 28 / 28
C_G_COMMIT (occupancy)= 1 / 1         (probe print 2 = valid-rise +1)
C_G_TOTAL probe max   = 53
P3P4 C_G_MAX / II     = 52            (end-to-end limiter)
T_QUERY               = 397 (unchanged)

FROZEN_C9             = HOLD (not re-run; BASE 8382238122802120)
FROZEN_OUT            = HOLD (BASE 653/689/237/60)

GLOBAL_CORE_LATENCY_AUDIT = PASS
NEXT                      = NOT_DECLARED
```

H_CANDIDATE **SUPPORTED** as measurement: C_G is the II limiter because
W0 fill occupies 52 cycles as `CAND 8 + HEAPIFY 7 + NEXT 8 + SORT 28 +
COMMIT 1`, and `C_L_MAX=31`.

Two serialization terms are exposed end-to-end. Neither is selected:

1. `ST_SORT` = 28 every merge (53.8% of C_G_MAX; 112 total).
2. Serial `ST_CAND`+`ST_NEXT` floor = 16 even on reject-all.

No production RTL patch. Do not merge as Gate14 pass. Do not program.
Do not assume the next gate.
