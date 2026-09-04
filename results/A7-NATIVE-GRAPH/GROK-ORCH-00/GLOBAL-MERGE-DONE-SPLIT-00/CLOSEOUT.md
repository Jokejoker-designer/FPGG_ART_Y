# CLOSEOUT — GLOBAL-MERGE-DONE-SPLIT-00

```text
RTL_EDIT     = YES  merge_done_o contract
BIT          = NO
PROGRAM      = NO
GATE14_PASS  = NO
M10          = KEEP_OPEN
ORACLE       = HOLD

merge_done            = 4
ordered_valid         = 4
xor(md, global_valid) = 0
ST_SORT               = 28 x 4
T_QUERY               = 397
C_G_MAX               = 52
FROZEN_C9             = PASS 8382238122802120
FROZEN_OUT            = PASS 653/689/237/60

GLOBAL_MERGE_DONE_SPLIT = PASS
NEXT                    = GLOBAL-SORT-FINAL-ONLY-00
```

Contract-only. Not a performance gate. `merge_done_o` is not wired as
`assign` to `global_valid_o`.
