# CLOSEOUT — GLOBAL-SORT-FINAL-ONLY-00

```text
RTL_EDIT     = YES  SORT_EVERY_WAVE=0 on SOA global instance
BIT          = NO
PROGRAM      = NO
GATE14_PASS  = NO
M10          = KEEP_OPEN
ORACLE       = HOLD

merge_done            = 4
ordered_valid         = 1
G_SORT                = 28
T_QUERY               = 310 < 397
C_G_MAX               = 45
II_PRED               = 45 = C_D_MAX
FROZEN_C9             = PASS 8382238122802120
FROZEN_OUT            = PASS 653/689/237/60

GLOBAL_SORT_FINAL_ONLY = PASS
ROOFLINE_CASE          = A  (DDR co-limiter)
NEXT                   = DDR-EXPOSED-REMEASURE
```

Not `GLOBAL-TAKE-SIFT-00`. Intermediate C_G is 16–23; II is 45 = C_D.
Memory optimization is now the first time it is worth paying for.
Do not program. Do not merge as Gate14 pass.
