# E2R-RPATH-IDLE-CXSIM-GRANT0-00 (Class C-XSIM grant=0) — CLOSEOUT

**Date:** 2026-08-27  
**Worktree:** `D:/Jetking_sem4/SEM_4/arty-a7-online-lm-board`  
**Agent:** `a7-ng-xsim-verify`  
**Authority:** `results/A7-NATIVE-GRAPH/STATUS/E2R_CXSIM_GRANT0_DISPATCH.md`  
**Claim scope:** Grant=0 dest-wait occupancy XSim only — **not** existence, **not** `BOARD_PASS`  
**Board program:** **No**  
**Product RTL edited:** **No**  
**C-FIX applied:** **No**  
**Forbidden bypass:** not used (`assign r_path_idle=1` absent; no force of `TILE_DST` / `dst`; no `soc_top` / MIG)

## Scientific frame

| Field | Value |
|-------|-------|
| OBSERVATION | Silicon dest-wait `TILE_DST=4` `GRANT=0` `RPATH_IDLE=0`. Mux XSim leftover idle=0 only after grant (`GRANT_ROSE=1`, SHA `1596C402…`). |
| UNKNOWN | On the mux vehicle, with TB holding grant=0 from reset, does DUT-driven `dbg_tile_dst` reach 4? |
| H_CANDIDATE | dest-wait occupies with grant=0 (`dst=4`); then classify AND terms (`ONE`/`SET`/`NONE`). |
| H_RIVAL | Dest stays ≠4 (`FAIL_NO_DESTWAIT_GRANT0`) — silicon `TILE_DST=4∧GRANT=0` is not reproduced. |
| FALSIFIER | Force `dst`; product RTL; C-FIX; `soc_top`+MIG only. Not used. |
| UNIT | One query, grant held 0 from reset. Timeout without `dst=4` (`snap_cyc=250050`). Not a cycle farm. |
| CONTROL | Mux dest-wait grant=1 (SHA `1596C402…`); silicon `GRANT=0`. `SIM_FULL=0`. Dual clocks 12.5/100 MHz. |
| METRICS | `tile_dst`, grant (stayed 0), owner, owner_ui, four AND terms, idle, dma go/busy. |

## Vehicle

`a7ng_native_v1_ab_core` `#(.SIM_FULL(1'b0))`, `do_lm=1`. Copy of mux bag. **TB-only delta:** B1 grant register stays 0 (never take `r_path_idle` rise). Same shared stub + AXI-read CDC + ungated `cdc_rvalid=rvalid`. DUT-driven `dbg_tile_dst` only.

Idle law (frozen DUT):  
`r_path_idle = !r_drain_hold && (fifo_cnt==0) && !m_axi_rvalid && (tr_cnt==0)`

## Timeout occupancy (UNIT — dest never 4)

| Metric | Value |
|--------|-------|
| `dbg_tile_dst` live / max | **3** / **3** (`D_DRAIN`; `D_WAITDONE=4` never occupied) |
| `wdma_owner_grant` | **0** throughout (`GRANT_STAYED_0=1`) |
| `wdma_owner` | 1 after first miss |
| `wdma_owner_ui` | 0 |
| four AND terms | 0 / 0 / 0 / 0 (live `LIMIT` probe) |
| `r_path_idle` | **1** at timeout (live) |
| `wdma_go` / `wdma_busy` | pulse then **0** / **1** |
| TB WDMA `w_st` / `rleft` | `W_WAITOWN` (1) / 8 |
| `soa_done` / `gv` / AXI beats | 1 / 4 / 52 |

At `WDMA_GO` (`t=26760000`): `dst=0` `grant=0` `idle=1` `go=1` `busy=0` `own_ui=0`.  
First heartbeat (`t=165080000`) through `LIMIT_NO_DESTWAIT` (`t=20005080000`): `dst=3` `grant=0` `idle=1` `busy=1` `own_ui=0`. Dest left `D_GO` into `D_DRAIN` when `dma_busy` rose; no R beats without mux grant, so dest never reached `D_WAITDONE=4`.

## Verdict

