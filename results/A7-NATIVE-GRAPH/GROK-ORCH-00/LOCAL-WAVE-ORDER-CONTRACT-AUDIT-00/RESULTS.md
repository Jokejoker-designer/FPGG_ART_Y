# RESULTS — LOCAL-WAVE-ORDER-CONTRACT-AUDIT-00

Measurement / contract only. No production RTL.

```text
RTL_EDIT    = NO
BIT         = NO
PROGRAM     = NO
ORACLE      = HOLD
GATE14_PASS = NO
M10         = KEEP_OPEN
evidence    = XSIM  tb_g14_wave_order_contract.sv
```

Unknown: does global `a7ng_topk_wavefront_minheap` ordered Top-8 `(score,id)`
depend on local presentation order, or only on the candidate SET?

`lane=8+i` is unused for ranking when ids are unique (`beats` valid→score desc→id asc→lane).

| Vector | Result |
| --- | --- |
| 1-wave identity vs reverse vs 16 shuffles | DIFF=0 |
| 4-wave reverse / shuffle | DIFF=0 |
| equal-score unique-id reverse | DIFF=0 |
| `LOCAL_WAVE_ORDER_CONTRACT_PASS` | **PASS** |

H_CANDIDATE **SUPPORTED**. Local `ST_SORT` is not required for the global K-set.

NEXT = `LOCAL-SORT-ELIDE-00`.
