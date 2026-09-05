# CLOSEOUT — CUE-OVERLAP-READY-00

```text
RTL_EDIT     = YES  wf_cons_ready only (mig_top)
BIT          = NO
SYNTH_IMPL   = NO
PROGRAM      = NO
GATE14_PASS  = NO
M10          = KEEP_OPEN
ORACLE       = HOLD

CUE_OVERLAP_SEM       = PASS
T_QUERY_NEW           = 628   < 744
CAND_PER_CYCLE_NEW    = 0.101911
OVERLAP3              = 60
BLK_HOLD              = 193   < 404
FROZEN_C9_REGRESSION  = PASS   HOLD_A C9=8382238122802120
FROZEN_OUT_REGRESSION = PASS   653 / 689 / 237 / 60

DEADLOCK              = 0
DROP                  = 0
DUP                   = 0
OVERWRITE             = 0
accepted              = 64
global merges         = 4

CUE_OVERLAP_READY     = PASS
```

H_CANDIDATE **SUPPORTED**. One-wave TermGen lookahead removes compute backpressure from wave accept. `rec_hold` stays single-occupant (`sched_idle` on accept). NG02 still snapshots `hold_id16/hold_terms16` on `input_hs`. Wall-clock moved with overlap occupancy.

P3P4 TB `id=57 score=165` is **not** a live check on this AOS MIG unit (`DATA_MISMATCH=64`). Do not retarget it. Overlap vs serialized pulses 1–2 are identical (`60/232`). Frozen oracle is C9/OUT.

Do not program. Do not synth/impl this as an intermediate bit.

NEXT = `P3P4-ROOFLINE-REMEASURE-02`.
