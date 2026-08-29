# E2R-EMB-RG-SWITCH-CXSIM-00 (C-XSIM ST_EMB TOK/POS rg switch) — CLOSEOUT

**Date:** 2026-08-28  
**Worktree:** `D:/Jetking_sem4/SEM_4/arty-a7-online-lm-board`  
**Agent:** `a7-ng-xsim-verify`  
**Authority:** `results/A7-NATIVE-GRAPH/STATUS/E2R_EMB_RG_SWITCH_CXSIM_DISPATCH.md`  
**Prior:** CORE_PRED UART replica; POS miss REGION_DONE nline=128  
**Claim scope:** core-only `SIM_FULL=1` ST_EMB `waddr` set count — **not** existence, **not** `BOARD_PASS`  
**Board program:** **No**  
**Product RTL edited:** **No**  
**C-FIX applied:** **No**  
**Forbidden bypass:** not used (no `soc_top` / MIG; `SIM_FULL=1` stall=0; left ST_EMB before timeout; `graph_late_materialize_00` not implemented)

## Scientific frame

| Field | Value |
|-------|-------|
| OBSERVATION | POS-only miss REGION_DONE nline=128. Silicon 300 s no CORE_DONE. ST_EMB alternates TOK/POS in RTL. |
| UNKNOWN | during one `start_fwd` ST_EMB (`ctx_n=8`), how many TOK vs POS `waddr` sets / region switches? |
| H_CANDIDATE | `OSC_2ND` — ≈ `2*ntok*D` TOK+POS sets (alternate every dim) |
| H_RIVAL | `HOLD_RG` — rg_switches ≤ 2 |
| FALSIFIER | `SIM_FULL=0`; SoC/MIG; C-FIX; stop before leave ST_EMB without timeout class. Not used. |
| UNIT | one `start_fwd` embedding (`ctx_n=8`) |
| CONTROL | ST_EMB sub0 TOK / sub2 POS; REGION_DONE nline law (not executed; stall=0) |
| METRICS | tok_sets, pos_sets, rg_switches, cycles in ST_EMB, leave_emb |

## Vehicle

`tiny_gpt803k_core #(.SIM_FULL(1))` only. Hierarchical peek `st` / `waddr` / `sub`. `ctx_we` with `ctx_n_in=8`, then pulse `start_fwd`. Count sub0→1 as TOK set (`waddr < OFF_POS`) and sub2→3 as POS set (`OFF_POS .. OFF_L0-1`). Count TOK↔POS `waddr` region changes while in ST_EMB. Stop when `st` leaves ST_EMB. Timeout cap 100000 unused. **No** `arty_a7_ng_native_v1_ab_soc_top`. **No** MIG. **No** `rtl/**` edit.

## UNIT snaps

| Snap | cyc | st | waddr | tok | pos | rg_sw |
|------|-----|----|-------|-----|-----|-------|
| CTX_LOAD ntok=8 | — | IDLE | 0 | 0 | 0 | 0 |
| ENTER_EMB / TOK_SET 1 | 1 | ST_EMB | 0 | 1 | 0 | 0 |
| POS_SET 1 | 3 | ST_EMB | 131072 | 1 | 1 | 1 |
| TOK_SET 2 | 6 | ST_EMB | 1 | 2 | 1 | 2 |
| TOK_SET 1024 | 5116 | ST_EMB | 1023 | 1024 | 1023 | — |
| POS_SET 1024 | 5118 | ST_EMB | 132095 | 1024 | 1024 | 2047 |
| LEAVE_EMB | 5120 | ST_LN_S | 132095 | 1024 | 1024 | 2047 |

`w_stall=0` throughout. Timeout unused (`$finish` at 51366 ns).  
rg_switches=2047 = 1024 TOK→POS + 1023 POS→TOK (first TOK set already sat in TOK region `waddr=0`).

## Verdict

| Field | Value |
|-------|-------|
| GATE | **E2R-EMB-RG-SWITCH-CXSIM-00** |
| XSIM | **PASS** (marker `E2R_EMB_RG_SWITCH_CXSIM_00_XSIM_PASS`) |
| CLASS | **OSC_2ND** |
| tok_sets | **1024** |
| pos_sets | **1024** |
| rg_switches | **2047** |
| emb_cycles | **5119** |
| leave_emb | **1** |
| C_FIX | **NONE** |
| H_CANDIDATE | **supported** on this SIM_FULL=1 core vehicle (`tok_sets=pos_sets=1024`) |
| H_RIVAL | **falsified** on this vehicle (`rg_switches=2047 > 2`) |
| EXISTENCE | **not claimed** |
| BOARD_PASS | **not claimed** |
| PROGRAM | **NO** |

