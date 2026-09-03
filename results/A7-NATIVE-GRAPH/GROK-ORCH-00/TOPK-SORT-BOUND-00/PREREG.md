# PREREG — TOPK-SORT-BOUND-00

```text
GATE        = TOPK-SORT-BOUND-00
BASELINE    = 29596ac / P3P4-METRIC-REPAIR-00
RTL_EDIT    = YES  (ST_SORT schedule only)
BIT         = NO
SYNTH_IMPL  = NO
PROGRAM     = NO
ORACLE      = HOLD
GATE14_PASS = NO
M10         = KEEP_OPEN
PHYS        = 4
WAVE        = 16
N           = 64

UNKNOWN     = Does a triangular ST_SORT (pass p compares j=0..K-2-p,
              worse-moves-right, 7+6+5+4+3+2+1 = 28 adjacent compares)
              produce the same ordered Top-8 as the rectangular 8×8 ST_SORT?

NOT_THIS_GATE =
  GLOBAL-SORT-FINAL-ONLY (still one sort per wave)
  CUE-OVERLAP-READY
  TERMGEN-II6
  comparator / beats() / heap h[] / C9 / LM / score law
  bitstream / program

H_CANDIDATE = ordered output identical to frozen bitonic / a7ng_topk;
              G_SORT 256 → ~112 (4 × 28); C_L_MAX and T_QUERY fall
H_RIVAL     = fewer passes drop a retained id/score (FAIL this gate)
FALSIFIER   = mismatch vs bitonic or a7ng_topk; edit beats(); sort h[];
              program; claim GATE14_PASS; close M10
UNIT        = tb_a7ng_topk_minheap_diff (global vs frozen bitonic)
              + tb_a7ng_topk_stream_minheap_diff (local vs a7ng_topk)
              + P3P4 MIG_XSIM N=64 PHYS=4 burst=16
```
