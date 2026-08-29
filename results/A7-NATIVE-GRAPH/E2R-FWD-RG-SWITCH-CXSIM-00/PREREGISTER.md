# E2R-FWD-RG-SWITCH-CXSIM-00 — PREREGISTER

**Date:** 2026-08-28  
**Worktree:** `D:/Jetking_sem4/SEM_4/arty-a7-online-lm-board`  
**Agent:** `a7-ng-xsim-verify`  
**Authority:** `results/A7-NATIVE-GRAPH/STATUS/E2R_FWD_RG_SWITCH_CXSIM_DISPATCH.md`  
**Prior:** E2R-EMB-RG-SWITCH-CXSIM-00 CLASS=OSC_2ND tok=1024 pos=1024 leave_emb=1  
**Class:** C-XSIM `tiny_gpt803k_core` start_fwd→done TOK/POS/other `waddr` set count  
**Board:** NOT used. No COM. No program. No bitstream. No `vivado.exe` impl.  
**Product RTL:** NOT edited. `arty_a7_ng_native_v1_ab_soc_top` / MIG **not instantiated**.  
**C-FIX:** NONE (name only; not applied).  
**Phase 2 / `graph_late_materialize_00`:** not this bag.  
**lock.owner:** grok (unchanged).  
**SIM_FULL:** **1** (stall=0). Do **not** run SIM_FULL=0 DMA farm.

## Scientific frame (frozen before first start_fwd)

| Field | Value |
|-------|-------|
| OBSERVATION | ST_EMB is 1024 TOK + 1024 POS sets. Layers after EMB also use `waddr`. Silicon 300 s no CORE_DONE. |
| UNKNOWN | from `start_fwd` to core `done`, how many TOK / POS / other-rg `waddr` sets? |
| H_CANDIDATE | `FWD_HEAVY` — after-EMB sets ≫ 0; total ≫ 2048 |
| H_RIVAL | `EMB_DOM` — after leave_emb, few more rg sets; total ≈ 2048 |
| FALSIFIER | `SIM_FULL=0`; stop at leave ST_EMB; SoC/MIG; C-FIX |
| UNIT | one `start_fwd` until `done` (`ctx_n=8`) |
| CONTROL | OSC_2ND tok=1024 pos=1024 leave_emb=1 |
| METRICS | tok_sets, pos_sets, other_sets, rg_switches, done, cycles |

## Vehicle

Instantiate `tiny_gpt803k_core #(.SIM_FULL(1))` only. Hierarchical peek `st` / `waddr` / `sub`. Load `ctx_n_in=8`, pulse `start_fwd`. **Do not stop at leave ST_EMB.** Watch until `done==1` or timeout **40000000** clk (preregistered minimum 5000000; 40e6 covers estimated ~18e6 ST_MV cycles plus LN/attn/head).

Set law (CONTROL-preserving):

- In ST_EMB: sub0→1 = TOK set (`waddr < OFF_POS`); sub2→3 = POS set (`OFF_POS .. OFF_L0-1`).
- After leave ST_EMB: each `waddr` change is a set, classified TOK / POS / other.
- other = `waddr` not in TOK or POS windows (`OFF_*` from `a7lm06_pkg`).

Do not instantiate SoC/MIG. Do not edit `rtl/**`.

## Verdict classes (preregistered)

| Class | Meaning |
|-------|---------|
| `FWD_HEAVY` | `done=1` and (`other_sets>64` or `total_sets>2048+64`) |
| `EMB_DOM` | `done=1` and after-EMB rg sets ≤ 64 |
| `NO_DONE` | timeout, `done=0` |
| `NO_EMB` | never ST_EMB |

Marker `E2R_FWD_RG_SWITCH_CXSIM_00_XSIM_PASS` if classified. Existence not claimed. DMA-time remains ENGINEERING_INFERENCE.

## Forbidden

- `SIM_FULL=0` DMA farm
- Stop at leave ST_EMB
- `graph_late_materialize_00` / Phase 2
- Program board / bitstream
- Edit `rtl/**` / C-FIX
- Instantiate `arty_a7_ng_native_v1_ab_soc_top` or MIG
- Declare `BOARD_PASS` or existence
- Steal Grok R6 lock
