# PREREG — GLOBAL-MERGE-DONE-SPLIT-00

```text
GATE        = GLOBAL-MERGE-DONE-SPLIT-00
BASE        = c8f654f4dc8dcb552cd9f36e7e0ee0ff048a2e83
              (RTL BASE 505e360 GLOBAL-CORE-LATENCY-AUDIT bag)
RTL_EDIT    = YES  contract files only
  a7ng_topk_wavefront_minheap.sv
  a7ng_cue_soa_mig_top.sv
  a7ng_native_v1_ab_core.sv
SYNTH_IMPL  = NO
BIT         = NO
PROGRAM     = NO
GATE14_PASS = NO
M10         = KEEP_OPEN
PHYS        = 4
WAVE        = 16
ORACLE      = HOLD

PRIMARY_UNKNOWN =
  Can "wave merge complete" be split from "ordered Global Top8 ready"
  without changing any current functional behavior?

THIS_GATE_IS_NOT_A_PERF_OPT.

KEEP =
  ST_SORT every wave = 28
  global_valid_o every wave = unchanged
  bit-exact / cycle-equivalent functional behavior

ADD =
  merge_done_o  (independent FF, this gate coincident with ST_COMMIT)

LM =
  was: topk_valid_o -> gv_cnt
  now: merge_done_o -> gv_cnt
  ordered result still global_valid_o / topk_valid_o

INVARIANT =
  waves=4  merge_done=4  ordered_valid=4  gv_cnt=4
  ST_SORT=28x4  C_G_MAX=52  T_QUERY=397 ± bookkeeping only
  drop=dup=0  global SET/order exact
  C9 8382238122802120  OUT 653/689/237/60

FALSIFIER =
  merge_done != 4
  ordered_valid != 4
  merge_done XOR global_valid this gate
  LM start moves
  C9/OUT change
  drop/dup
  SET/order mismatch
  T_QUERY or C_G_MAX significant unexpected delta

NOT_THIS_GATE =
  skip ST_SORT on W0-W2   (that is GLOBAL-SORT-FINAL-ONLY-00)
  GLOBAL-TAKE-SIFT
  PHYS / score skid / bitstream
  assumed NEXT beyond SPLIT PASS

NEXT_IF_PASS = GLOBAL-SORT-FINAL-ONLY-00
```
