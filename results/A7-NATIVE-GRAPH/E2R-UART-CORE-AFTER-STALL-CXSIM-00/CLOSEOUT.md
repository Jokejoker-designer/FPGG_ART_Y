# E2R-UART-CORE-AFTER-STALL-CXSIM-00 (C-XSIM hb_next after W_STALL) — CLOSEOUT

**Date:** 2026-08-28  
**Worktree:** `D:/Jetking_sem4/SEM_4/arty-a7-online-lm-board`  
**Agent:** `a7-ng-xsim-verify`  
**Authority:** `results/A7-NATIVE-GRAPH/STATUS/E2R_UART_CORE_AFTER_STALL_CXSIM_DISPATCH.md`  
**Prior:** `results/A7-NATIVE-GRAPH/E2R-UART-SKEW-CXSIM-00/` (replica, no SoC instantiate)  
**Claim scope:** TB-only `hb_next` + `have_pending` sent_mask stepper — **not** existence, **not** `BOARD_PASS`  
**Board program:** **No**  
**Product RTL edited:** **No**  
**C-FIX applied:** **No**  
**Forbidden bypass:** not used (no `soc_top` / MIG; `core_done` raised only after 51/52 sent; `sent_mask` used; ATOM 69/70 held 0; `graph_late_materialize_00` not implemented)

## Scientific frame

| Field | Value |
|-------|-------|
| OBSERVATION | REARM UART ends `W_STALL` `PHASE=01`. `hb_next` can return 54/55 after mask 51/52. `have_pending` includes `core_done_100` / `pred_ready`. UART-SKEW showed print-time leftover. |
| UNKNOWN | after 51/52 are sent, if `core_done` then `pred_ready` rise later, does `nxt_sel` become 54 then 55? |
| H_CANDIDATE | `PRINT_DEAD` — `core_done=1` but `nxt_sel` never 54/55 |
| H_RIVAL | `CORE_PRED` — 54 then 55 after stall/phase sent |
| FALSIFIER | raise `core_done` before 51/52; skip `sent_mask`; instantiate SoC/MIG; C-FIX. Not used. |
| UNIT | one print sequence (stall → phase → late `core_done` → pred) |
| CONTROL | UART-SKEW replica; SoC order 51,52,53,54,55; other `*_ok`=0; ATOM 69/70=0; BOOT `mask[0]` sent first |
| METRICS | `nxt_sel` after each step; `have_pending`; `sent_mask` bits 51/52/54/55 |

## Vehicle

TB-only replica of `hb_next` + `have_pending` copied from `arty_a7_ng_native_v1_ab_soc_top.sv`. Tiny `sent_mask` stepper. `pred_ready` driven as the SoC `pred_ok` argument; `bind_100` held 0 so slot 35 does not win. **No** `arty_a7_ng_native_v1_ab_soc_top` instance. **No** MIG. **No** `rtl/**` edit.

## UNIT steps

| Step | Drive | nxt_sel | have_pending | mask 51/52/54/55 |
|------|-------|---------|--------------|------------------|
| SETUP_PRE | mask empty | **0** (BOOT) | 1 | 0/0/0/0 |
| A | stall=1 phase=1 core=0 pred=0 | **51** | 1 | 0/0/0/0 |
| B | after send 51 | **52** | 1 | 1/0/0/0 |
| C | raise `core_done` | **54** | 1 | 1/1/0/0 |
| D | raise `pred_ready` | **55** | 1 | 1/1/1/0 |

`mask[55]` stays 0 because step D is observe-only (no send after 55).

## Verdict

| Field | Value |
|-------|-------|
| GATE | **E2R-UART-CORE-AFTER-STALL-CXSIM-00** |
| XSIM | **PASS** (marker `E2R_UART_CORE_AFTER_STALL_CXSIM_00_XSIM_PASS`) |
| CLASS | **CORE_PRED** |
| sel_after_C | **54** |
| sel_after_D | **55** |
| C_FIX | **NONE** |
| H_CANDIDATE | **falsified** on this replica (`core_done=1` produced 54 then 55) |
| H_RIVAL | **supported** on this replica |
| EXISTENCE | **not claimed** |
| BOARD_PASS | **not claimed** |
| PROGRAM | **NO** |

