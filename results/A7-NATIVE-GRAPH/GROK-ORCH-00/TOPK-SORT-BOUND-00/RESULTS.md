# RESULTS — TOPK-SORT-BOUND-00

```text
RTL_EDIT    = YES  ST_SORT schedule only (local + global minheap)
BIT_BUILD   = NO
SYNTH_IMPL  = NO
PROGRAM     = NO
ORACLE      = HOLD
GATE14_PASS = NO
M10         = KEEP_OPEN
PHYS        = 4
WAVE        = 16
N           = 64
evidence    = XSIM (exact Top-8) + MIG_XSIM (P3P4-METRIC-REPAIR-00 methodology)
mig_log_sha = 921DA02C68F84D3DA6BBC49B007AFC2F8D22BAD913A94045879383C616AA6BED
c9_log_sha  = F804AEE9D9EADCF41BC8B8431E8E1E6A09CEB818801C890B47948E7026314DE2
```

One unknown: triangular `ST_SORT` (pass `p` compares `j=0..K-2-p`, 28 adjacent swaps, wrap on last-compare edge) vs rectangular 64-cycle `ST_SORT`. Comparator `beats()`, heap `h[]`, C9, LM, score law, global recurrence `G_{t+1}=TopK(G_t ∪ TopK(W_t))` untouched. Still one global sort per wave.

First attempt (prefix-shrink `j=p..K-2`) **FAILED** vs bitonic (247 mismatches). Production swap is worse-moves-right; sorted suffix grows on the right. Corrected to `j=0..K-2-p`.

Allowed RTL delta only:

- `rtl/native_graph/topk/a7ng_topk_stream_minheap.sv`
- `rtl/native_graph/topk/a7ng_topk_wavefront_minheap.sv`

---

## Success table (spec)

| Check | Result |
| --- | --- |
| LOCAL_TOPK_DIFF | **PASS** DIFF_COUNT=0 |
| GLOBAL_TOPK_DIFF | **PASS** DIFF_COUNT=0 |
| FROZEN_C9_REGRESSION | **PASS** HOLD_A C9=`8382238122802120` |
| FROZEN_OUT_REGRESSION | **PASS** 653 / 689 / 237 / 60 |
| LOCAL_SORT | **64 → 28** /wave |
| GLOBAL_SORT | **64 → 28** /wave |
| T_QUERY_NEW | **744** < 1032 |
| CAND_PER_CYCLE_NEW | **0.086022** > 0.0620 |
| DEADLOCK | **0** |
| DROP | **0** (delivered=64, waves=4) |
| DUP | **0** (ACC_W=TG_W=L_W=4; 4 local + 4 global SORT_RUN) |
| accepted candidates | **64** |
| global merge count | **4** |
| TOPK_SORT_BOUND | **PASS** |

NEXT = `GLOBAL-SORT-FINAL-ONLY-00`. Do not jump to PHYS, DDR, or CUE-OVERLAP.

---

## A. Local minheap differential

Production `tb_a7ng_topk_stream_minheap_diff.sv` vs frozen `a7ng_topk`:

- 100,000 randomized vectors
- eqscore_id, dup_score_id, two_dups, signed_ext, mask underfill 0..16, backpressure
- MISMATCH_COUNT=0, FAILS=0
- marker `LOCAL_MINHEAP_STREAM_TOP8_XSIM_PASS`

Bag `tb_g14_local_groups.sv` (clocked NBA capture) vs frozen `a7ng_topk`:

| group | result |
| --- | --- |
| reverse_ordered | DIFF=0 |
| ordered_input | DIFF=0 |
| all_equal_scores | DIFF=0 |
| duplicate_ids | DIFF=0 |
| score_ties_id_asc | DIFF=0 |
| id_ties_lane_asc | DIFF=0 |
| lane_ties_same_score_id | DIFF=0 |
| all_negative | DIFF=0 |
| int16_extrema | DIFF=0 |
| underfill | DIFF=0 |
| invalid_entries | DIFF=0 |
| worst_case_replacements | DIFF=0 |
| rnd 256 extra | DIFF=0 |

`LOCAL_GROUPS_XSIM_PASS DIFF_COUNT=0`. Occupancy in that TB: `SORT_OCC_SUM code=2 n_run=268 min=28 max=28 bad=0`.

H_RIVAL (dropped id/score) **FALSIFIED**.

---

## B. Global recurrence differential

Production `tb_a7ng_topk_minheap_diff.sv` vs frozen bitonic: `GLOBAL_TOPK_MINHEAP_XSIM_PASS` mismatches=0.

Bag `tb_g14_global_waves.sv` ordered after **each** wave, not only the final set:

| n_waves | merge_b | merge_h | ordered DIFF |
| ---: | ---: | ---: | --- |
| 1 | 1 | 1 | 0 |
| 2 | 2 | 2 | 0 |
| 3 | 3 | 3 | 0 |
| 4 | 4 | 4 | 0 |
| rnd 4 | 4 | 4 | 0 |

