# E2R-UART-CORE-AFTER-STALL-CXSIM-00 — GO (no board)

**Agent:** `a7-ng-xsim-verify`  
**Workspace:** `D:/Jetking_sem4/SEM_4/arty-a7-online-lm-board`  
**Results:** `results/A7-NATIVE-GRAPH/E2R-UART-CORE-AFTER-STALL-CXSIM-00/`  
**PROGRAM=NO. No RTL edit. No C-FIX.**

Prior [REGION_DONE](8276b8cf-e79d-498d-b46e-9b0afd494f4b) / audit [CLEAN](0caf023d-3846-45c1-8a59-c2787058ec6f): one POS region `nline=128` `stall=0` on stub. Silicon REARM 300 s ended `W_STALL`/`PHASE=01` with no `CORE_DONE`. `hb_next` places 54/55 **after** 51/52. `have_pending` includes `core_done_100` / `pred_ready`. UART-SKEW already showed print-time leftover; do not treat the assign as classified.

Do **not** instantiate `arty_a7_ng_native_v1_ab_soc_top` or MIG. Replica `hb_next` + `have_pending` + a tiny sent_mask/print stepper (same style as UART-SKEW). Copy functions from SoC; do not edit `rtl/**`.

## Scientific frame

| Field | Value |
|-------|-------|
| OBSERVATION | REARM file ends `W_STALL` `PHASE=01`. `hb_next` can return 54/55 after mask 51/52. LONG listen SILENT (one-shot). |
| UNKNOWN | after 51/52 are sent, if `core_done` then `pred_ready` rise later, does `nxt_sel` become 54 then 55? |
| H_CANDIDATE | `PRINT_DEAD` — `core_done=1` but `nxt_sel` never 54/55 |
| H_RIVAL | `CORE_PRED` — 54 then 55 after stall/phase sent |
| FALSIFIER | raise core_done before 51/52; skip sent_mask; instantiate SoC/MIG; C-FIX |
| UNIT | one print sequence (stall → phase → late core_done → pred) |
| CONTROL | UART-SKEW replica style; SoC `hb_next` order 51,52,53,54,55 |
| METRICS | nxt_sel after each step, have_pending, sent_mask bits 51/52/54/55 |

**One change vs a blank replica:** drive 51 then 52 first; **then** raise `core_done_100`; **then** `pred_ready`. Do not raise them in the same step as stall.

| Class | Meaning |
|-------|---------|
| `CORE_PRED` | `nxt_sel=54` after stall/phase sent, then `nxt_sel=55` after pred_ready |
| `CORE_ONLY` | 54 yes, 55 never |
| `PRINT_DEAD` | core_done=1, never 54/55 |
| `NO_STALL` | never selected 51/52 |

Marker `E2R_UART_CORE_AFTER_STALL_CXSIM_00_XSIM_PASS` if classified. Existence not claimed. Does not authorize program or a UART RTL fix.
