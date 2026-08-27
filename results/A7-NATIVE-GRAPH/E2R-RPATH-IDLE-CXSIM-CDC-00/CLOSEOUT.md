# E2R-RPATH-IDLE-CXSIM-CDC-00 (Class C-XSIM) — CLOSEOUT

**Date:** 2026-08-27  
**Worktree:** `D:/Jetking_sem4/SEM_4/arty-a7-online-lm-board`  
**Agent:** `a7-ng-xsim-verify`  
**Authority:** `results/A7-NATIVE-GRAPH/STATUS/E2R_CXSIM_CDC_DISPATCH.md`  
**Claim scope:** Dual-clock CDC + SOA-bridge XSim only — **not** existence, **not** `BOARD_PASS`  
**Board program:** **No**  
**Product RTL edited:** **No**  
**Forbidden bypass:** not used (`assign r_path_idle=1` absent)  
**Prior bags not repeated as the only bag:** isolated complete-drain `NONE`; stub-INT `E2R-RPATH-IDLE-CXSIM-INT-00` `NONE`

## Scientific frame

| Field | Value |
|-------|-------|
| OBSERVATION | Isolated + stub-INT C-XSIM idle=1 after SOA-complete. Silicon late-latch `RPATH_IDLE=0` while `core_busy`. |
| UNKNOWN | After one completed AR/R through `a7ng_axi_read_cdc` into `a7ng_ddr_soa_axi_bridge`, does CDC keep a leftover so `r_path_idle=0`? |
| H_CANDIDATE | CDC `m_rvalid_r` / `m_r_hold` / R FIFO / AR hold after last beat. |
| H_RIVAL | CDC quiet; idle=1 (leftover is mux/tile only → no C-FIX). |
| FALSIFIER | UNIT idle=1 and CDC quiet, or exactly one named leftover. |
| UNIT | One 4-beat AR/R through CDC + 32 `m_clk` settle. n=1 query-equivalent. |
| CONTROL | Silicon late-latch idle=0. Stub-INT idle=1 without CDC. Isolated idle=1 without CDC. Phase C: forced `m_rvalid_r` can hold idle=0. |
| ONE CHANGE | TB only (`tests/xsim/tb_e2r_rpath_idle_cxsim_cdc_00.sv`). |

## Verdict

| Field | Value |
|-------|-------|
| XSIM | **PASS** (`E2R_RPATH_IDLE_CXSIM_CDC_00_XSIM_PASS`) |
| WIRE_THAT_HOLDS_IDLE_0 | **NONE** |
| C_FIX_CONSTITUENT | **NONE** |
| VERDICT | **H_RIVAL_CDC_QUIET_NO_CFIX** |
| H_CANDIDATE | **falsified** on this dual-clock CDC-in-path complete query |
| H_RIVAL | **supported** (CDC quiet; idle=1) |
| EXISTENCE | **not claimed** |
| BOARD_PASS | **not claimed** |
| NEXT_ONE_UNKNOWN | silicon leftover is mux/tile dest-wait (not CDC leftover after SOA-complete) |

## Numbers (n = 1 query through CDC)

| Snapshot | idle | drain | fifo | rvalid | tr | m_rvalid_r | m_r_hold | r_empty | cdc_q | cons |
|----------|------|-------|------|--------|----|------------|----------|---------|-------|------|
| RESET / POST_CLEAR | 1 | 0 | 0 | 0 | 0 | 0 | 0 | 1 | 1 | 0 |
| R_CONSUMED | 1 | 0 | 0 | 0 | 0 | 0 | 0 | 1 | 1 | 4 |
| **UNIT settle** | **1** | **0** | **0** | **0** | **0** | **0** | **0** | **1** | **1** | **4** |
| Phase C force `m_rvalid_r` | 0 | 0 | 0 | 1 | 0 | 1 | 0 | 1 | 0 | 4 |

