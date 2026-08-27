# E2R-RPATH-IDLE-CXSIM-GRANT0-RINJ-00 (Class C-XSIM grant=0 leftover-R) — CLOSEOUT

**Date:** 2026-08-27  
**Worktree:** `D:/Jetking_sem4/SEM_4/arty-a7-online-lm-board`  
**Agent:** `a7-ng-xsim-verify`  
**Authority:** `results/A7-NATIVE-GRAPH/STATUS/E2R_CXSIM_GRANT0_RINJ_DISPATCH.md`  
**Claim scope:** Grant=0 leftover-R dest-wait occupancy XSim only — **not** existence, **not** `BOARD_PASS`  
**Board program:** **No**  
**Product RTL edited:** **No**  
**C-FIX applied:** **No**  
**Forbidden bypass:** not used (`assign r_path_idle=1` absent; no force of `TILE_DST` / `dst`; grant never raised; no `soc_top` / MIG)

## Scientific frame

| Field | Value |
|-------|-------|
| OBSERVATION | GRANT0 dest starved at `D_DRAIN=3` without R (SHA `E2B2BA9A…`). Silicon UART same-cycle latch: `TILE_DST=4` `GRANT=0` `OWNER=1`. |
| UNKNOWN | With grant held 0, after first `dbg_tile_dst==3`, do 8 TB-injected CDC-slave WDMA R beats make DUT-driven `dbg_tile_dst==4`? |
| H_CANDIDATE | Yes — leftover R completes drain without grant; then classify AND terms (`ONE`/`SET`/`NONE`). |
| H_RIVAL | dest stays 3 after 8 R (`FAIL_NO_DESTWAIT_GRANT0`). |
| FALSIFIER | Force `dst`; raise grant; product RTL; C-FIX; board. Not used. |
| UNIT | One query; grant=0 from reset; inject exactly 8 R after first dest==3. |
| CONTROL | GRANT0 no-inject dest=3 (SHA `E2B2BA9A…`); mux dest=4 only after grant. `SIM_FULL=0`. |
| METRICS | dest before/after inject, grant (stayed 0), owner, four AND terms, idle at dest=4, `R_INJECTED`. |

## Vehicle

Copy of GRANT0 TB. `a7ng_native_v1_ab_core` `#(.SIM_FULL(1'b0))`, `do_lm=1`. **TB-only delta:** after first `dbg_tile_dst==3`, 8 combinational-legal R beats on CDC slave `dma_r_valid` toward the tile. Grant register stays 0. DUT-driven `dbg_tile_dst` only.

Idle law (frozen DUT):  
`r_path_idle = !r_drain_hold && (fifo_cnt==0) && !m_axi_rvalid && (tr_cnt==0)`

## UNIT occupancy

| Metric | Value |
|--------|-------|
| dest before inject | **3** (`D_DRAIN`) |
| `R_INJECTED` | **8** (`rinj_done=1`; grant still 0) |
| dest at inject-complete (`AFTER_RINJ`) | **3** (CDC crossing not yet drained) |
| dest at first dest-wait | **4** (`D_WAITDONE`; `dbg_tile_dst`) |
| `wdma_owner_grant` | **0** throughout (`GRANT_STAYED_0=1`) |
| `wdma_owner` / `wdma_owner_ui` | 1 / 0 |
| four AND terms at dest=4 | 0 / 0 / 0 / 0 |
| `r_path_idle` at dest=4 | **1** |
| TB WDMA `w_st` | `W_WAITOWN` (1) — stub never took R; inject bypassed grant/mux |

## Verdict

| Field | Value |
|-------|-------|
| XSIM | **PASS** (`E2R_RPATH_IDLE_CXSIM_GRANT0_RINJ_00_XSIM_PASS`) |
| VERDICT_CLASS | **NONE** |
| WIRE_THAT_HOLDS_IDLE_0 | **NONE** |
| C_FIX | **NONE** |
| DEST | **4** |
| GRANT_STAYED_0 | **1** |
| R_INJECTED | **8** |
| H_CANDIDATE | **supported** on this vehicle: leftover R without grant moved dest 3→4 |
| H_RIVAL | **falsified** for dest≠4 after 8 R |
| EXISTENCE | **not claimed** |
| BOARD_PASS | **not claimed** |

