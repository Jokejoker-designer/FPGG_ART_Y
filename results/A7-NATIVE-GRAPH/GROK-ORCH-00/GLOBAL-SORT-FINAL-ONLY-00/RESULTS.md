# RESULTS — GLOBAL-SORT-FINAL-ONLY-00

```text
RTL_EDIT    = YES
  a7ng_topk_wavefront_minheap.sv  SORT_EVERY_WAVE / wave_last_i
  a7ng_cue_soa_mig_top.sv         instance SORT_EVERY_WAVE=0
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

One unknown: skip `ST_SORT` on waves 0–2 and sort only the final wave,
keeping retained SET + final ordered Top8 + C9/LM.

Default `SORT_EVERY_WAVE=1` (C9 / other instances unchanged). SOA
instance is 0. Intermediate waves pulse `merge_done_o` only. Ordered
`global_valid_o` only after final triangular sort. Never publishes
unordered `h[]`.

---

## Success table

| Check | Result |
| --- | --- |
| UNIT md / gv / sort | **4 / 1 / 28** |
| MIG merge_done | **4** |
| MIG ordered_valid | **1** |
| MIG mid ordered | **0** |
| MIG G_SORT | **28** (was 112) |
| drop | **0** |
| T_QUERY | **310** < 397 |
| C_G_MAX | **45** (was 52) |
| II_PRED | **45** |
| C_D_MAX | **45** |
| C_L_MAX | **31** |
| C_T_MAX | **33** |
| BLK_GLOBAL | **3** (was 59) |
| SOA_TOPK_PULSE | id=60 score=232 (n=1) |
| FROZEN_C9 | **PASS** `8382238122802120` |
| FROZEN_OUT | **PASS** 653/689/237/60 |
| GLOBAL-SORT-FINAL-ONLY-00 | **PASS** |

Per-wave C_G (MIG, matches audit C_G_CAND + final sort):

| w | C_G | notes |
| ---: | ---: | --- |
| 0 | **23** | C_G_CAND only |
| 1 | **19** | C_G_CAND only |
| 2 | **16** | C_G_CAND only |
| 3 | **45** | 16 + SORT 28 + COMMIT 1 |

T_QUERY 397→310 is **−87** = 3×(28+1). The 3 skipped COMMIT cycles
came with the skipped sorts. Overlap did not hide this term because
C_G was the II limiter.

---

## Roofline after this gate — Case A (EVIDENCE)

```text
C_D_MAX = 45
C_T_MAX = 33
C_L_MAX = 31
C_G_MAX = 45   (final wave only)
C_G W0-W2 = 23 / 19 / 16  (< 25)
II_PRED = 45 = max(C_D, C_G_final)
BLK_GLOBAL = 3
```

DDR is now a real co-limiter with final-wave C_G. Do **not** open
`GLOBAL-TAKE-SIFT-00` yet. CAND+NEXT=16 is still on W2/W3 but II is
already 45 = C_D.

NEXT = `DDR-EXPOSED-REMEASURE` (memory). TAKE-SIFT only if a later
remeasure shows Global still blocking.

Path @ PHYS=4: 1032 → 744 → 628 → 500 → 432 → 397 → **310**.
