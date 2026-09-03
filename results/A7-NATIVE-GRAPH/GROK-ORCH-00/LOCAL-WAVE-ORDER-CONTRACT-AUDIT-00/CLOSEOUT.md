# CLOSEOUT — LOCAL-WAVE-ORDER-CONTRACT-AUDIT-00

```text
RTL_EDIT = NO
BIT      = NO
PROGRAM  = NO

1-wave identity vs reverse vs 16 shuffles : DIFF=0
4-wave reverse / shuffle                  : DIFF=0
equal-score unique-id reverse             : DIFF=0

LOCAL_WAVE_ORDER_CONTRACT = PASS
NEXT = LOCAL-SORT-ELIDE-00
```

Global `lane=8+i` does not change `(score,id)` ranking when ids are unique.
Skipping local `ST_SORT` preserves the K-set that global already re-sorts.
