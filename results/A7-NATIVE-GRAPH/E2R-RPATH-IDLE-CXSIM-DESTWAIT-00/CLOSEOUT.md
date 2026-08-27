# E2R-RPATH-IDLE-CXSIM-DESTWAIT-00 (Class C-XSIM dest-wait) — CLOSEOUT

**Date:** 2026-08-27  
**Worktree:** `D:/Jetking_sem4/SEM_4/arty-a7-online-lm-board`  
**Agent:** `a7-ng-xsim-verify`  
**Authority:** `results/A7-NATIVE-GRAPH/STATUS/E2R_CXSIM_DESTWAIT_DISPATCH.md`  
**Claim scope:** Dest-wait leftover XSim only — **not** existence, **not** `BOARD_PASS`  
**Board program:** **No**  
**Product RTL edited:** **No**  
**C-FIX applied:** **No**  
**Forbidden bypass:** not used (`assign r_path_idle=1` absent; no force of `TILE_DST` / `dst`)  
**Sealed complete-query bags:** not re-run as the only result

## Scientific frame

| Field | Value |
|-------|-------|
| OBSERVATION | Silicon dest-wait `TILE_DST=4` `RPATH_IDLE=0` `GRANT=0` (BIT `6023D9A3…`). Complete-query XSim idle=1 after SOA drain. |
| UNKNOWN | Which of `r_drain_hold`, `fifo_cnt!=0`, `m_axi_rvalid`, `tr_cnt!=0` is 1 at first legal `dbg_tile_dst_o==3'd4`. |
| H_CANDIDATE | `m_axi_rvalid` leftover holds idle=0 at dest-wait. |
| H_RIVAL | `fifo_cnt`/`tr_cnt` leftover; or dest-wait also idle=1 (`NONE`). |
| FALSIFIER | Never reach dest-wait (`FAIL_NO_DESTWAIT`); force `dst`; more than one term (`SET`). |
| UNIT | First dest-wait occupancy after one query start (`snap_cyc=208` from rst). Not a cycle farm. |
| CONTROL | Isolated/INT/CDC complete-query idle=1. Silicon dest-wait idle=0. `SIM_FULL=0`. Legal WDMA hold `busy=1` `done=0` after 8 R beats. |
| METRICS | `tile_dst`, `r_drain_hold`, `fifo_cnt`, `m_axi_rvalid`, `tr_cnt`, `r_path_idle`, `wdma_owner`, `wdma_owner_grant`. |

## Vehicle

`a7ng_native_v1_ab_core` `#(.SIM_FULL(1'b0))`, `do_lm=1`, AXI SOA stub, TB-only WDMA responder (no hierarchical dest force). Tile law observed: `WDMA_GO` at `bst=4`/`miss=1`/`reqs1=1`, then 8 R beats, then hold so DUT `dbg_tile_dst_o` became `4` (`D_WAITDONE`).

Idle law (frozen DUT):  
`r_path_idle = !r_drain_hold && (fifo_cnt==0) && !m_axi_rvalid && (tr_cnt==0)`.

## First dest-wait snapshot (UNIT)

| Metric | Value |
|--------|-------|
| `dbg_tile_dst` | **4** |
| `r_drain_hold` | 0 |
| `fifo_cnt` | 0 |
| `m_axi_rvalid` | 0 |
| `tr_cnt` | 0 |
| `r_path_idle` | **1** |
| `wdma_owner` | 1 |
| `wdma_owner_grant` (TB B1 replica) | 1 |
| `n_hot` | 0 |
| `soa_done` / `gv` / AXI beats | 1 / 4 / 52 |
| WDMA after UNIT | `busy=1` `done=0` `r_valid=0` |

`wdma_owner_grant=1` is the TB replica of SoC B1 (`grant` rises only when `owner && r_path_idle`). It is **not** a product C-FIX. Silicon `GRANT=0` is the B1 consequence of `RPATH_IDLE=0`, which this stub dest-wait did not reproduce.

## Verdict

