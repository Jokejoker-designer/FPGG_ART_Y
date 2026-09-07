# PREREG — U2R-RESOURCE-MARGIN-RECOVERY-00

```text
GATE        = U2R-RESOURCE-MARGIN-RECOVERY-00
BASE        = d8da32a
RTL_EDIT    = YES  snap mapping only (LUTRAM bind OFF -> frozen snap_ram4k16 BRAM)
SOA/HEAP/C9 = UNTOUCHED
PHYS        = 4
BIT         = NO
PROGRAM     = NO
ORACLE      = HOLD

PRIMARY_UNKNOWN =
  Does scoring with Available-column slice parse PASS, and does mapping
  LM snap to BRAM recover Occupied Slice margin (preferred free>=800)
  without changing T_QUERY or C9/OUT?

HARD =
  WNS>=0 TNS=0 WHS>=0 THS=0 route=0 DRC ERROR=0
  slice tot parsed as 15850 not 0
  BRAM36<=135
  free>=64 (device fit)
PREFERRED =
  free_slices >= 800  (not hard fail)

NOT_THIS_GATE = bitstream, program, U5, router integration, oracle
```
