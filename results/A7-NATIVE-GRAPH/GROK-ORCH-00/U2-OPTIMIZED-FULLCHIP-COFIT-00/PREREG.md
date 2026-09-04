# PREREG — U2-OPTIMIZED-FULLCHIP-COFIT-00

```text
GATE        = U2-OPTIMIZED-FULLCHIP-COFIT-00
BASE        = 7f923b488566e29ee019587527131af0f7cf2630
RTL_EDIT    = NO
BIT         = NO  (no final bit claim; no write_bitstream)
PROGRAM     = NO
GATE14_PASS = NO
PHYS        = 4
TOP         = arty_a7_ng_native_v1_ab_soc_top
PART        = xc7a100tcsg324-1

PRIMARY_UNKNOWN =
  Does the current 281-cycle ping-pong lineage fit and time
  (WNS>=0 TNS=0 WHS>=0 THS=0 route/DRC clean)?

HARD =
  WNS>=0 TNS=0 WHS>=0 THS=0
  UNROUTED=0 FAILED_ROUTE=0
  DRC ERROR/FATAL=0 DEVICE_FIT=PASS

NOT_THIS_GATE = program, final bit, U3 re-implement

FILESET =
  C9 production SoC (G14-FINAL-OBS-BIT-00 list)
  + ping-pong PHYS=4 lineage
  - persist_gen_fast
  - teacher_off_glue
  FIRST U2 SYNTH FAIL = a7ng_learned_prior_graph not in copied P2-G1G5 list

SCORE_NOTE =
  Slice regex must use Available (col 4), not Fixed (col 2).
  tot=0 is parse fail, not DEVICE_FIT fail.
```
