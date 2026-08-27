# E2R-RPATH-IDLE-CXSIM-GRANT0-RMUX-00 (Class C-XSIM grant=0 mux leftover-R) — CLOSEOUT

**Date:** 2026-08-27  
**Worktree:** `D:/Jetking_sem4/SEM_4/arty-a7-online-lm-board`  
**Agent:** `a7-ng-xsim-verify`  
**Authority:** `results/A7-NATIVE-GRAPH/STATUS/E2R_CXSIM_GRANT0_RMUX_DISPATCH.md`  
**Claim scope:** Grant=0 mux leftover-R dest-wait occupancy XSim only — **not** existence, **not** `BOARD_PASS`  
**Board program:** **No**  
**Product RTL edited:** **No**  
**C-FIX applied:** **No**  
**Forbidden bypass:** not used (`assign r_path_idle=1` absent; no force of `TILE_DST` / `dst`; grant never raised; no CDC-slave `dma_r_valid` inject; no `soc_top` / MIG)

## Scientific frame

| Field | Value |
|-------|-------|
| OBSERVATION | Tile-side leftover R can occupy dest=4 with grant=0 and idle=1 (RINJ SHA `3F169C1C…`). Silicon leftover is idle=0. Mux leftover (fifo + `c_rvalid`) existed only after grant. |
| UNKNOWN | With grant held 0 and `wdma_owner_ui=0`, after first `dbg_tile_dst==3`, do 8 leftover beats on the shared stub R (mux `rvalid` / ungated `cdc_rvalid=rvalid`) make DUT-driven `dbg_tile_dst==4`? If dest=4, classify four idle AND terms. |
| H_CANDIDATE | Mux leftover R without grant reaches dest=4 and holds idle=0 (silicon triple occupiable; then `ONE`/`SET`/`NONE`). |
| H_RIVAL | dest stays 3 (`FAIL_NO_DESTWAIT_GRANT0`) — mux leftover does not complete drain without grant. |
| FALSIFIER | Force `dst`; raise grant; CDC-slave `dma_r_valid` inject (RINJ); product RTL; C-FIX; board. Not used. |
| UNIT | One query; grant=0 from reset; inject exactly 8 leftover beats on shared stub R after first dest==3. |
| CONTROL | RINJ dest=4 idle=1 via CDC-slave (SHA `3F169C1C…`); GRANT0 no-inject dest=3; mux dest=4 only after grant. `SIM_FULL=0`. |
| METRICS | dest before/after inject, grant stayed 0, `own_ui`, four AND terms, idle if dest=4, `R_INJECTED`, stub/`cdc_rvalid`. |

## Vehicle

Copy of RINJ/GRANT0 TB. `a7ng_native_v1_ab_core` `#(.SIM_FULL(1'b0))`, `do_lm=1`. **TB-only delta:** after first `dbg_tile_dst==3`, 8 combinational-legal leftover beats on the shared stub R into the mux (ungated `cdc_rvalid=rvalid`). Grant register stays 0. `dma_r_valid` stays the legal WDMA `W_R` path only. DUT-driven `dbg_tile_dst` only.

Idle law (frozen DUT):  
`r_path_idle = !r_drain_hold && (fifo_cnt==0) && !m_axi_rvalid && (tr_cnt==0)`

## UNIT occupancy

| Metric | Value |
|--------|-------|
| dest before inject | **3** (`D_DRAIN`) |
| `R_INJECTED` | **8** (`rmux_done=1`; grant still 0) |
| `dma_r_valid` during leftover | **0** (not RINJ) |
| dest at inject-complete (`AFTER_RMUX`) | **3** (CDC leftover not yet at dest-wait) |
| dest after post-inject window | **3** (`LIMIT_NO_DESTWAIT`; `max_dst=3`) |
| `wdma_owner_grant` | **0** throughout (`GRANT_STAYED_0=1`) |
| `wdma_owner` / `wdma_owner_ui` | 1 / 0 |
| dest=4 AND terms | **not taken** (dest never 4) |
| Live leftover at dest=3 (exploratory) | fifo=4, `c_rvalid=1`, drain=0, tr=0, **idle=0** |
| TB WDMA `w_st` | `W_WAITOWN` (1) — stub never took R |

## Verdict

| Field | Value |
|-------|-------|
| XSIM | **FAIL_NO_DESTWAIT_GRANT0** (marker `E2R_RPATH_IDLE_CXSIM_GRANT0_RMUX_00_XSIM_PASS` **not** issued) |
| VERDICT_CLASS | **FAIL_NO_DESTWAIT_GRANT0** |
| WIRE_THAT_HOLDS_IDLE_0 | **NONE** (no dest=4 classification) |
| C_FIX | **NONE** |
| DEST | **3** |
| GRANT_STAYED_0 | **1** |
| R_INJECTED | **8** |
| OWN_UI | **0** |
| H_CANDIDATE | **not supported** on this vehicle: mux leftover R without grant did **not** move dest 3→4 |
| H_RIVAL | **supported** for dest≠4 after 8 mux leftover R |
| EXISTENCE | **not claimed** |
| BOARD_PASS | **not claimed** |