| Field | Value |
|-------|-------|
| XSIM | **FAIL** (`E2R_RPATH_IDLE_CXSIM_GRANT0_00_FAIL_NO_DESTWAIT_GRANT0`) |
| Marker `…_XSIM_PASS` | **not issued** (dest never 4) |
| VERDICT_CLASS | **FAIL_NO_DESTWAIT_GRANT0** |
| WIRE_THAT_HOLDS_IDLE_0 | **NONE** (no dest-wait snapshot) |
| C_FIX | **NONE** |
| DEST | **3** |
| GRANT_STAYED_0 | **1** |
| H_CANDIDATE | **falsified** on this mux+grant=0 vehicle (`dst` never 4) |
| H_RIVAL | **supported** for dest ≠4. Mechanism clause “cannot leave `D_GO`” is only partial: dest occupied `D_DRAIN=3` after `busy` rose. Exploratory, not a new UNIT. |
| EXISTENCE | **not claimed** |
| BOARD_PASS | **not claimed** |

## Evidence quotes (`xsim.log`)

```text
VEHICLE=a7ng_native_v1_ab_core SIM_FULL=0 do_lm=1 CDC+B1_GRANT0+MUX ungated_cdc_rvalid SHARED_STUB_WDMA
PROBE t=26760000 phase=WDMA_GO dst=0 drain=0 fifo=0 c_rvalid=0 tr=0 idle=1 own=1 grant=0 own_ui=0 go=1 busy=0
PROBE t=165080000 phase=HB dst=3 drain=0 fifo=0 c_rvalid=0 tr=0 idle=1 own=1 grant=0 own_ui=0 go=0 busy=1 rleft=8 wst=1
PROBE t=20005080000 phase=LIMIT_NO_DESTWAIT dst=3 drain=0 fifo=0 c_rvalid=0 tr=0 idle=1 own=1 grant=0 own_ui=0 go=0 busy=1
REACHED_DESTWAIT=0 FIRST_TILE_DST=0 LIVE_TILE_DST=3 MAX_DST=3
GRANT_ROSE_BEFORE_DESTWAIT=0 GRANT_STAYED_0=1
DEST=3
VERDICT_CLASS=FAIL_NO_DESTWAIT_GRANT0
C_FIX=NONE
BOARD_PASS=not_claimed
XSIM=FAIL_NO_DESTWAIT_GRANT0
E2R_RPATH_IDLE_CXSIM_GRANT0_00_FAIL_NO_DESTWAIT_GRANT0 dst=3 max_dst=3 grant=0 grant_stayed_0=1 own_ui=0
```

Log SHA256 `E2B2BA9A4AA78F0B594638C1DE179B99E10D76DBBEBC9F0D3B443E3F2DA064D2` (`xsim.log`).  
TB SHA256 `D655F8C87C77F537BBAADFAAD198D6140FC9846599C53672263105606D560C54`.  
CDC SHA256 `AF3EDB1ACD9DF1EA1B52C5B7E06F5C0799AB8E65813A74CB5037FBB18C032B45` (`a7ng_axi_read_cdc.sv`, same as mux bag).  
Vivado 2026.1 xvlog / xelab (`-L xpm` + `glbl`) / xsim. No `vivado.exe` impl. No board.

## Interpretation (critical)

Legal dest-wait (`TILE_DST=4`) was **not** occupied while grant stayed 0. H_CANDIDATE is **falsified** on this stimulus. H_RIVAL dest ≠4 is **supported**. Silicon `TILE_DST=4∧GRANT=0` is **not** reproduced on the mux vehicle — leftover-after-grant (mux SHA `1596C402…`) is a different occupancy than dest-wait with grant never risen.

XSim ≠ board. Stub AXI ≠ MIG. `busy=1` with `grant=0` / `own_ui=0` is observed, not a C-FIX license.

**No C-FIX.** AND terms were not classified at dest-wait because dest-wait never occurred.

## Artifacts

| Path | Role |
|------|------|
| `PREREGISTER.md` | Scientific frame (before UNIT run) |
| `tests/xsim/tb_e2r_rpath_idle_cxsim_grant0_00.sv` | Canonical TB |
| `tests/xsim/run_e2r_rpath_idle_cxsim_grant0_00.tcl` | Canonical tcl |
| `tb_e2r_rpath_idle_cxsim_grant0_00.sv` | Copy used by xvlog cwd |
| `run_e2r_rpath_idle_cxsim_grant0_00.tcl` | Archived tcl |
| `sources.f` / `run_xsim.cmd` | xvlog / xelab / xsim (no `vivado.exe` impl) |
| `xsim.log` / `xsim_stdout.txt` | Tool + transcript |
| `probe_table.csv` | Four-wire + dest snapshots |
