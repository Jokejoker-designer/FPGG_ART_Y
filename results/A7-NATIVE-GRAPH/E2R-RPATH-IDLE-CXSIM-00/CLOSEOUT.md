# E2R-RPATH-IDLE-CXSIM-00 (Class C-XSIM) — CLOSEOUT

**Date:** 2026-08-27  
**Worktree:** `D:/Jetking_sem4/SEM_4/arty-a7-online-lm-board`  
**Agent:** `a7-ng-xsim-verify`  
**Authority:** `results/A7-NATIVE-GRAPH/STATUS/E2R_CXSIM_DISPATCH.md`  
**Claim scope:** Isolated SOA AXI-bridge XSim only — **not** existence, **not** `BOARD_PASS`  
**Board program:** **No**  
**Product RTL edited:** **No**  
**Forbidden bypass:** not used (`assign r_path_idle=1` absent)

## Scientific frame

| Field | Value |
|-------|-------|
| OBSERVATION | F1v/F1w/B2/B-FIX UART `RPATH_IDLE=0` `GRANT=0` at `TILE_DST=4`. Grant = `wdma_owner && r_path_idle`. |
| UNKNOWN | Which of `r_drain_hold`, `fifo_cnt`, `m_axi_rvalid`, `tr_cnt` keeps idle=0 after one SOA-complete drain. |
| H_CANDIDATE | `r_drain_hold` stays 1 after `metric_clear` / SOA complete. |
| H_RIVAL | Leftover `fifo_cnt` or `tr_cnt` or stuck `m_axi_rvalid`. |
| FALSIFIER | All four clear and idle=1 after SOA-complete stimulus; or independent holder count ≠ 1. |
| UNIT | One metric_clear + one 4-beat AR/R fully consumed (query-equivalent), not a cycle farm. |
| CONTROL | Silicon `RPATH_IDLE=0`. Reset row idle=1. Phase C: each wire *can* hold idle=0. |
| ONE CHANGE | TB only (`tests/xsim/tb_e2r_rpath_idle_cxsim_00.sv`). |

## Verdict

| Field | Value |
|-------|-------|
| XSIM | **PASS** (`E2R_RPATH_IDLE_CXSIM_00_XSIM_PASS`) |
| WIRE_THAT_HOLDS_IDLE_0 | **NONE** |
| C_FIX_CONSTITUENT | **NONE** |
| VERDICT | **NO_LEFTOVER_AFTER_SOA_COMPLETE** |
| H_CANDIDATE | **falsified** under isolated complete drain + post-complete `metric_clear` |
| H_RIVAL | **not observed** at the UNIT snapshot (in-flight R_RETURNED is not dest-wait) |
| EXISTENCE | **not claimed** |
| BOARD_PASS | **not claimed** |
| NEXT_ONE_UNKNOWN | silicon leftover source (orphan rvalid / incomplete consumer / full-core probe), not this isolated complete drain |

## Numbers (n = 1 query-equivalent)

| Snapshot | idle | drain | fifo | rvalid | tr | dirty |
|----------|------|-------|------|--------|----|-------|
| RESET | 1 | 0 | 0 | 0 | 0 | 0 |
| Phase A UNIT (SOA complete + 16 clk) | **1** | 0 | 0 | 0 | 0 | 0 |
| Phase B (`metric_clear` + 8 clk) | **1** | 0 | 0 | 0 | 0 | 0 |
| R_RETURNED in-flight (not UNIT) | 0 | 0 | 1 | 1 | 1 | 3 |
| Phase C force each wire | 0 | one at a time | — | — | — | 1 (4/4) |

Phase C: 4/4 independent forces hold idle=0; restore idle=1. Idle law is a 4-way AND on this DUT. That does **not** name a leftover after complete drain.

## Evidence quotes (`xsim.log`)

```text
PHASE_A idle=1 drain=0 fifo=0 rvalid=0 tr=0 indep=0 wire=NONE mask=0000
PHASE_B idle=1 drain=0 fifo=0 rvalid=0 tr=0 indep=0 wire=NONE mask=0000
PHASE_C law_ok=1 n_law=4 mask=1111 (expect 4)
WIRE_THAT_HOLDS_IDLE_0=NONE
C_FIX_CONSTITUENT=NONE
VERDICT=NO_LEFTOVER_AFTER_SOA_COMPLETE
XSIM=PASS
E2R_RPATH_IDLE_CXSIM_00_XSIM_PASS probes_recorded=1 wire=NONE c_fix=NONE verdict=NO_LEFTOVER_AFTER_SOA_COMPLETE law_ok=1
```

DUT SHA256 `40170C5C8A5D0DFC7FA400762918DE7A363256B047ABE0667E3248F4D697A7FB` (`a7ng_ddr_soa_axi_bridge.sv`). Vivado 2026.1 xvlog/xelab/xsim. `$finish` at 524 ns.

## Interpretation (critical)

Isolated `a7ng_ddr_soa_axi_bridge` **does** release `r_drain_hold` after a 1-cycle `metric_clear` when `m_axi_rvalid=0` and fifo/tr are empty. After one completed 4-beat AR/R with a well-behaved slave and `r_ready=1`, all four constituents are clear and `r_path_idle=1`.

This **falsifies** H_CANDIDATE on this stimulus. It does **not** explain silicon `RPATH_IDLE=0` at `TILE_DST=4`. XSim ≠ board. A well-behaved exact-beat slave ≠ MIG/CDC. Always-ready consumer ≠ wavefront backpressure.

In-flight `R_RETURNED` shows fifo+rvalid+tr dirty together (dirty=3). That is expected mid-burst, not dest-wait after SOA done. Preregistered UNIT is the settled Phase A row.

**No C-FIX wire.** Naming a product patch on `r_drain_hold` (or any one constituent) is not licensed by this bag.

## Artifacts

| Path | Role |
|------|------|
| `PREREGISTER.md` | Scientific frame (before run) |
| `tests/xsim/tb_e2r_rpath_idle_cxsim_00.sv` | Canonical TB |
| `tb_e2r_rpath_idle_cxsim_00.sv` | Copy used by xvlog |
| `run_xsim.cmd` | xvlog / xelab / xsim (no `vivado.exe` impl) |
| `xsim.log` / `xsim_stdout.txt` | Tool + transcript |
| `xvlog_stdout.txt` / `xelab_stdout.txt` | Compile/elab |
| `probe_table.csv` / `PROBE_TABLE.md` | Four-wire table |
