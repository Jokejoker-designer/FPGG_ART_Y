# E2R-FWD-RG-SWITCH-CXSIM-00 (C-XSIM start_fwd→done rg sets) — CLOSEOUT

**Date:** 2026-08-28  
**Worktree:** `D:/Jetking_sem4/SEM_4/arty-a7-online-lm-board`  
**Agent:** `a7-ng-xsim-verify`  
**Authority:** `results/A7-NATIVE-GRAPH/STATUS/E2R_FWD_RG_SWITCH_CXSIM_DISPATCH.md`  
**Prior:** E2R-EMB-RG-SWITCH-CXSIM-00 CLASS=OSC_2ND tok=1024 pos=1024 leave_emb=1  
**Claim scope:** core-only `SIM_FULL=1` start_fwd→done `waddr` set count — **not** existence, **not** `BOARD_PASS`  
**Board program:** **No**  
**Product RTL edited:** **No**  
**C-FIX applied:** **No**  
**Forbidden bypass:** not used (no `soc_top` / MIG; `SIM_FULL=1` stall=0; did not stop at leave ST_EMB; `graph_late_materialize_00` not implemented)

## Scientific frame

| Field | Value |
|-------|-------|
| OBSERVATION | ST_EMB OSC_2ND 1024 TOK + 1024 POS. Layers after EMB use `waddr`. Silicon 300 s no CORE_DONE. |
| UNKNOWN | from `start_fwd` to core `done`, how many TOK / POS / other-rg `waddr` sets? |
| H_CANDIDATE | `FWD_HEAVY` — after-EMB sets ≫ 0; total ≫ 2048 |
| H_RIVAL | `EMB_DOM` — after leave_emb, few more rg sets; total ≈ 2048 |
| FALSIFIER | `SIM_FULL=0`; stop at leave ST_EMB; SoC/MIG; C-FIX. Not used. |
| UNIT | one `start_fwd` until `done` (`ctx_n=8`) |
| CONTROL | OSC_2ND tok=1024 pos=1024 leave_emb=1 |
| METRICS | tok_sets, pos_sets, other_sets, rg_switches, done, cycles |

## Vehicle

`tiny_gpt803k_core #(.SIM_FULL(1))` only. Hierarchical peek `st` / `waddr` / `sub`. `ctx_we` with `ctx_n_in=8`, then pulse `start_fwd`. ST_EMB set law unchanged (sub0→1 TOK, sub2→3 POS). After leave ST_EMB, each `waddr` change is a set classified by `OFF_TOK` / `OFF_POS` / `OFF_L0`. Watch until `done==1` or timeout **40000000** clk (preregistered minimum 5000000). **No** `arty_a7_ng_native_v1_ab_soc_top`. **No** MIG. **No** `rtl/**` edit.

## UNIT snaps

| Snap | cyc | st | waddr | tok | pos | other | after |
|------|-----|----|-------|-----|-----|-------|-------|
| CTX_LOAD ntok=8 | — | IDLE | 0 | 0 | 0 | 0 | 0 |
| ENTER_EMB / TOK_SET 1 | 1 | ST_EMB | 0 | 1 | 0 | 0 | 0 |
| POS_SET 1024 / CONTROL | 5118 | ST_EMB | 132095 | 1024 | 1024 | 0 | 0 |
| LEAVE_EMB | 5120 | ST_LN_S | 132095 | 1024 | 1024 | 0 | 0 |
| AFTER_SET 1 (OFF_L0) | 62444 | ST_MV | 147456 | 1024 | 1024 | 1 | 1 |
| HEAD enter | 17676844 | ST_MV | 671744 | 1024 | 1024 | — | — |
| CORE_DONE | 18205209 | done=1 | 802815 | 1024 | 1024 | 4325376 | 4325376 |

`w_stall=0` throughout. Timeout unused (`$finish` at 182052256 ns; xsim elapsed 31 s).  
other_sets=4325376 = `4 layers × 8 tok × (4×D×D + FF×D + D×FF) + V×D` = `32×131072 + 131072`.  
after_emb tok/pos = 0. rg_switches=2048 = 2047 EMB TOK↔POS + 1 POS→OTHER.

## Verdict

