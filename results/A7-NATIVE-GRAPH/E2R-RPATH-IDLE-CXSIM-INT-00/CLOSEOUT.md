# E2R-RPATH-IDLE-CXSIM-INT-00 (Class C-XSIM) — CLOSEOUT

**Date:** 2026-08-27  
**Worktree:** `D:/Jetking_sem4/SEM_4/arty-a7-online-lm-board`  
**Agent:** `a7-ng-xsim-verify`  
**Authority:** `results/A7-NATIVE-GRAPH/STATUS/E2R_CXSIM_INTEGRATED_DISPATCH.md`  
**Claim scope:** Integrated SOA+consumer XSim only — **not** existence, **not** `BOARD_PASS`  
**Board program:** **No**  
**Product RTL edited:** **No**  
**Forbidden bypass:** not used (`assign r_path_idle=1` absent)  
**Prior isolated bag:** `E2R-RPATH-IDLE-CXSIM-00` named `NONE` — not repeated as the only bag

## Scientific frame

| Field | Value |
|-------|-------|
| OBSERVATION | Isolated bridge C-XSIM idle=1 after complete drain. Silicon B-FIX/F1w `RPATH_IDLE=0` at `TILE_DST=4`. |
| UNKNOWN | In integrated native-v1-ab SOA path, after SOA-done, which leftover holds `r_path_idle=0`? |
| H_CANDIDATE | Incomplete consumer / leftover `m_axi_rvalid` or `tr_cnt`. |
| H_RIVAL | Second `metric_clear` / boot overlap holds `r_drain_hold`. |
| FALSIFIER | UNIT idle=1 **or** exactly one of four wires holds. |
| UNIT | One 64-candidate query to `soa_done` + 16 clk settle. Not a cycle farm. |
| CONTROL | Silicon `RPATH_IDLE=0`. Isolated C-XSIM idle=1. Stub ≠ MIG. XSim ≠ board. |
| ONE CHANGE | TB/probe only (`tests/xsim/tb_e2r_rpath_idle_cxsim_int_00.sv`). |

## MIG TB

`tb_a7ng_native_v1_ab_mig.sv` cannot reach dest-wait in a **bounded** C-XSIM (MIG calib + AXI preload + `#5000ms` + LM bind). Not run. `.r_path_idle_o()` stays tied off there.

Vehicle: `a7ng_cue_soa_mig_top` + `a7ng_axi_soa_mem_stub` (SOA bridge + wavefront consumer + owner `metric_clear`). `TILE_DST` **absent**, **not faked** as 4.

## Verdict

| Field | Value |
|-------|-------|
| XSIM | **PASS** (`E2R_RPATH_IDLE_CXSIM_INT_00_XSIM_PASS`) |
| WIRE_THAT_HOLDS_IDLE_0 | **NONE** |
| C_FIX_CONSTITUENT | **NONE** |
| VERDICT | **NO_LEFTOVER_AFTER_INTEGRATED_SOA_DONE** |
| H_CANDIDATE | **falsified** on this stub-integrated SOA-done path |
| H_RIVAL | **not observed** (`mc_after_start=1`) |
| EXISTENCE | **not claimed** |
| BOARD_PASS | **not claimed** |
| NEXT_ONE_UNKNOWN | silicon leftover is outside this stub-integrated TB (MIG/CDC/tile dest-wait / host mux) |

## Numbers (n = 1 query)

| Snapshot | idle | drain | fifo | rvalid | tr | dirty | mc_as | beats | del |
|----------|------|-------|------|--------|----|-------|-------|-------|-----|
| RESET / OWNER_READY | 1 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 |
| SOA_DONE | 1 | 0 | 0 | 0 | 0 | 0 | 1 | 52 | 64 |
| **UNIT settle** | **1** | **0** | **0** | **0** | **0** | **0** | **1** | **52** | **64** |

Leave-one-dirty not run (UNIT idle=1). Conservation: 52 AXI beats, 64 candidates delivered.

## Evidence quotes (`xsim.log`)

```text
VEHICLE=a7ng_cue_soa_mig_top+axi_stub MIG_TB=not_bounded TILE_DST=ABSENT_NOT_FAKED
PROBE t=1455000 phase=SOA_DONE drain=0 fifo=0 rvalid=0 tr=0 idle=1 dirty=0 mc=1 mc_as=1 ... beats=52 del=64
PROBE t=1615000 phase=UNIT_SOA_DONE_SETTLE drain=0 fifo=0 rvalid=0 tr=0 idle=1 dirty=0 mc=1 mc_as=1 ... beats=52 del=64
REACHED_SOA_DONE=1 UNIT_IDLE=1 DRAIN=0 FIFO=0 RVALID=0 TR=0 MC=1 MC_AFTER_START=1
WIRE_THAT_HOLDS_IDLE_0=NONE
C_FIX_CONSTITUENT=NONE
VERDICT=NO_LEFTOVER_AFTER_INTEGRATED_SOA_DONE
XSIM=PASS
E2R_RPATH_IDLE_CXSIM_INT_00_XSIM_PASS probes_recorded=1 wire=NONE c_fix=NONE verdict=NO_LEFTOVER_AFTER_INTEGRATED_SOA_DONE reached=1
```

DUT SHA256 `40170C5C8A5D0DFC7FA400762918DE7A363256B047ABE0667E3248F4D697A7FB` (`a7ng_ddr_soa_axi_bridge.sv`). Vivado 2026.1 xvlog/xelab/xsim. Wall ~7.7 s. No `vivado.exe` impl.

## Interpretation (critical)

Integrated SOA with the **real consumer** (wavefront `r_ready` + termgen + NG02 + global Top-K) and one owner `metric_clear` **does** leave `r_path_idle=1` at SOA-done. All four constituents are clear. That is a stronger falsifier than the isolated 4-beat complete-drain bag, and it still names **no** leftover wire.

This **falsifies** H_CANDIDATE on this stimulus. H_RIVAL is **not observed** (exactly one `metric_clear` after start). It does **not** explain silicon `RPATH_IDLE=0` at `TILE_DST=4`. XSim ≠ board. AXI stub ≠ MIG/CDC. Always-ready `cons_ready` ≠ board mux / WDMA steal. `TILE_DST` was not present and was not faked.

**No C-FIX wire.** Naming a product patch on any constituent is not licensed by this bag.

## Artifacts

| Path | Role |
|------|------|
| `PREREGISTER.md` | Scientific frame (before run) |
| `tests/xsim/tb_e2r_rpath_idle_cxsim_int_00.sv` | Canonical TB |
| `tb_e2r_rpath_idle_cxsim_int_00.sv` | Copy used by xvlog cwd |
| `sources.f` / `run_xsim.cmd` | xvlog / xelab / xsim (no `vivado.exe` impl) |
| `xsim.log` / `xsim_stdout.txt` | Tool + transcript |
| `xvlog_stdout.txt` / `xelab_stdout.txt` | Compile/elab |
| `probe_table.csv` / `PROBE_TABLE.md` | Four-wire table |
