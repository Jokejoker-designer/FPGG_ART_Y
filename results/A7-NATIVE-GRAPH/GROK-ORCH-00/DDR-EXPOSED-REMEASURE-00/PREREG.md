# PREREG — DDR-EXPOSED-REMEASURE-00

```text
GATE        = DDR-EXPOSED-REMEASURE-00
BASE        = 24dcdc10c0beefafaefdf5c4bc6da51ae13d3ded
RTL_EDIT    = NO
SYNTH_IMPL  = NO
BIT         = NO
PROGRAM     = NO
GATE14_PASS = NO
M10         = KEEP_OPEN
PHYS        = 4
WAVE        = 16
N           = 64
ORACLE      = HOLD

PRIMARY_UNKNOWN =
  After final-only sort, is the II=45 DDR term recurring exposed wait,
  startup-only fill, or a launch-coupling gap?

MEASURE (per wave) =
  AR_FIRE FIRST_R LAST_R FETCH_DONE WAVE_AVAILABLE WAVE_ACCEPT NEXT_AR
DERIVE =
  AR_TO_FIRST_R  R_DRAIN  FETCH_SERVICE
  INTERWAVE_AR_GAP  EXPOSED_WAIT
SEPARATE =
  C_D_SERVICE  C_D_EXPOSED  II_STEADY  FINAL_G_TAIL

ALSO =
  AR count, beat count, bytes
  R backpressure, FIFO high-water, outstanding high-water
  RID/RRESP/RLAST errors

DO_NOT_CHANGE =
  MAX_OUT FIFO burst ping-pong MIG PHYS TopK oracle

DECISION_AFTER_MEASUREMENT_ONLY =
  recurring DDR exposed     -> DDR-WAVE-PINGPONG-00
  startup-only DDR exposed  -> do NOT optimize DDR;
                               reconsider GLOBAL-TAKE-SIFT / next limiter
  large launch gap          -> DDR-LAUNCH-DECOUPLE-00

NOT_THIS_GATE = production RTL, bitstream, assumed NEXT
```