| Field | Value |
|-------|-------|
| GATE | **E2R-FWD-RG-SWITCH-CXSIM-00** |
| XSIM | **PASS** (marker `E2R_FWD_RG_SWITCH_CXSIM_00_XSIM_PASS`) |
| CLASS | **FWD_HEAVY** |
| tok_sets | **1024** |
| pos_sets | **1024** |
| other_sets | **4325376** |
| after_emb_sets | **4325376** |
| rg_switches | **2048** |
| cycles | **18205209** |
| done | **1** |
| leave_emb | **1** |
| C_FIX | **NONE** |
| H_CANDIDATE | **supported** (`other_sets=4325376>64`, `total=4327424>2112`) |
| H_RIVAL | **falsified** (`after_emb_sets=4325376>64`) |
| EXISTENCE | **not claimed** |
| BOARD_PASS | **not claimed** |
| PROGRAM | **NO** |

n = 1 forward (`ctx_n=8`). Descriptive class only. Not a cycle farm. No inferential test. `pred=0` is uninitialized SIM_FULL BRAM, not an existence token.

## Evidence quotes (`xsim.log`)

```text
VEHICLE=tiny_gpt803k_core SIM_FULL=1 CORE_ONLY NO_SOC_TOP NO_MIG C_FIX=NONE
LAW ctx_n=8 UNIT=one_start_fwd_until_done TIMEOUT_CLK=40000000
LAW SIM_FULL=1 stall=0 no_DMA_farm STOP=done_or_timeout NOT_leave_ST_EMB
PROGRAM=NO
LEAVE_EMB cyc=5120 st=2 waddr=132095 sub=0 emb_cycles=5119 tok=1024 pos=1024 other=0
AFTER_SET n=1 cyc=62444 st=6 waddr=147456 rg=2 tok=1024 pos=1024 other=1 ly=0
CORE_DONE cyc=18205209 st=0 pred=0 waddr=802815 tok=1024 pos=1024 other=4325376 after=4325376
TOK_SETS=1024 POS_SETS=1024 OTHER_SETS=4325376 TOTAL_SETS=4327424 RG_SWITCHES=2048
AFTER_EMB_TOK=0 AFTER_EMB_POS=0 AFTER_EMB_OTHER=4325376 AFTER_EMB_SETS=4325376
EMB_CYCLES=5119 CYCLES=18205209 LEAVE_EMB=1 DONE=1 TIMEOUT=0 ENTERED=1
XSIM=FWD_HEAVY
VERDICT_CLASS=FWD_HEAVY
E2R_FWD_RG_SWITCH_CXSIM_00_XSIM_PASS verdict=FWD_HEAVY c_fix=NONE
```

Log SHA256 `AEA9C0F8F5836C0DD40F97993C11BF621BB1FF389329B619321443FA854B68D0` (`xsim.log`).  
TB SHA256 `8F9819415031E2C6CD6DE464BE2FE4F5AA6AF35B4646FD033FED85BC0BAE2B20`.  
TCL SHA256 `13F76E2A822E5F020C995C4BFBBE49AB169C1BF0168CA23BDD041B9122B23627`.  
Vivado 2026.1 xvlog / xelab / xsim. License `D:\Xilinx\licenses\vivado_basic.lic`. No `vivado.exe` impl. No board.

## Interpretation (critical)

Controls held: `SIM_FULL=1` (stall=0); core only; no SoC/MIG; UNIT ran past leave ST_EMB to `done=1`; timeout class unused; EMB CONTROL reproduced (1024/1024/leave=1).

On this vehicle the forward after EMB is layer/head `waddr` traffic in the OTHER window (`>= OFF_L0`): 4.325e6 sets, zero extra TOK/POS. H_RIVAL `EMB_DOM` is falsified **on SIM_FULL=1**. That is not silicon DMA. Mapping other_sets × nline × MIG ms remains ENGINEERING_INFERENCE only. XSim ≠ board. Harness ≠ HS-02. **No C-FIX. Existence not claimed.**

## Artifacts

| Path | Role |
|------|------|
| `PREREGISTER.md` | Scientific frame (before UNIT run) |
| `tests/xsim/tb_e2r_fwd_rg_switch_cxsim_00.sv` | Canonical TB |
| `tests/xsim/run_e2r_fwd_rg_switch_cxsim_00.tcl` | Canonical tcl |
| `tb_e2r_fwd_rg_switch_cxsim_00.sv` | Copy used by xvlog cwd |
| `run_e2r_fwd_rg_switch_cxsim_00.tcl` | Archived tcl |
| `sources.f` / `run_xsim.cmd` | xvlog / xelab / xsim (no `vivado.exe` impl) |
| `xsim.log` / `xsim_stdout.txt` | Tool + transcript |
| `STEPS.tsv` | UNIT snaps |