`GLOBAL_WAVES_XSIM_PASS DIFF_COUNT=0`. Occupancy: `SORT_OCC_SUM code=4 n_run=14 min=28 max=28 bad=0`.

Isolated occupancy unit `tb_g14_sort_bound_count.sv`: local code=2 cycles=28; global code=4 cycles=28. `SORT_BOUND_COUNT_XSIM_PASS`.

---

## C. Frozen C9 / OUT regression

Same DUT/TB as BIT-07 (`tb_a7ng_gate14_c9_soc_cofit.sv`). No oracle retarget.

```text
C9_PACK_A/U/C/B = 8382238122802120 / 8786858483828180 / 2322832182208180 / 8382438142804140
LM_OUT_A/U/C/B  = 653 / 689 / 237 / 60
FIRST_DIVERGENCE = NONE
GATE14_C9_SOC_COFIT_XSIM_PASS fails=0
C9_FROZEN_REGRESSION_PASS
```

Any bit change here would have been REJECT PATCH. It did not change.

---

## Query roofline (MIG_XSIM, P3P4-METRIC-REPAIR-00 methodology)

Bind occupancy probe (no production RTL edit). Authority for sort cycles is `SORT_OCC_SUM`, not WAVE3 `C_G` latch.

| Metric | Baseline | After | Δ |
| --- | ---: | ---: | ---: |
| T_QUERY | 1032 | **744** | **-288** |
| T_RUN | 801 | **585** | -216 |
| cand/cycle | 0.062016 | **0.086022** | |
| C_L max | 132 | **96** | -36 |
| C_G max | 102 | **66** | -36 |
| G_SORT | 256 | **112** | -144 (= 4×(64-28)) |
| LOCAL_SORT_CYCLES/wave | 64 | **28** | -36 |
| GLOBAL_SORT_CYCLES/wave | 64 | **28** | -36 |
| S_TAX | 325 | **217** | -108 |
| BLK_HOLD | 621 | **404** | -217 |
| II_PRED | 132 | **96** | still C_L |
| II_WAVE_OBS | 267 | **195** | |
| η_TG | 0.75 | 0.75 | unchanged |
| C_D_EXPOSED | 45 | 45 | fill only |
| OVERLAP3 | 0 | 0 | |
| AXI | 1024 | 1024 | |
| delivered | 64 | 64 | |
| waves | 4 | 4 | |

```text
SORT_OCC_SUM code=2 n_run=4 sum=112 min=28 max=28 bad=0   LOCAL
SORT_OCC_SUM code=4 n_run=4 sum=112 min=28 max=28 bad=0   GLOBAL
P3P4_REPAIR_DONE T_QUERY=744 T_RUN=585 ACC_W=4 TG_W=4 L_W=4 G_W=3
P3P4_REPAIR_TB_PASS delivered=64
```

Per-wave after (C_D / C_T / C_L / C_G):

| wave | C_D | C_T | C_L | C_G | t_accept |
| ---: | --: | --: | --: | --: | -------: |
| 0 | 45 | 33 | 96 | 65 | 46 |
| 1 | 43 | 33 | 81 | 48 | 241 |
| 2 | 43 | 33 | 81 | 66 | 404 |
| 3 | 43 | 33 | 81 | 0* | 585 |

`*` WAVE3 `C_G` latch missed (`G_W=3`). Occupancy `G_SORT=112` and four `SORT_RUN code=4 cycles=28` are the authority that the fourth global sort ran.

Wall-clock ΔT_QUERY = −288 equals 4×36 local + 4×36 global because both sorts sit on the serialized `wf_cons_ready` path. That is a measured MIG_XSIM fact for this control, not a claim that every future overlap change will save 288.

`cell_fail=1` is the sealed packing expect 832 B vs AOS 1024 B / 64. Same P3P4 packing FAIL. Not a metric miss.

---

## Falsifiers (none fired)

- TopK differential = 0
- C9 / OUT frozen
- comparator `beats()` identical to `a7ng_topk.sv`
- heap `h[]` still min-heap; sort permutes `ord[]` only
- sort occupancy = 28
- T_QUERY decreased (1032 → 744)
- no deadlock, no dropped wave, no duplicate wave
- accepted = 64, global merges = 4

Classification is **not** `MICRO_OPT_CORRECT / END_TO_END_GAIN_FALSIFIED`. End-to-end T_QUERY fell.

---

## What this does not close

- Still one global sort **per wave** (`GLOBAL-SORT-FINAL-ONLY-00` is next).
- `II_PRED` still `C_L=96` (score + stream heap + 28-cycle sort + push).
- `BLK_HOLD=404` remains the overlap tax (`CUE-OVERLAP-READY-00` after re-measure).
- `η_TG=0.75` (`TERMGEN-II6-00`).
- No synth, no impl, no bit, no program, no GATE14_PASS, M10 KEEP_OPEN.
