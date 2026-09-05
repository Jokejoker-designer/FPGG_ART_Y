# PREREG — DDR-WAVE-PINGPONG-00

```text
GATE        = DDR-WAVE-PINGPONG-00
BASE_RTL    = 24dcdc10c0beefafaefdf5c4bc6da51ae13d3ded
BASE_BAG    = 216bdc5bca9489963619e9bac566df7a3fc3b40e
RTL_EDIT    = YES  a7ng_cue_soa_wavefront.sv
                   a7ng_cue_soa_mig_top.sv (ISSUE waits core only)
SYNTH_IMPL  = NO
BIT         = NO
PROGRAM     = NO
GATE14_PASS = NO
M10         = KEEP_OPEN
PHYS        = 4
WAVE        = 16
N           = 64
BURST       = 16
R_FIFO_DEPTH= 4
ORACLE      = HOLD

PRIMARY_UNKNOWN =
  Can dual-bank, two-outstanding wave prefetch hide recurring DDR RTT
  and reduce II_STEADY below 46 without semantic or ownership change?

REQUIRED_ARCH =
  AR(N+1) issues before LAST_R(N)
  DUAL_BANK = YES
  MAX_INFLIGHT_WAVES = 2
  overlapping bursts use the SAME AXI RID
  sequential R maps to bank ownership; no cross-ID order assumption

KEEP =
  burst=16 WAVE=16 PHYS=4 R_FIFO_DEPTH=4
  TopK Fold6 scorer C9 LM oracle

REQUIRED =
  waves=4 AR=4 beats=64 bytes=1024
  outstanding_HW >= 2
  AR_OVERLAP > 0
  drop=0 dup=0 overwrite=0 out_of_order_delivery=0
  RRESP=0 RLAST=0 RID_ORDER=0
  II_STEADY < 46
  T_QUERY < 310
  C9=8382238122802120
  OUT=653/689/237/60

AFTER_PASS = ROOFLINE-REMEASURE-05
NOT_THIS_GATE = bitstream, program, M10 sparse retrieval, TAKE-SIFT
```