## Evidence quotes (`xsim.log`)

```text
VEHICLE=a7ng_native_v1_ab_core SIM_FULL=0 do_lm=1 CDC+B1_GRANT0+MUX ungated_cdc_rvalid SHARED_STUB_WDMA RMUX8_AFTER_DST3
PROBE t=26760000 phase=WDMA_GO dst=0 grant=0 own_ui=0 go=1 busy=0
PROBE t=27640000 phase=DEST3_BEFORE_INJECT dst=3 grant=0 busy=1 rinj_acc=8 rmux_done=1 dma_rv=0
DEST_BEFORE_INJECT=3
GRANT_AT_INJECT=0
R_INJECTED=8 rmux_done=1 dma_rv_during_rmux=0
PROBE t=67640000 phase=POST_INJ_HB dst=3 drain=0 fifo=4 c_rvalid=1 tr=0 idle=0 own=1 grant=0 own_ui=0
PROBE t=1627640000 phase=LIMIT_NO_DESTWAIT dst=3 drain=0 fifo=4 c_rvalid=1 tr=0 idle=0 grant=0 own_ui=0
GRANT_ROSE_BEFORE_DESTWAIT=0 GRANT_STAYED_0=1
DEST=3
R_INJECTED=8
OWN_UI=0
DMA_RV_DURING_RMUX=0
VERDICT_CLASS=FAIL_NO_DESTWAIT_GRANT0
C_FIX=NONE
BOARD_PASS=not_claimed
XSIM=FAIL_NO_DESTWAIT_GRANT0
E2R_RPATH_IDLE_CXSIM_GRANT0_RMUX_00_FAIL_NO_DESTWAIT_GRANT0 dst=3 max_dst=3 grant=0 grant_stayed_0=1 own_ui=0 rinj=8 dma_rv_during_rmux=0
```

Log SHA256 `0452BDD20F8C6959AB8DB546C00EDA2CFDA0C57381A9B44B9CE03A18714B7CBE` (`xsim.log`).  
TB SHA256 `C9E322B421AD8322D8E3CDB966D608C0B7D309E0242DFEA122959E2A3D1C99CA`.  
Read-CDC SHA256 `AF3EDB1ACD9DF1EA1B52C5B7E06F5C0799AB8E65813A74CB5037FBB18C032B45` (unchanged vs RINJ/GRANT0).  
Vivado 2026.1 xvlog / xelab (`-L xpm` + `glbl`) / xsim. No `vivado.exe` impl. No board.

## Interpretation (critical)

H_RIVAL is **supported** for the preregistered dest unknown: with grant held 0, eight leftover beats on the shared mux R path (`cdc_rvalid=rvalid`) did **not** move DUT-driven dest off `D_DRAIN=3`. RINJ control (CDC-slave `dma_r_valid`, SHA `3F169C1C…`) did move dest to 4. That is one query, one unknown.

AND_MASK `0000` at `$finish` is **not** a dest=4 `NONE` class — dest-wait snap was never taken. Do not treat it as idle classification at dest=4.

**Exploratory (not UNIT):** after leftover crossed AXI-read CDC, live occupancy at dest=3 was fifo=4 and `c_rvalid=1` with idle=0. Mux leftover without grant can occupy the leftover pair that the granted MUX bag saw at dest=4, but dest stays 3. Silicon `TILE_DST=4∧GRANT=0∧RPATH_IDLE=0` is **not** reproduced here.

XSim ≠ board. Stub AXI ≠ MIG. TB leftover ≠ silicon leftover R. **No C-FIX.**

## Artifacts

| Path | Role |
|------|------|
| `PREREGISTER.md` | Scientific frame (before UNIT run) |
| `tests/xsim/tb_e2r_rpath_idle_cxsim_grant0_rmux_00.sv` | Canonical TB |
| `tests/xsim/run_e2r_rpath_idle_cxsim_grant0_rmux_00.tcl` | Canonical tcl |
| `tb_e2r_rpath_idle_cxsim_grant0_rmux_00.sv` | Copy used by xvlog cwd |
| `run_e2r_rpath_idle_cxsim_grant0_rmux_00.tcl` | Archived tcl |
| `sources.f` / `run_xsim.cmd` | xvlog / xelab / xsim (no `vivado.exe` impl) |
| `xsim.log` / `xsim_stdout.txt` | Tool + transcript |
| `probe_table.csv` | Four-wire + dest + leftover snapshots |