n = 1 embedding (`ctx_n=8`). Descriptive class only. Not a cycle farm. No inferential test.

## Evidence quotes (`xsim.log`)

```text
VEHICLE=tiny_gpt803k_core SIM_FULL=1 CORE_ONLY NO_SOC_TOP NO_MIG C_FIX=NONE
LAW ST_EMB_sub0=TOK ST_EMB_sub2=POS OFF_TOK=0 OFF_POS=131072 OFF_L0=147456 D=128
LAW ctx_n=8 UNIT=one_start_fwd_embedding TIMEOUT_CLK=100000
LAW SIM_FULL=1 stall=0 no_DMA_farm
PROGRAM=NO
CTX_LOAD ntok=8 ctx_n_in=8
ENTER_EMB cyc=1 st=1 waddr=0 sub=1 rg=0 w_stall=0
TOK_SET n=1 cyc=1 waddr=0 sub=1 tok_i=0 dim=0
POS_SET n=1 cyc=3 waddr=131072 sub=3 tok_i=0 dim=0
RG_SW n=1 cyc=3 prev_rg=0 now_rg=1 waddr=131072
TOK_SET n=1024 cyc=5116 waddr=1023 sub=1 tok_i=7 dim=127
POS_SET n=1024 cyc=5118 waddr=132095 sub=3 tok_i=7 dim=127
LEAVE_EMB cyc=5120 st=2 waddr=132095 sub=0 emb_cycles=5119
TOK_SETS=1024 POS_SETS=1024 RG_SWITCHES=2047 EMB_CYCLES=5119 LEAVE_EMB=1 TIMEOUT=0 ENTERED=1
XSIM=OSC_2ND
VERDICT_CLASS=OSC_2ND
E2R_EMB_RG_SWITCH_CXSIM_00_XSIM_PASS verdict=OSC_2ND c_fix=NONE
```

Log SHA256 `BEE33A7775A1B6105E5729890F928829B8E2F71BB925A4E7F11EEBA8CE4C687C` (`xsim.log`).  
TB SHA256 `FBAA8C05CD61A7CA02D5FE9589B86706B7B5F6EEB24D64B4E2FA84AC5A2AFDF3`.  
TCL SHA256 `88BF75DBAF124AE16BE5D670624C078EF4533D10167E2C8461B8E2E32BECF9EF`.  
Vivado 2026.1 xvlog / xelab / xsim. License `D:\Xilinx\licenses\vivado_basic.lic`. No `vivado.exe` impl. No board.

## Interpretation (critical)

Controls held: `SIM_FULL=1` (stall=0); core only; no SoC/MIG; UNIT stopped at leave ST_EMB; timeout class unused because leave_emb=1.

On this vehicle ST_EMB sets TOK then POS every `(tok,dim)`: 8×128 = 1024 of each. Region switches every set after the first (2047). H_RIVAL `HOLD_RG` is falsified **on SIM_FULL=1**. That is not silicon DMA. Silicon `SIM_FULL=0` would refill the resident region on each switch; nline×count×MIG ms remains ENGINEERING_INFERENCE only (POS nline=128, TOK nline=1024). XSim ≠ board. Harness ≠ HS-02. **No C-FIX. Existence not claimed.**

## Artifacts

| Path | Role |
|------|------|
| `PREREGISTER.md` | Scientific frame (before UNIT run) |
| `tests/xsim/tb_e2r_emb_rg_switch_cxsim_00.sv` | Canonical TB |
| `tests/xsim/run_e2r_emb_rg_switch_cxsim_00.tcl` | Canonical tcl |
| `tb_e2r_emb_rg_switch_cxsim_00.sv` | Copy used by xvlog cwd |
| `run_e2r_emb_rg_switch_cxsim_00.tcl` | Archived tcl |
| `sources.f` / `run_xsim.cmd` | xvlog / xelab / xsim (no `vivado.exe` impl) |
| `xsim.log` / `xsim_stdout.txt` | Tool + transcript |
| `STEPS.tsv` | UNIT snaps |
