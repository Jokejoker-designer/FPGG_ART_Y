# CLOSEOUT — LOCAL-TOPK-PARALLEL-COMMIT-00

```text
RTL_EDIT     = YES  VECTOR_COMMIT; NG02 vector collect
BIT          = NO
PROGRAM      = NO
GATE14_PASS  = NO
M10          = KEEP_OPEN
ORACLE       = HOLD

SET                   = PASS n=64
T_QUERY_NEW           = 397 < 432
COLLECT               = 9 → 1
C_L_MAX               = 39 → 31
II_PRED               = 52 = C_G
FROZEN_C9             = PASS 8382238122802120
FROZEN_OUT            = PASS 653/689/237/60

LOCAL_TOPK_PARALLEL_COMMIT = PASS
```

H_CANDIDATE **SUPPORTED**. 8 parallel wires from `h[ord[i]]`, no extra
comparator. Serial `out_*` kept for C9.

Skip-sort on Global was already done; this removed the leftover serialize
step. Raw ~144 cy (sort+drain)×4 was the pre-elide envelope; this gate took
the remaining drain (~32 cy, measured T_QUERY −35).

NEXT = `GLOBAL-CORE-LATENCY-AUDIT-00`.
