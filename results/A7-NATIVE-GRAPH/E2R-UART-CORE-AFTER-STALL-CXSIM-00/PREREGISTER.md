# E2R-UART-CORE-AFTER-STALL-CXSIM-00 — PREREGISTER

**Date:** 2026-08-28  
**Worktree:** `D:/Jetking_sem4/SEM_4/arty-a7-online-lm-board`  
**Agent:** `a7-ng-xsim-verify`  
**Authority:** `results/A7-NATIVE-GRAPH/STATUS/E2R_UART_CORE_AFTER_STALL_CXSIM_DISPATCH.md`  
**Prior:** `results/A7-NATIVE-GRAPH/E2R-UART-SKEW-CXSIM-00/` (replica, no SoC instantiate)  
**Class:** C-XSIM UART `hb_next` after W_STALL / PHASE sent  
**Board:** NOT used. No COM. No program. No bitstream. No `vivado.exe` impl.  
**Product RTL:** NOT edited. `arty_a7_ng_native_v1_ab_soc_top` / MIG **not instantiated**.  
**C-FIX:** NONE (name only; not applied).  
**Phase 2 / `graph_late_materialize_00`:** not this bag.  
**lock.owner:** grok (unchanged).

## Scientific frame (frozen before first print step)

| Field | Value |
|-------|-------|
| OBSERVATION | REARM UART ends `W_STALL` / `PHASE=01`. `hb_next` can return 54/55 after mask 51/52. `have_pending` includes `core_done_100` / `pred_ready`. UART-SKEW showed print-time leftover. |
| UNKNOWN | after 51/52 are sent, if `core_done` then `pred_ready` rise later, does `nxt_sel` become 54 then 55? |
| H_CANDIDATE | `PRINT_DEAD` — `core_done=1` but `nxt_sel` never 54/55 |
| H_RIVAL | `CORE_PRED` — 54 then 55 after stall/phase sent |
| FALSIFIER | raise `core_done` before 51/52; skip `sent_mask`; instantiate SoC/MIG; C-FIX |
| UNIT | one print sequence (stall → phase → late `core_done` → pred) |
| CONTROL | UART-SKEW replica style; SoC `hb_next` order 51,52,53,54,55; other `*_ok` = 0; ATOM 69/70 = 0; BOOT `mask[0]` sent first (else `hb_next` always returns 0) |
| METRICS | `nxt_sel` after each step; `have_pending`; `sent_mask` bits 51/52/54/55 |

## One change vs a blank replica

Drive 51 then 52 first; **then** raise `core_done_100`; **then** `pred_ready`. Do not raise them in the same step as stall.

## Drive steps (replication axis)

| Step | Drive | Expect if H_RIVAL |
|------|-------|-------------------|
| SETUP | send `mask[0]` (BOOT) | `nxt_sel=0` before send |
| A | `w_stall_ok=1` `phase_ok=1` `core_done=0` `pred_ready=0` | `nxt_sel=51`, then send `mask[51]` |
| B | same, `mask[51]=1` | `nxt_sel=52`, then send `mask[52]` |
| C | raise `core_done_ok=1` (pred still 0) | `nxt_sel=54`, then send `mask[54]` |
| D | raise `pred_ok` / `pred_ready=1` | `nxt_sel=55` |

`pred_ready` is driven as the SoC `pred_ok` argument. `bind_100` stays 0 so slot 35 does not win. SoC `pred_ready = bind_100 && (pred_100 != 0)` is not used as a drive (would force `bind_ok=1`).

## Verdict classes (preregistered)

| Class | Meaning |
|-------|---------|
| `CORE_PRED` | `nxt_sel=54` after stall/phase sent, then `nxt_sel=55` after `pred_ready` |
| `CORE_ONLY` | 54 yes, 55 never |
| `PRINT_DEAD` | `core_done=1`, never 54/55 |
| `NO_STALL` | never selected 51/52 |

Marker `E2R_UART_CORE_AFTER_STALL_CXSIM_00_XSIM_PASS` if classified. Existence not claimed. Does not authorize program or a UART RTL fix.

## Vehicle

TB-only replica of `hb_next` + `have_pending` copied from `rtl/board/arty_a7_ng_native_v1_ab_soc_top.sv` into `tests/xsim` only. Tiny `sent_mask` stepper. Do **not** instantiate `arty_a7_ng_native_v1_ab_soc_top` or MIG. Do not edit `rtl/**`.

## Forbidden

- `graph_late_materialize_00` / Phase 2
- Program board / bitstream
- Edit `rtl/**` / C-FIX / UART RTL fix
- Instantiate `arty_a7_ng_native_v1_ab_soc_top` or MIG
- Raise `core_done` before 51/52; skip `sent_mask`
- Declare `BOARD_PASS` or existence
- Steal Grok R6 lock
