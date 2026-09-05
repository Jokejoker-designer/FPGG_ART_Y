# GitHub PR — DDR-WAVE-PINGPONG-00

Public: https://github.com/Jokejoker-designer/FPGG_ART_Y
Existing PR (do not merge as Gate14 pass):
https://github.com/Jokejoker-designer/FPGG_ART_Y/pull/11

```text
GATE14_PASS = NO
PROGRAM     = NO
BIT_BUILD   = NO
M10         = KEEP_OPEN
ORACLE      = HOLD
```

Dual-bank, two-outstanding AOS prefetch. Same AXI RID. Sequential R
maps to banks. AR(N+1) issues before LAST_R(N).

II_STEADY **46→40**. T_QUERY **310→281**. outstanding_HW=2, AR_OVERLAP=3.

NEXT = `ROOFLINE-REMEASURE-05`. Then prefer M10 sparse retrieval
unless that remeasure shows a remaining pipeline barrier.

Do **not** merge as Gate14 pass. Do not program.
