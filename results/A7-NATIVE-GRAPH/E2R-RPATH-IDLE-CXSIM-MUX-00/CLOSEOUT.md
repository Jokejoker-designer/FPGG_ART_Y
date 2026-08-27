# E2R-RPATH-IDLE-CXSIM-MUX-00 (Class C-XSIM mux) — CLOSEOUT

**Date:** 2026-08-27  
**Worktree:** `D:/Jetking_sem4/SEM_4/arty-a7-online-lm-board`  
**Agent:** `a7-ng-xsim-verify`  
**Authority:** `results/A7-NATIVE-GRAPH/STATUS/E2R_CXSIM_MUX_DISPATCH.md`  
**Claim scope:** Mux leftover XSim only — **not** existence, **not** `BOARD_PASS`  
**Board program:** **No**  
**Product RTL edited:** **No**  
**C-FIX applied:** **No**  
**Forbidden bypass:** not used (`assign r_path_idle=1` absent; no force of `TILE_DST` / `dst`; no `soc_top` / MIG)

## Scientific frame

| Field | Value |
|-------|-------|
| OBSERVATION | Dest-wait XSim idle=1 with separate WDMA (SHA `DAD0E6DE…`). Silicon dest-wait `RPATH_IDLE=0` `GRANT=0`. SoC `cdc_rvalid=rvalid` ungated. |
| UNKNOWN | Which of `r_drain_hold` / `fifo_cnt` / `m_axi_rvalid` (`c_rvalid`) / `tr_cnt` is 1 at first legal `TILE_DST==4` through shared stub + AXI-read CDC + B1 + ungated `cdc_rvalid`. |
| H_CANDIDATE | Shared-bus leftover or WDMA R seen by ungated `cdc_rvalid` holds `c_rvalid` → idle=0. |
| H_RIVAL | Mux+CDC dest-wait still idle=1 (`NONE`); leftover is true MIG-only. |
| FALSIFIER | Force `dst`; full `soc_top`+MIG only; apply C-FIX; `FAIL_NO_DESTWAIT`; `SET` if >1 term. |
| UNIT | First dest-wait occupancy after one query (`snap_cyc=355` from rst). Not a cycle farm. |
| CONTROL | Dest-wait separate-WDMA idle=1; silicon `GRANT=0`. `SIM_FULL=0`. Dual clocks 12.5/100 MHz. |
| METRICS | `tile_dst`, four AND terms, idle, owner, grant, owner_ui, `cdc_rvalid`, stub `rvalid`, `grant_rose_before_destwait`. |

## Vehicle

`a7ng_native_v1_ab_core` `#(.SIM_FULL(1'b0))`, `do_lm=1`. TB-only (no product edit):

1. `a7ng_axi_read_cdc` between core AXI and one shared `a7ng_axi_soa_mem_stub` (ui 100 MHz).
2. B1 grant FF copied from SoC law (`grant` rises only when `wdma_owner && r_path_idle`).
3. Mux assigns copied from SoC ~170–201, including **ungated** `cdc_rvalid=rvalid`.
4. WDMA on the **same** stub R bus via `a7ng_wdma_cdc` + TB AXI responder (hold `busy=1` `done=0` after 8 R beats).
5. DUT-driven `dbg_tile_dst==4` only.

Idle law (frozen DUT):  
`r_path_idle = !r_drain_hold && (fifo_cnt==0) && !m_axi_rvalid && (tr_cnt==0)`  
with `m_axi_rvalid` = CDC master `c_rvalid`.

**Deviation (vehicle, not HARKing):** first compile used a registered WDMA R handshake that dropped the last beat (`FAIL_NO_DESTWAIT`, dest stuck `D_DRAIN=3` with `fifo=4` `c_rvalid=1`). UNIT below is the second run after a TB-only combinational handshake (`ddr_tile_dma` style). No product RTL change.

## First dest-wait snapshot (UNIT)

| Metric | Value |
|--------|-------|
| `dbg_tile_dst` | **4** |
| `r_drain_hold` | 0 |
| `fifo_cnt` | **4** |
| `m_axi_rvalid` (`c_rvalid`) | **1** |
| `tr_cnt` | 0 |
| `r_path_idle` | **0** |
| `wdma_owner` | 1 |
| `wdma_owner_grant` (TB B1 replica) | 1 |
| `wdma_owner_ui` | 1 |
| `cdc_rvalid` / stub `rvalid` at snap | 0 / 0 (WDMA already `W_HOLD`) |
| `grant_rose_before_destwait` | **1** |
| `n_hot` | 2 |
| `soa_done` / `gv` / AXI beats | 1 / 4 / 52 |

At `WDMA_GO` (before shared-bus R): idle=1, grant=1, owner_ui=0, all four terms 0. Leftover appears **after** grant + shared-bus WDMA R.

## Verdict

