# PREREG — LOCAL-TOPK-PARALLEL-COMMIT-00

```text
GATE        = LOCAL-TOPK-PARALLEL-COMMIT-00
BASE        = HEAP-TAKE-SIFT-00 PASS
              T_QUERY=432 C_L=39 COLLECT=9 STREAM=16 II=C_G=52
RTL_EDIT    = YES
  a7ng_topk_stream_minheap.sv  VECTOR_COMMIT (default 0) + ordered_* ports
  a7ng_ng02_core.sv            VECTOR_COMMIT=1; ST_COLLECT samples vector
BIT         = NO
PROGRAM     = NO
ORACLE      = HOLD
GATE14_PASS = NO
M10         = KEEP_OPEN

UNKNOWN     = Can NG02 take the retained K-set as one vector commit
              (8 parallel register reads) instead of 8-cycle serial drain
              then reassembly, without changing SET or C9/OUT?

ALREADY_DONE (do not re-open as this gate) =
  LOCAL-WAVE-ORDER-CONTRACT-AUDIT PASS
  LOCAL-SORT-ELIDE  NG02 SORT_BEFORE_DRAIN=0
  → ST_SORT 28 already off the Global path
  Remaining COLLECT = ST_DRAIN 8 + FSM

NOT_THIS_GATE =
  beats()
  SIFT_ON_TAKE / TAKE-HEAPIFY
  SCORER-HEAP-DECOUPLE (bidx split / 2-bank)  ← separate optional
  PHYS / WAVE / Fold6
  global ST_SORT
  C9 serial drain (default VECTOR_COMMIT=0)
  bitstream

H_CANDIDATE = COLLECT 9→~1; SET DIFF=0 vs serial drain; C9/OUT freeze
FALSIFIER   = SET mismatch; C9/OUT change; deadlock; vector not 8-wide

KEEP serial out_* for generic / C9.
FPGA mapping: 8 wires from h[ord[i]], no extra comparator network.
```
