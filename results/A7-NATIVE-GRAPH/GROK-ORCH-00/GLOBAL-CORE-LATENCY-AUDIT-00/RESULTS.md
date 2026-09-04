# RESULTS — GLOBAL-CORE-LATENCY-AUDIT-00

```text
GATE        = GLOBAL-CORE-LATENCY-AUDIT-00
BASE        = 505e3605dc582e12d96616834fd03f3d261d6f1b
RTL_EDIT    = NO
SYNTH_IMPL  = NO
BIT         = NO
PROGRAM     = NO
GATE14_PASS = NO
M10         = KEEP_OPEN
PHYS        = 4
WAVE        = 16
N           = 64
ORACLE      = HOLD
evidence    = MIG_XSIM  (bind-only occupancy probe)
NEXT        = NOT_DECLARED
```

Measurement only. Production RTL not patched. Frozen C9 not re-run
(RTL_EDIT=NO; HOLD from BASE `505e360` PASS).

One unknown: what exact global minheap sub-state occupancy makes `C_G`
the current II limiter, and which serialization term is exposed end-to-end.

---

## Required counts (MIG_XSIM)

| Check | Result |
| --- | --- |
| waves | **4** |
| global_merge_count | **4** |
| candidates_to_global | **8 / wave** (`wave_n=8`; pin `wave_scored_i=16`) |
| ST_SORT | **28 / wave exactly** (`sort28=1`) |
| drop | **0** |
| dup | **0** |
| deadlock / inflight | **0** |
| GLOBAL_CORE_AUDIT | **PASS** |
| P3P4 T_QUERY | **397** (unchanged vs BASE) |
| P3P4 C_G_MAX / II_PRED | **52** |
| P3P4 G_SORT | **112** |
| BLK_CORE / BLK_GLOBAL | **2 / 59** |
| FROZEN_C9 this gate | **HOLD** (not re-run; no production RTL) |
| HOLD_A C9 (BASE) | `8382238122802120` |
| OUT (BASE) | 653 / 689 / 237 / 60 |

```text
GLOBAL_CORE_AUDIT_DONE waves=4 merges=4 C_G_MAX=53 C_G_AVG=48 ST_SORT_OK=1
GLOBAL_CORE_OCC CAND=32 HEAPIFY=10 NEXT=32 SORT=112 COMMIT=4 BUSY=190 BLK_UP=59
GLOBAL_CORE_SEM drop=0 dup=0 deadlock=0 inflight=0 wave_scored_pin=16
GLOBAL_CORE_CHECKS sort28=1 cand8=1 merge_eq_waves=1 w0_set=1 out_order=1
GLOBAL_CORE_AUDIT_PASS
```

---

## Classification (as specified)

```text
C_G_CAND   = ST_CAND + ST_HEAPIFY + ST_NEXT
C_G_SORT   = ST_SORT
C_G_COMMIT = ST_COMMIT
C_G_TOTAL  = C_G_CAND + C_G_SORT + C_G_COMMIT
             + measured transition overhead
```

Two C_G_TOTAL views are reported because the probe latches per-wave
totals on `global_valid_o` rise, which is the IDLE cycle after
`ST_COMMIT` (NBA). Occupancy `always_ff` and P3P4 `busy_o` count the
live FSM.

| View | What it is | W0 / W1 / W2 / W3 | max / avg |
| --- | --- | --- | --- |
| Probe print `C_G_TOTAL` | states + `t_commit+1` at valid rise | 53 / 49 / 46 / 46 | **53 / 48** |
| P3P4 / `busy_o` `C_G` | `st != IDLE` | 52 / 48 / 45 / 45 | **52 / 47.5** |
| OCC sum | CAND+HF+NEXT+SORT+COMMIT | 32+10+32+112+4 = **190** | matches `P3P4_C_G_OCC=190` |

Probe `C_G_COMMIT` print = 2 every wave. Occupancy `COMMIT=4` over 4
waves = **1 / wave**. RTL `ST_COMMIT` is one cycle (vector write of K,
then IDLE). The extra printed 1 is capture on valid-rise in IDLE, not a
second commit state. End-to-end limiter uses **P3P4 C_G = 52**.

---

## Per-wave occupancy

Probe state counts (CAND / HEAPIFY / NEXT / SORT as occupied; COMMIT
print includes +1 capture):

| w | ST_CAND | ST_HEAPIFY | ST_NEXT | ST_SORT | ST_COMMIT print | C_G_CAND | C_G_SORT | C_G_COMMIT print | C_G_TOTAL print | P3P4 C_G |
| ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| 0 | 8 | 7 | 8 | 28 | 2 | 23 | 28 | 2 | 53 | **52** |
| 1 | 8 | 3 | 8 | 28 | 2 | 19 | 28 | 2 | 49 | **48** |
| 2 | 8 | 0 | 8 | 28 | 2 | 16 | 28 | 2 | 46 | **45** |
| 3 | 8 | 0 | 8 | 28 | 2 | 16 | 28 | 2 | 46 | **45** |
| **max** | 8 | 7 | 8 | 28 | 2 | **23** | **28** | 2 | 53 | **52** |
| **avg** | 8 | 2.5 | 8 | 28 | 2 | **18.5** | **28** | 2 | 48.5 | **47.5** |

P3P4-aligned COMMIT = 1; P3P4-aligned TOTAL = C_G_CAND + 28 + 1.

Candidate / heapify events:

| w | ACCEPTED | FIRST_EMPTY | ROOT_REPL | REJECTED | HF_UP | HF_DOWN | MERGE |
| ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| 0 | 8 | 8 | 0 | 0 | 7 | 0 | 1 |
| 1 | 2 | 0 | 2 | 6 | 0 | 3 | 1 |
| 2 | 0 | 0 | 0 | 8 | 0 | 0 | 1 |
| 3 | 0 | 0 | 0 | 8 | 0 | 0 | 1 |
| tot | 10 | 8 | 2 | 22 | 7 | 3 | **4** |

