# PREREG — SCORER-HEAP-DECOUPLE-00

```text
GATE        = SCORER-HEAP-DECOUPLE-00
RTL_EDIT    = YES  a7ng_ng02_core.sv only (planned)
BIT         = NO
PROGRAM     = NO
ORACLE      = HOLD
GATE14_PASS = NO
M10         = KEEP_OPEN

UNKNOWN     = Can a 1-batch PHYS score skid let FIRE/WAIT of batch k+1
              overlap STREAM of batch k without changing local Top-8?

NOT_THIS_GATE =
  parallel heaps
  beats()/ranking
  PHYS
  C9/LM/oracle
  FRONTIER_REQUIRED
  bitstream

H_CANDIDATE = C_L falls; TopK pulses 1-4 stay id=60 score=232 vs CUE baseline
              (this AOS TB); C9/OUT frozen
FALSIFIER   = TopK change; deadlock; C_L not down
```
