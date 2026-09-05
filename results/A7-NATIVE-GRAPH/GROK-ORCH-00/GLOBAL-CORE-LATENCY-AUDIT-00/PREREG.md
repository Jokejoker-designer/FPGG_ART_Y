# PREREG — GLOBAL-CORE-LATENCY-AUDIT-00

```text
GATE        = GLOBAL-CORE-LATENCY-AUDIT-00
BASE        = 505e3605dc582e12d96616834fd03f3d261d6f1b
RTL_EDIT    = NO  (bind probe / TB copies only)
SYNTH_IMPL  = NO
BIT         = NO
PROGRAM     = NO
GATE14_PASS = NO
M10         = KEEP_OPEN
PHYS        = 4
WAVE        = 16
ORACLE      = HOLD

PRIMARY_UNKNOWN =
  What exact sub-state occupancy makes C_G the current II limiter,
  and which serialization term is exposed end-to-end?

CLASSIFY =
  C_G_CAND   = ST_CAND + ST_HEAPIFY + ST_NEXT
  C_G_SORT   = ST_SORT
  C_G_COMMIT = ST_COMMIT
  C_G_TOTAL  = C_G_CAND + C_G_SORT + C_G_COMMIT + measured transition overhead

NOT_THIS_GATE = production RTL, PHYS, score skid, bitstream, assumed NEXT
```

MEASURED (MIG_XSIM, no production RTL):

```text
GLOBAL_CORE_AUDIT = PASS
waves=4 merges=4 ST_SORT=28 drop=dup=deadlock=0
C_G_CAND max/avg=23/18.5  C_G_SORT=28  C_G_COMMIT_occ=1
P3P4 C_G_MAX=52 = II  T_QUERY=397
NEXT = NOT_DECLARED
```
