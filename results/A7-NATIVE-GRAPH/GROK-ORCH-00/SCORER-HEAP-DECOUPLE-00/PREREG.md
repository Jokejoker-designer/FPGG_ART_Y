# PREREG — SCORER-HEAP-DECOUPLE-00  (OPTIONAL MICROOPT — NOT dominant C_L)

```text
GATE        = SCORER-HEAP-DECOUPLE-00
STATUS      = OPEN_OPTIONAL_NOT_DOMINANT
RTL_EDIT    = YES  a7ng_ng02_core.sv only, if/when run
BIT         = NO
PROGRAM     = NO
ORACLE      = HOLD
GATE14_PASS = NO
M10         = KEEP_OPEN

ROLE        = hide inter-batch scorer bubbles only
CEILING     = 3 * (1 FIRE + 2 WAIT) = 9 cycles/wave  (first batch still serial)
NOT         = "fix dominant C_L"
DOMINANT_CL = LOCAL ST_SORT 28 + ST_DRAIN 8  (COLLECT 37-40)

UNKNOWN     = Can a reserved 2-bank score skid overlap FIRE/WAIT(k+1)
              with STREAM(k) without corrupting heap lane tags?

HARD_HAZARD =
  one bidx is currently both score producer index and heap consumer index.
  Must split score_prod_bidx vs heap_cons_bidx.
  Scorer has no ready_i: reserve a free bank at sc_fire, not at sc_valid_p.
  Architecture = two banks (active+skid), not a deep FIFO.

NOT_THIS_GATE =
  parallel heaps
  beats()/ranking
  PHYS
  C9/LM/oracle
  local ST_SORT elide
  bitstream

Do not start this gate as the C_L attack. NEXT dominant = LOCAL-WAVE-ORDER-CONTRACT
then LOCAL-SORT-ELIDE if presentation order is not in the global SET.
```

