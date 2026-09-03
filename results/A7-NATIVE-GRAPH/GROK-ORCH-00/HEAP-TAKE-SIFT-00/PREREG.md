# PREREG — HEAP-TAKE-SIFT-00

```text
GATE        = HEAP-TAKE-SIFT-00
BASE        = LOCAL-SORT-ELIDE-00 PASS  (T_QUERY=500, C_L_MAX=68, STREAM=30–42)
RTL_EDIT    = YES  a7ng_topk_stream_minheap.sv only
BIT         = NO
PROGRAM     = NO
ORACLE      = HOLD
GATE14_PASS = NO
M10         = KEEP_OPEN

UNKNOWN     = Can TAKE accept + full K=8 sift-up/sift-down complete in the
              same cycle so ST_HEAPIFY occupancy leaves NG02 STREAM,
              without changing the K-set or C9/OUT?

WHY         = After elide, DOMINANT=HEAP_STREAM.
              heap_in_ready = (st == ST_TAKE) only.
              NG02 sits in ST_STREAM for the whole serial
              TAKE(1) + HEAPIFY(1–3) per candidate.
              Wave0 STREAM=42, wave1–3 STREAM=30.
              Floor if II=1 accept: STREAM ≈ 16 /wave (WAVE=16).

H_CANDIDATE = combinational 3-level sift on the TAKE handshake;
              stay in ST_TAKE; SET DIFF=0 vs current multi-cycle HEAPIFY;
              C_L and T_QUERY fall; C9/OUT freeze.
FALSIFIER   = SET mismatch; C9/OUT change; deadlock; STREAM not down.

NOT_THIS_GATE =
  beats() law
  PHYS / WAVE / Fold6
  SCORER-HEAP-DECOUPLE (optional, ceiling ~9, split bidx, 2-bank reserve)
  global ST_SORT
  parallel heaps
  bitstream

HAZARD =
  control FSM and no-reset datapath are split always_ff.
  Sift must use pre-NBA fill_n / h[] and write the entire new heap
  in one datapath cycle. Do not read the just-written slot as if
  sequential HEAPIFY had already swapped.

K=8 depth<=3: unroll 3 sift steps. Keep beats() identical.
Default SORT_BEFORE_DRAIN=1 still used by C9.
```
