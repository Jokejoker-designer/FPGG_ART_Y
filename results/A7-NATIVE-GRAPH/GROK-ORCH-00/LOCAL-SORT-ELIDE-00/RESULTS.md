# RESULTS — LOCAL-SORT-ELIDE-00

```text
RTL_EDIT    = YES
  a7ng_topk_stream_minheap.sv  parameter SORT_BEFORE_DRAIN (default 1)
  a7ng_ng02_core.sv            SORT_BEFORE_DRAIN=0
BIT_BUILD   = NO
SYNTH_IMPL  = NO
PROGRAM     = NO
ORACLE      = HOLD
GATE14_PASS = NO
M10         = KEEP_OPEN
PHYS        = 4
WAVE        = 16
N           = 64
evidence    = XSIM (SET + order-contract) + MIG_XSIM (P3P4 + occupancy) + XSIM (frozen C9)
```

One unknown: can NG02 skip local `ST_SORT` and drain the K-set in heap-array
order so COLLECT drops the triangular 28 without changing global `(score,id)`
or C9/OUT?

C9 / `learned_prior_graph` keep default `SORT_BEFORE_DRAIN=1`.

Forbidden (untouched): `beats()`, TAKE/HEAPIFY, global `ST_SORT`, PHYS, WAVE,
score skid / `bidx` split, oracle, LM, Fold6.

This gate is the COLLECT attack. It is **not** `SCORER-HEAP-DECOUPLE-00`.
DECOUPLE remains an optional microopt (ceiling ≈ 9 cycles/wave) and is **not**
a fix for dominant C_L.

---

## Success table

| Check | Result |
| --- | --- |
| LOCAL_WAVE_ORDER_CONTRACT | **PASS** (prior gate) |
| LOCAL_SORT_ELIDE_SET | **PASS** n=64 |
| T_QUERY | **500** < 628 |
| cand/cycle | **0.128000** > 0.101911 |
| C_L_MAX | **96 → 68** |
| COLLECT/wave | **37–40 → 9–12** |
| STREAM/wave | 42 / 30 / 30 / 30 (unchanged; now dominant) |
| G_SORT | 112 (global still sorts) |
| OVERLAP3 | 60 |
| BLK_HOLD | 193 → 124 |
| SOA pulses 1–4 | id=60 score=232 |
| FROZEN_C9_REGRESSION | **PASS** HOLD_A C9=`8382238122802120` |
| FROZEN_OUT_REGRESSION | **PASS** 653 / 689 / 237 / 60 |
| P3P4 TB SCORE_LAW 57/165 | **NOT LIVE** on AOS TB (`DATA_MISMATCH=64`); not retargeted |
| LOCAL-SORT-ELIDE-00 | **PASS** |

Do not program. Do not synth/impl this as an intermediate bit. Do not merge as Gate14 pass.

---

## Production delta

`a7ng_topk_stream_minheap.sv`:

```systemverilog
parameter bit SORT_BEFORE_DRAIN = 1'b1
task automatic enter_emit;
  // ord[] identity; then
  if (SORT_BEFORE_DRAIN) st <= ST_SORT;
  else                   st <= ST_DRAIN;
endtask
```

`a7ng_ng02_core.sv`:

```systemverilog
a7ng_topk_stream_minheap #(.K(8), .SORT_BEFORE_DRAIN(1'b0)) u_topk (
```

---

## Occupancy (MIG_XSIM)

```text
LOCAL_CORE_AUDIT_DONE waves=4 C_L_MAX=68 ISSUE_TO_IDLE_MAX=76
OCC FIRE=16 WAIT=32 STREAM=132 COLLECT=39 COMMIT=4 PUSH=32
WAVE0 C_L=68 FIRE=4 WAIT=8 STREAM=42 COLLECT=12 COMMIT=1 PUSH=8
WAVE1-3 C_L=53 FIRE=4 WAIT=8 STREAM=30 COLLECT=9 COMMIT=1 PUSH=8
DOMINANT=HEAP_STREAM
```

COLLECT remainder is `ST_DRAIN` 8 + FSM (no local `ST_SORT`).

---

## Roofline after elide

```text
T_QUERY    = 500
T_RUN      = 305
cand/cycle = 0.128000
C_D_MAX    = 45
C_T_MAX    = 33
C_L_MAX    = 68   ← still bottleneck, now HEAP_STREAM
C_G_MAX    = 52
G_SORT     = 112
II_PRED    = 68
OVERLAP3   = 60
BLK_HOLD   = 124
```

Path from original 1032 @ PHYS=4: sort-bound 744 → overlap 628 → elide 500.

---

## Director correction (locked)

`SCORER-HEAP-DECOUPLE-00` hides inter-batch scorer bubbles only.

```text
FIRE+WAIT = 4+8 = 12 /wave
max hide  = 3 batches × (1 FIRE + 2 WAIT) = 9 /wave
COLLECT   = 37–40 before this gate
```

If DECOUPLE is ever run: split `score_prod_bidx` / `heap_cons_bidx`; 2-bank
reservation at `sc_fire` (scorer has no `ready_i`); not a deep FIFO; not
"fix C_L".

NEXT = `HEAP-TAKE-SIFT-00` (STREAM 30–42 = serial TAKE + HEAPIFY).
