# PREREG — GLOBAL-CORE-LATENCY-AUDIT-00

```text
GATE        = GLOBAL-CORE-LATENCY-AUDIT-00
BASE        = HEAP-TAKE-SIFT-00 PASS
              T_QUERY=432 C_L_MAX=39 C_G_MAX=52 G_SORT=112 II_PRED=52
RTL_EDIT    = NO  (probe / TB only)
BIT         = NO
PROGRAM     = NO
ORACLE      = HOLD
GATE14_PASS = NO
M10         = KEEP_OPEN

UNKNOWN     = Which global-minheap state occupies C_G_MAX=52:
              ST_CAND (8 inserts) vs ST_SORT (28) vs ST_DRAIN vs wait-on-core?

WHY         = After local STREAM hit WAVE=16 floor, roofline II is C_G not C_L.
              G_SORT=112 is 4×28 triangular sort occupancy.
              Do not assume ST_SORT is the only C_G lever until measured
              the same way LOCAL-CORE-LATENCY-AUDIT measured NG02.

NOT_THIS_GATE =
  production RTL
  PHYS
  SCORER-HEAP-DECOUPLE
  bitstream
  retarget oracle
```