| Field | Value |
|-------|-------|
| XSIM | **PASS** (`E2R_RPATH_IDLE_CXSIM_MUX_00_XSIM_PASS`) |
| VERDICT_CLASS | **SET** |
| WIRE_THAT_HOLDS_IDLE_0 | **AMBIGUOUS** (do not name — two terms) |
| C_FIX | **NONE** |
| H_CANDIDATE | **supported** on this mux+shared-stub path (`fifo_cnt` + `c_rvalid` hold idle=0) |
| H_RIVAL | **falsified** on this vehicle (not `NONE`; leftover is not MIG-only here) |
| EXISTENCE | **not claimed** |
| BOARD_PASS | **not claimed** |

## Evidence quotes (`xsim.log`)

```text
VEHICLE=a7ng_native_v1_ab_core SIM_FULL=0 do_lm=1 CDC+B1+MUX ungated_cdc_rvalid SHARED_STUB_WDMA
PROBE t=26760000 phase=WDMA_GO dst=0 drain=0 fifo=0 c_rvalid=0 tr=0 idle=1 own=1 grant=1 own_ui=0
PROBE t=29640000 phase=FIRST_DESTWAIT dst=4 drain=0 fifo=4 c_rvalid=1 tr=0 idle=0 own=1 grant=1 own_ui=1 cdc_rv=0 stub_rv=0
REACHED_DESTWAIT=1 FIRST_TILE_DST=4 LIVE_TILE_DST=4
SNAP destwait_cyc=355 drain=0 fifo=4 c_rvalid=1 tr=0 idle=0 own=1 grant=1 own_ui=1 cdc_rv=0 stub_rv=0
GRANT_ROSE_BEFORE_DESTWAIT=1
AND_MASK drain,fifo,rvalid,tr = 0110 n_hot=2
WIRE_THAT_HOLDS_IDLE_0=AMBIGUOUS
VERDICT_CLASS=SET
C_FIX=NONE
BOARD_PASS=not_claimed
XSIM=PASS
E2R_RPATH_IDLE_CXSIM_MUX_00_XSIM_PASS verdict=SET wire=AMBIGUOUS c_fix=NONE idle=0 n_hot=2 dst=4 grant_rose=1
```

Log SHA256 `1596C402B1033E3D36E85DCE266A458C941C0F656BE08DC77A681A196034ED6B` (`xsim.log`).  
CDC SHA256 `AF3EDB1ACD9DF1EA1B52C5B7E06F5C0799AB8E65813A74CB5037FBB18C032B45` (`a7ng_axi_read_cdc.sv`, same as CDC bag).  
Bridge SHA256 `40170C5C8A5D0DFC7FA400762918DE7A363256B047ABE0667E3248F4D697A7FB` (`a7ng_ddr_soa_axi_bridge.sv`, same as dest-wait).  
Vivado 2026.1 xvlog / xelab (`-L xpm` + `glbl`) / xsim. No `vivado.exe` impl. No board.

## Interpretation (critical)

Legal dest-wait was occupied: DUT-driven `TILE_DST=4` after SOA 52 beats / 4th merge / `start_fwd` / first tile miss / shared-bus WDMA 8 R beats, with TB `busy` held so dest stayed `D_WAITDONE`. Two idle-law terms were 1: `fifo_cnt!=0` and `m_axi_rvalid` (`c_rvalid`). `r_path_idle=0`.

That **supports** H_CANDIDATE on this stimulus and **falsifies** H_RIVAL `NONE` (leftover is present on stub+CDC+ungated mux, so it is not MIG-only under this vehicle).

`SET` forbids naming a C-FIX wire. The leftover is already inside the SOA bridge / CDC master at dest-wait (stub `rvalid=0`, `cdc_rvalid=0` after WDMA `W_HOLD`). Mechanism consistent with ungated `cdc_rvalid=rvalid` accepting WDMA R while `rready` is stolen.

**Grant timing ≠ silicon.** `grant_rose_before_destwait=1` because idle was still 1 at `WDMA_GO`. Silicon dest-wait `GRANT=0` is not reproduced. This bag classifies leftover **after** a legal B1 grant + shared-bus WDMA, not leftover that blocked grant. XSim ≠ board. Stub AXI ≠ MIG.

**No C-FIX.** Naming a product patch on `m_axi_rvalid` or `fifo_cnt` is not licensed by a two-term `SET`.

## Artifacts

| Path | Role |
|------|------|
| `PREREGISTER.md` | Scientific frame (before UNIT run) |
| `tests/xsim/tb_e2r_rpath_idle_cxsim_mux_00.sv` | Canonical TB |
| `tests/xsim/run_e2r_rpath_idle_cxsim_mux_00.tcl` | Canonical tcl |
| `tb_e2r_rpath_idle_cxsim_mux_00.sv` | Copy used by xvlog cwd |
| `run_e2r_rpath_idle_cxsim_mux_00.tcl` | Archived tcl |
| `sources.f` / `run_xsim.cmd` | xvlog / xelab / xsim (no `vivado.exe` impl) |
| `xsim.log` / `xsim_stdout.txt` | Tool + transcript |
| `probe_table.csv` | Four-wire + dest snapshot |