Wave 0 fills G from empty (8 inserts; HEAPIFY=7 because emp=0 skips
sift). Wave 1 replaces root twice. Waves 2–3 reject all 8. `ST_CAND=8`
and `ST_NEXT=8` on every wave, including reject-all.

---

## PRIMARY_UNKNOWN

**Sub-state occupancy that makes C_G the II limiter**

After local opts, `C_L_MAX=31` and `BLK_CORE=2`. II is
`max(C_i)=C_G`. Worst wave is fill (W0):

```text
P3P4 C_G_MAX = 52
  = ST_CAND 8 + ST_HEAPIFY 7 + ST_NEXT 8 + ST_SORT 28 + ST_COMMIT 1
  = C_G_CAND 23 + C_G_SORT 28 + C_G_COMMIT 1
```

Share of W0=52:

| term | cycles | share of C_G_MAX |
| --- | ---: | ---: |
| C_G_SORT (ST_SORT) | 28 | **53.8%** |
| C_G_CAND | 23 | **44.2%** |
|   ST_CAND | 8 | 15.4% |
|   ST_HEAPIFY | 7 | 13.5% |
|   ST_NEXT | 8 | 15.4% |
| C_G_COMMIT | 1 | **1.9%** |

Reject-all floor (W2/W3): `8+0+8+28+1 = 45`, still `> C_L=31`.

**Serialization terms exposed end-to-end** (both measured; neither
assumed as NEXT):

1. **Always-on triangular `ST_SORT` = K(K−1)/2 = 28 / merge**, every
   wave, independent of accept/reject. `G_SORT=112=28×4`. Heap `h[]` is
   not permuted; `ord[]` bubble only. Runs even when the K-set did not
   change (W2/W3).
2. **Serial 8-step `ST_CAND` + `ST_NEXT` floor = 16 / wave**, even when
   all 8 candidates are rejected. One candidate per CAND, one NEXT
   between candidates; no skip of the remaining walk.

`C_G_COMMIT` is not the limiter (1 cycle, vector of K). HEAPIFY is
data-dependent (7 → 3 → 0) and already 0 on reject-all waves.

Do not treat `ST_SORT` as the only lever. Do not assume the next gate.

---

## INPUT / OUTPUT Top-8

**W0 — EVIDENCE (w0_set=1, out_order=1)**

```text
INPUT_TOP8_SET    id=32,s=203  40,214  36,205  44,216  60,232  52,221  48,219  56,230
OUTPUT_TOP8_ORDER id=60,s=232  56,230  52,221  48,219  44,216  40,214  36,205  32,203
OUTPUT_TOP8_SET   same as ORDER (best-first)
```

SET(W0 in) = SET(W0 out). Slot0 = best (60/232). Matches prior SOA pulse.

**W1–W3 INPUT_TOP8_SET — probe dump defect, not used as semantic proof**

Dump shows eight identical garbage ids per wave
(`2818091/209`, `3390949917/190`, `1225804048/170`). That dump cannot
produce W1 `ACCEPTED=2 REJECTED=6`. Occupancy counters (accept / empty /
replace / reject / HF dir) remain consistent with the RTL FSM.
OUTPUT W1+ dump repeats the same garbage ids in the two replaced slots;
not used as SET evidence.

`out_order=1` is the probe's pairwise `beats` on captured OUTPUT rows,
including the defective W1–W3 rows. W0 order is independently consistent
with SET equality.

---

## Cross-check vs BASE P3P4 (unchanged)

```text
T_QUERY=397  T_RUN=246  cand/cycle=0.161209
C_L_MAX=31  FIRE=4 WAIT=8 STREAM=16 COLLECT=1 COMMIT=1 PUSH=8   (all 4 waves)
C_G_OCC=190 C_G_MAX=52 G_SORT=112
II_PRED_MAX_Ci=52
BLK_HOLD=65 BLK_GLOBAL=59 BLK_CORE=2
```

Path @ PHYS=4: 1032 → 744 → 628 → 500 → 432 → **397**. Limiter still C_G.

---

## Evidence class

| Claim | Class |
| --- | --- |
| Per-wave ST_* occupancy, SORT=28, waves/merges/drop/dup | EVIDENCE (MIG_XSIM) |
| P3P4 C_G_MAX=52 is the II limiter vs C_L=31 | EVIDENCE |
| ST_SORT 28 and CAND+NEXT 16 are both exposed serialization | EVIDENCE |
| Probe C_G_TOTAL = P3P4 C_G + 1 | EVIDENCE (valid-rise capture) |
| W0 INPUT SET = OUTPUT SET, best-first | EVIDENCE |
| W1–W3 INPUT/OUTPUT SET dump | NEEDS_EXPERIMENT (probe defect) |
| Frozen C9 this gate | HOLD (not re-run; RTL unchanged vs BASE) |
| GATE14_PASS / BOARD_PASS / PROGRAM | **NO** |

Production RTL SHA256 (unchanged vs `505e360`):

```text
a7ng_topk_wavefront_minheap.sv  C5BFFA8F55F0F917E8AAA4E8F4C3896242A36AAF86E295E9B84448AA4F2B2189
a7ng_topk_stream_minheap.sv     DF17B26911A7682EE7EE29040EC6F1E0C26926A11FEC5AF629A07AB48A226448
a7ng_ng02_core.sv               74A3F626E5E21553F7CB86FCAB94A1F1218B6B84BFEF2E3E3938DDB1F5ED224B
```
