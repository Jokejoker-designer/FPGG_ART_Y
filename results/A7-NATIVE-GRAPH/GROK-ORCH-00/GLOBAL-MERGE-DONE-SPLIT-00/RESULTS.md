# RESULTS — GLOBAL-MERGE-DONE-SPLIT-00

```text
RTL_EDIT    = YES  contract only
  a7ng_topk_wavefront_minheap.sv  merge_done_o (independent FF)
  a7ng_cue_soa_mig_top.sv         export merge_done_o
  a7ng_native_v1_ab_core.sv       gv_cnt/pending from merge_done
BIT         = NO
PROGRAM     = NO
ORACLE      = HOLD
GATE14_PASS = NO
M10         = KEEP_OPEN
PHYS        = 4
WAVE        = 16
N           = 64
evidence    = UNIT + MIG_XSIM + XSIM C9
```

One unknown: split "wave merge complete" from "ordered Global Top8 ready"
without changing current functional behavior.

This gate is **not** a performance opt. `ST_SORT` still 28 every wave.
`global_valid_o` still pulses every wave. `merge_done_o` is a separate
register, coincident with `ST_COMMIT` this gate (not `assign` tied).

LM bookkeeping: `merge_done_o → gv_cnt`. Ordered result still
`global_valid_o` / `topk_valid_o`.

---

## Success table

| Check | Result |
| --- | --- |
| UNIT md/gv/xor/sort | **4 / 4 / 0 / 112** |
| MIG merge_done | **4** |
| MIG ordered_valid | **4** |
| MIG xor(md, gv) | **0** |
| MIG ST_SORT | **112 = 28×4** |
| drop / dup | **0 / 0** |
| T_QUERY | **397** (unchanged) |
| C_G_MAX | **52** (unchanged) |
| G_SORT | **112** |
| SOA_TOP1 | id=60 score=232 pulse=4 |
| FROZEN_C9 | **PASS** `8382238122802120` |
| FROZEN_OUT | **PASS** 653/689/237/60 |
| GLOBAL-MERGE-DONE-SPLIT-00 | **PASS** |

No unexpected performance delta. No bonus claimed.

H_CANDIDATE **SUPPORTED**. Completion token is independent of ordered
commit. Same-cycle coincidence this gate keeps LM start cycle-equivalent.

NEXT = `GLOBAL-SORT-FINAL-ONLY-00` (now opened).
