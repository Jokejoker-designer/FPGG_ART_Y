# GitHub PR — LOCAL-TOPK-PARALLEL-COMMIT-00

Public: https://github.com/Jokejoker-designer/FPGG_ART_Y

```text
GATE14_PASS = NO
PROGRAM     = NO
BIT_BUILD   = NO
M10         = KEEP_OPEN
ORACLE      = HOLD
```

Do **not** merge as Gate14 pass.

NG02 copies Top-8 as one vector (`h[ord[i]]` wires). Serial drain kept for C9.
Skip-local-sort on Global already landed; this is the leftover 8-cycle drain.

| | sift | vector |
| --- | ---: | ---: |
| T_QUERY | 432 | **397** |
| COLLECT | 9 | **1** |
| C_L_MAX | 39 | **31** |
| II_PRED | 52 C_G | **52 C_G** |

NEXT = `GLOBAL-CORE-LATENCY-AUDIT-00`. Not score skid.