| Field | Value |
|-------|-------|
| XSIM | **PASS** (`E2R_RPATH_IDLE_CXSIM_DESTWAIT_00_XSIM_PASS`) |
| VERDICT_CLASS | **NONE** |
| WIRE_THAT_HOLDS_IDLE_0 | **NONE** |
| C_FIX | **NONE** |
| H_CANDIDATE | **falsified** on this stub dest-wait path (`m_axi_rvalid=0`, idle=1) |
| H_RIVAL | **supported** (dest-wait idle=1 / leftover not on this stub path) |
| EXISTENCE | **not claimed** |
| BOARD_PASS | **not claimed** |

## Evidence quotes (`xsim.log`)

```text
VEHICLE=a7ng_native_v1_ab_core SIM_FULL=0 do_lm=1 WDMA_RESPONDER=hold_busy
PROBE t=2205000 phase=FIRST_DESTWAIT dst=4 drain=0 fifo=0 rvalid=0 tr=0 idle=1 own=1 grant=1 go=0 busy=1 rready=0 rleft=0 miss=1 reqs1=1 bst=4 stall=1 soa_done=1 run=0 fwd=0 core_busy=1 phase=1 gv=4
REACHED_DESTWAIT=1 FIRST_TILE_DST=4 LIVE_TILE_DST=4
SNAP destwait_cyc=208 drain=0 fifo=0 rvalid=0 tr=0 idle=1 own=1 grant=1
AND_MASK drain,fifo,rvalid,tr = 0000 n_hot=0
WIRE_THAT_HOLDS_IDLE_0=NONE
VERDICT_CLASS=NONE
C_FIX=NONE
BOARD_PASS=not_claimed
XSIM=PASS
E2R_RPATH_IDLE_CXSIM_DESTWAIT_00_XSIM_PASS verdict=NONE wire=NONE c_fix=NONE idle=1 n_hot=0 dst=4
```

Log SHA256 `DAD0E6DEDB9122453F7E5B623DC2C320512C529575C934A320BA6FA8C2EE1900` (`xsim.log`).  
Bridge SHA256 `40170C5C8A5D0DFC7FA400762918DE7A363256B047ABE0667E3248F4D697A7FB` (`a7ng_ddr_soa_axi_bridge.sv`, same as isolated/INT/CDC).  
Vivado 2026.1 xvlog / xelab / xsim. Wall ~8 s. No `vivado.exe` impl. No board.

## Interpretation (critical)

Legal dest-wait was occupied: DUT-driven `TILE_DST=4` after SOA 52 beats / 4th merge / `start_fwd` / first tile miss / 8 WDMA R beats, with TB `busy` held so dest stayed `D_WAITDONE`. All four idle-law terms were 0. `r_path_idle=1`.

That **falsifies** H_CANDIDATE on this stimulus. H_RIVAL `NONE` is **supported**: leftover that holds silicon `RPATH_IDLE=0` at dest-wait is **not** present on this AXI-stub + separate WDMA-port path.

This does **not** explain silicon B-FIX `RPATH_IDLE=0` `GRANT=0` at `TILE_DST=4`. XSim ≠ board. Stub AXI ≠ MIG. Separate WDMA port ≠ SoC mux steal of the query R bus. Always-ready SOA consumer ≠ board CDC/mux.

**No C-FIX wire.** Naming a product patch on `m_axi_rvalid` (or any other AND term) is not licensed by this bag.

## Artifacts

| Path | Role |
|------|------|
| `PREREGISTER.md` | Scientific frame (before run) |
| `tests/xsim/tb_e2r_rpath_idle_cxsim_destwait_00.sv` | Canonical TB |
| `tests/xsim/run_e2r_rpath_idle_cxsim_destwait_00.tcl` | Canonical tcl |
| `tb_e2r_rpath_idle_cxsim_destwait_00.sv` | Copy used by xvlog cwd |
| `run_e2r_rpath_idle_cxsim_destwait_00.tcl` | Archived tcl |
| `sources.f` / `run_xsim.cmd` | xvlog / xelab / xsim (no `vivado.exe` impl) |
| `xsim.log` / `xsim_stdout.txt` | Tool + transcript |
| `probe_table.csv` | Four-wire + dest snapshot |