## Evidence quotes (`xsim.log`)

```text
VEHICLE=a7ng_native_v1_ab_core SIM_FULL=0 do_lm=1 CDC+B1_GRANT0+MUX ungated_cdc_rvalid SHARED_STUB_WDMA RINJ8_AFTER_DST3
PROBE t=26760000 phase=WDMA_GO dst=0 grant=0 own_ui=0 go=1 busy=0
PROBE t=27640000 phase=DEST3_BEFORE_INJECT dst=3 grant=0 busy=1 rready=1 rinj_acc=8 rinj_done=1
DEST_BEFORE_INJECT=3
GRANT_AT_INJECT=0
R_INJECTED=8 rinj_done=1
PROBE t=30200000 phase=FIRST_DESTWAIT dst=4 drain=0 fifo=0 c_rvalid=0 tr=0 idle=1 own=1 grant=0
GRANT_ROSE_BEFORE_DESTWAIT=0 GRANT_STAYED_0=1
DEST=4
R_INJECTED=8
AND_MASK drain,fifo,rvalid,tr = 0000 n_hot=0
WIRE_THAT_HOLDS_IDLE_0=NONE
VERDICT_CLASS=NONE
C_FIX=NONE
BOARD_PASS=not_claimed
XSIM=PASS
E2R_RPATH_IDLE_CXSIM_GRANT0_RINJ_00_XSIM_PASS verdict=NONE wire=NONE c_fix=NONE idle=1 n_hot=0 dst=4 grant_stayed_0=1 rinj=8
```

Log SHA256 `3F169C1CB461116F5595DD7499F1FE71F6085F26E63E419AADB38DC47151767D` (`xsim.log`).  
TB SHA256 `0501B23ACB2F98EF1FC55F9A1AD6FE0DE857D975F6C298FD35F8F8CF8CB94D16`.  
Read-CDC SHA256 `AF3EDB1ACD9DF1EA1B52C5B7E06F5C0799AB8E65813A74CB5037FBB18C032B45` (unchanged vs GRANT0).  
Vivado 2026.1 xvlog / xelab (`-L xpm` + `glbl`) / xsim. No `vivado.exe` impl. No board.

## Interpretation (critical)

H_CANDIDATE is **supported**: with grant held 0, eight TB R beats on the CDC slave path were sufficient for DUT-driven dest to leave `D_DRAIN=3` and occupy `D_WAITDONE=4`. GRANT0 no-inject control stayed at dest=3. That is one query, one unknown.

AND terms at first dest=4 are all 0 (`idle=1`, class `NONE`). This dest=4∧grant=0 occupancy is **not** leftover SOA R-path idle=0. Silicon `TILE_DST=4∧GRANT=0` is **mechanistically possible** via leftover WDMA R without grant on this vehicle; silicon `RPATH_IDLE=0` is **not** reproduced here.

XSim ≠ board. Stub AXI ≠ MIG. TB inject ≠ silicon leftover R. **No C-FIX.**

## Artifacts

| Path | Role |
|------|------|
| `PREREGISTER.md` | Scientific frame (before UNIT run) |
| `tests/xsim/tb_e2r_rpath_idle_cxsim_grant0_rinj_00.sv` | Canonical TB |
| `tests/xsim/run_e2r_rpath_idle_cxsim_grant0_rinj_00.tcl` | Canonical tcl |
| `tb_e2r_rpath_idle_cxsim_grant0_rinj_00.sv` | Copy used by xvlog cwd |
| `run_e2r_rpath_idle_cxsim_grant0_rinj_00.tcl` | Archived tcl |
| `sources.f` / `run_xsim.cmd` | xvlog / xelab / xsim (no `vivado.exe` impl) |
| `xsim.log` / `xsim_stdout.txt` | Tool + transcript |
| `probe_table.csv` | Four-wire + dest + rinj snapshots |
