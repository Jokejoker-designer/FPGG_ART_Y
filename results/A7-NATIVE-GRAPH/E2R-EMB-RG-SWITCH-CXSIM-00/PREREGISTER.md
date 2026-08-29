# E2R-EMB-RG-SWITCH-CXSIM-00 — PREREGISTER

**Date:** 2026-08-28  
**Worktree:** `D:/Jetking_sem4/SEM_4/arty-a7-online-lm-board`  
**Agent:** `a7-ng-xsim-verify`  
**Authority:** `results/A7-NATIVE-GRAPH/STATUS/E2R_EMB_RG_SWITCH_CXSIM_DISPATCH.md`  
**Prior:** CORE_PRED UART replica; POS miss REGION_DONE nline=128  
**Class:** C-XSIM `tiny_gpt803k_core` ST_EMB TOK vs POS `waddr` region-switch count  
**Board:** NOT used. No COM. No program. No bitstream. No `vivado.exe` impl.  
**Product RTL:** NOT edited. `arty_a7_ng_native_v1_ab_soc_top` / MIG **not instantiated**.  
**C-FIX:** NONE (name only; not applied).  
**Phase 2 / `graph_late_materialize_00`:** not this bag.  
**lock.owner:** grok (unchanged).  
**SIM_FULL:** **1** (stall=0). Do **not** run SIM_FULL=0 DMA farm.

## Scientific frame (frozen before first start_fwd)

| Field | Value |
|-------|-------|
| OBSERVATION | POS-only miss REGION_DONE nline=128. Silicon 300 s no CORE_DONE. ST_EMB alternates TOK/POS in RTL. |
| UNKNOWN | during one `start_fwd` ST_EMB (`ctx_n=8`), how many TOK vs POS `waddr` sets / region switches? |
| H_CANDIDATE | `OSC_2ND` — ≈ `2*ntok*D` TOK+POS sets (alternate every dim) |
| H_RIVAL | `HOLD_RG` — few switches (one TOK region + one POS for the whole emb) |
| FALSIFIER | `SIM_FULL=0` (DMA farm); SoC/MIG; C-FIX; stop before leave ST_EMB without timeout class |
| UNIT | one `start_fwd` embedding (`ctx_n=8`) |
| CONTROL | ST_EMB sub0 TOK / sub2 POS; REGION_DONE nline law (not executed here) |
| METRICS | tok_sets, pos_sets, rg_switches, cycles in ST_EMB, leave_emb |

## Vehicle

Instantiate `tiny_gpt803k_core #(.SIM_FULL(1))` only. Hierarchical peek `st` / `waddr` / `sub`. Load `ctx_n_in=8`, pulse `start_fwd`. Count `waddr` sets whose address is in TOK (`< OFF_POS`) vs POS (`OFF_POS .. OFF_L0-1`) until `st` leaves `ST_EMB` or timeout **100000** clk. Do not instantiate SoC/MIG. Do not edit `rtl/**`.

## Verdict classes (preregistered)

| Class | Meaning |
|-------|---------|
| `OSC_2ND` | tok_sets≈1024 and pos_sets≈1024 (`2*8*128`) |
| `HOLD_RG` | rg_switches ≤ 2 |
| `OSC_OTHER` | left EMB; counts match neither |
| `NO_EMB` | never enter or never leave ST_EMB (timeout) |

Marker `E2R_EMB_RG_SWITCH_CXSIM_00_XSIM_PASS` if classified. Existence not claimed. nline×count×MIG ms is ENGINEERING_INFERENCE only.

## Forbidden

- `SIM_FULL=0` DMA farm
- `graph_late_materialize_00` / Phase 2
- Program board / bitstream
- Edit `rtl/**` / C-FIX
- Instantiate `arty_a7_ng_native_v1_ab_soc_top` or MIG
- Stop before leave ST_EMB without `NO_EMB` timeout class
- Declare `BOARD_PASS` or existence
- Steal Grok R6 lock