Leave-one-dirty not run (UNIT idle=1). Conservation: 4 consumer beats with `r_last`. Dual clocks 12.5 MHz / 100 MHz.

## Evidence quotes (`xsim.log`)

```text
VEHICLE=soa_bridge+axi_read_cdc PRIOR=isolated_NONE+stubINT_NONE
PROBE t=8680000 phase=UNIT_CDC_SOA_SETTLE drain=0 fifo=0 rvalid=0 tr=0 idle=1 dirty=0 mrv=0 hold=0 empty=1 pend=0 arhold=0 armst=0 cdc_q=1 cons=4 last=1
UNIT idle=1 drain=0 fifo=0 rvalid=0 tr=0 mrv=0 hold=0 empty=1 pend=0 arhold=0 armst=0 cdc_q=1 indep=0 wire=NONE mask=0000
PHASE_C law_ok=1 m_rvalid_r_holds_idle0=1
WIRE_THAT_HOLDS_IDLE_0=NONE
C_FIX_CONSTITUENT=NONE
VERDICT=H_RIVAL_CDC_QUIET_NO_CFIX
XSIM=PASS
E2R_RPATH_IDLE_CXSIM_CDC_00_XSIM_PASS probes_recorded=1 wire=NONE c_fix=NONE verdict=H_RIVAL_CDC_QUIET_NO_CFIX law_ok=1 idle=1 cdc_q=1
```

Bridge SHA256 `40170C5C8A5D0DFC7FA400762918DE7A363256B047ABE0667E3248F4D697A7FB` (`a7ng_ddr_soa_axi_bridge.sv`, same as isolated/INT).  
CDC SHA256 `AF3EDB1ACD9DF1EA1B52C5B7E06F5C0799AB8E65813A74CB5037FBB18C032B45` (`a7ng_axi_read_cdc.sv`).  
Vivado 2026.1 xvlog/xelab/xsim (`-L xpm` + `glbl`). `$finish` at 8683 ns. No `vivado.exe` impl.

## Interpretation (critical)

After one completed AR/R through the **real** `a7ng_axi_read_cdc` (AR `xpm_cdc_handshake` + R async FIFO) into the SOA bridge, UNIT settle leaves `r_path_idle=1` and CDC quiet: `m_rvalid_r=0`, `m_r_hold=0`, `r_empty=1`, `m_r_pend=0`, `s_ar_hold=0`, `ar_m_st=IDLE`. All four bridge constituents are clear.

This **falsifies** H_CANDIDATE on this stimulus. H_RIVAL is **supported**: leftover after SOA-complete is not a CDC hold. Phase C shows a forced `m_rvalid_r` *can* hold idle=0, so the probe is not vacuous — the CDC rvalid path is in the idle law, and it is **not** stuck after the last beat.

This does **not** explain silicon late-latch `RPATH_IDLE=0` while `core_busy`. XSim ≠ board. Dual-clock stub ≠ MIG. Always-ready consumer ≠ tile dest-wait / WDMA mux. 4-beat query ≠ 52-beat SOA.

**No C-FIX wire.** Naming a product patch on `m_rvalid_r`, `m_r_hold`, R FIFO, or AR hold is not licensed by this bag.

## Artifacts

| Path | Role |
|------|------|
| `PREREGISTER.md` | Scientific frame (before run) |
| `tests/xsim/tb_e2r_rpath_idle_cxsim_cdc_00.sv` | Canonical TB |
| `tb_e2r_rpath_idle_cxsim_cdc_00.sv` | Copy used by xvlog cwd |
| `run_xsim.cmd` | xvlog / xelab / xsim (no `vivado.exe` impl) |
| `xsim.log` / `xsim_stdout.txt` | Tool + transcript |
| `xvlog_stdout.txt` / `xvlog_glbl.txt` / `xelab_stdout.txt` | Compile/elab |
| `probe_table.csv` / `PROBE_TABLE.md` | Idle + four bridge + CDC rvalid/hold/empty |
