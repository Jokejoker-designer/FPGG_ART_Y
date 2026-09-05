# GitHub PR — GLOBAL-CORE-LATENCY-AUDIT-00

Public: https://github.com/Jokejoker-designer/FPGG_ART_Y

```text
GATE14_PASS = NO
PROGRAM     = NO
BIT_BUILD   = NO
RTL_EDIT    = NO
M10         = KEEP_OPEN
ORACLE      = HOLD
NEXT        = NOT_DECLARED
```

Do **not** merge as Gate14 pass. Measurement bag only (bind probe + RESULTS).
No production RTL. Frozen bits not programmed.

C_G is the II limiter at PHYS=4: W0 fill = 8+7+8+28+1 = 52 vs C_L=31.
Two serialization terms exposed: `ST_SORT=28/wave` and serial
`CAND+NEXT` floor 16. Neither selected as NEXT.