n = 1 print sequence (one UNIT). Descriptive class only. Not a cycle farm. No inferential test.

## Evidence quotes (`xsim.log`)

```text
VEHICLE=tb_hb_next_have_pending_sent_mask_stepper NO_SOC_TOP NO_MIG C_FIX=NONE
LAW hb_next_order=51,52,53,54,55_after_atom69_70
LAW other_ok=0 ATOM69_70=0 bind_ok=0
LAW core_done_raised_after_mask_51_52
LAW pred_ready_driven_as_pred_ok bind_100_held_0
PROGRAM=NO
STEP=A nxt_sel=51 have_pending=1 mask51=0 mask52=0 mask54=0 mask55=0 w_stall=1 phase=1 core_done=0 pred_ready=0 atom0=0 atom1=0 giveup=0 bind=0
STEP=B nxt_sel=52 have_pending=1 mask51=1 mask52=0 mask54=0 mask55=0 w_stall=1 phase=1 core_done=0 pred_ready=0 atom0=0 atom1=0 giveup=0 bind=0
STEP=C nxt_sel=54 have_pending=1 mask51=1 mask52=1 mask54=0 mask55=0 w_stall=1 phase=1 core_done=1 pred_ready=0 atom0=0 atom1=0 giveup=0 bind=0
STEP=D nxt_sel=55 have_pending=1 mask51=1 mask52=1 mask54=1 mask55=0 w_stall=1 phase=1 core_done=1 pred_ready=1 atom0=0 atom1=0 giveup=0 bind=0
SEL_SETUP=0 SEL_A=51 SEL_B=52 SEL_C=54 SEL_D=55
XSIM=CORE_PRED
VERDICT_CLASS=CORE_PRED
E2R_UART_CORE_AFTER_STALL_CXSIM_00_XSIM_PASS verdict=CORE_PRED c_fix=NONE
```

Log SHA256 `7F327F091D1889866087B0C4FE2BECB7CA57E1876A1B57BB6B9770BE7D77C86A` (`xsim.log`).  
TB SHA256 `B183AC0254EA9F2FD05E18EE1DFEB06185429C339FFDEA7082C525C2256C02EA`.  
TCL SHA256 `2754CD8AF1E5C123FBAA95B5A835097715EE058D2CA5913B66FB96DC261C71AE`.  
`soc_top` SHA256 `8298376EA060D028303A7148591D99416D8F7C56D116E011E7A32543BC3A2CF0` (read-only; not instantiated).  
Vivado 2026.1 xvlog / xelab / xsim. License `D:\Xilinx\licenses\vivado_basic.lic`. No `vivado.exe` impl. No board.

## Interpretation (critical)

Controls held: other `*_ok` = 0; ATOM 69/70 = 0; `bind_100` = 0; BOOT `mask[0]` sent before stall (else `hb_next` always returns 0). `core_done` was not raised until after 51 and 52 were sent. `sent_mask` was used.

On this copied priority function, after 51/52 are masked, a later `core_done_100=1` yields `nxt_sel=54`, and a later `pred_ready=1` yields `nxt_sel=55`. `PRINT_DEAD` is falsified **on the replica**. That is not silicon UART, not SoC time, and not proof REARM would have printed 54/55 — REARM ended `W_STALL`/`PHASE=01` without `CORE_DONE`. XSim ≠ board. Harness replica ≠ UART capture. **No C-FIX. No UART RTL fix authorized.**

## Artifacts

| Path | Role |
|------|------|
| `PREREGISTER.md` | Scientific frame (before UNIT run) |
| `tests/xsim/tb_e2r_uart_core_after_stall_cxsim_00.sv` | Canonical TB |
| `tests/xsim/run_e2r_uart_core_after_stall_cxsim_00.tcl` | Canonical tcl |
| `tb_e2r_uart_core_after_stall_cxsim_00.sv` | Copy used by xvlog cwd |
| `run_e2r_uart_core_after_stall_cxsim_00.tcl` | Archived tcl |
| `sources.f` / `run_xsim.cmd` | xvlog / xelab / xsim (no `vivado.exe` impl) |
| `xsim.log` / `xsim_stdout.txt` | Tool + transcript |
| `STEPS.tsv` | Five-row nxt_sel / mask / drive |
