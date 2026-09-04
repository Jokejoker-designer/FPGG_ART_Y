# PREREG — GLOBAL-SORT-FINAL-ONLY-00

```text
GATE        = GLOBAL-SORT-FINAL-ONLY-00
BASE        = f99c095baeb07b1b580b0ecbf8904ce52eca921e  (SPLIT PASS)
RTL_EDIT    = YES
  a7ng_topk_wavefront_minheap.sv  SORT_EVERY_WAVE / wave_last_i
  a7ng_cue_soa_mig_top.sv         instance SORT_EVERY_WAVE=0 + last-wave
SYNTH_IMPL  = NO
BIT         = NO
PROGRAM     = NO
GATE14_PASS = NO
M10         = KEEP_OPEN
PHYS        = 4
WAVE        = 16
ORACLE      = HOLD

PRIMARY_UNKNOWN =
  After completion bookkeeping is independent of ordered result, can
  ST_SORT be skipped on waves 0-2 and run only on the final wave while
  keeping exact retained SET + final ordered Top8 + C9/LM?

PATH =
  W0-W2: CAND/HEAPIFY/NEXT -> merge_done -> NO SORT, no global_valid
  W3:    CAND/HEAPIFY/NEXT -> ST_SORT 28 -> ordered commit + merge_done

MUST_NOT =
  pulse global_valid_o with unordered h[]

PREREG_EVIDENCE =
  G_SORT: 112 -> 28
  merge_done = 4
  final ordered-valid = 1
  final Global Top8 exact (SOA_TOP1 id=60 s=232)
  T_QUERY < 397
  C9 8382238122802120  OUT 653/689/237/60

NOT_PREREG =
  T_QUERY = 397-84   (overlap hides part)

ENGINEERING_PRED (not evidence) =
  W0 C_G ~ C_G_CAND 23
  W1 ~ 19
  W2 ~ 16
  W3 ~ 16+28+1 = 45
  then C_D_MAX=45 may co-limit II

FALSIFIER =
  merge_done != 4
  ordered_valid != 1
  G_SORT != 28
  T_QUERY >= 397
  SET/order mismatch
  C9/OUT change
  drop/dup
  unordered global_valid pulse

NOT_THIS_GATE =
  GLOBAL-TAKE-SIFT (remeasure first)
  DDR ping-pong
  bitstream
```
