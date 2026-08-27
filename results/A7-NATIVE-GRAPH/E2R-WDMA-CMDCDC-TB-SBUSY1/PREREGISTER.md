# E2R-WDMA-CMDCDC-TB-SBUSY1 — PREREGISTER

**Date:** 2026-08-27  
**Worktree:** `D:/Jetking_sem4/SEM_4/arty-a7-online-lm-board`  
**Agent:** `a7-ng-xsim-verify`  
**Authority:** `results/A7-NATIVE-GRAPH/STATUS/E2R_F1B2_XSIM_SBUSY_DISPATCH.md` (main repo)  
**Class:** B (XSim unit only)  
**Board:** NOT used. No program. No COM12. No bitstream Vivado.

## Scientific frame

| Field | Value |
|-------|-------|
| OBSERVATION | TB-00 CONTROL (`s_busy=0`): one `m_go` → `cmd_rd_en=1` then `s_go=1` at 8 `s_clk`. RTL law: `cmd_rd_en = … && !s_busy`. Silicon F1w still MGO=1 SGO=0. |
| UNKNOWN | Does `cmd_rd_en` stay 0 and `s_go` never fire while `s_busy=1` after one `m_go`? |
| H_CANDIDATE | Yes — preregistered **B-FIX**: `s_busy` gates `cmd_rd_en` (rd only when DMA idle + tile wait). |
| H_RIVAL | `s_busy` is unused or bypassed; `cmd_rd_en`/`s_go` still fire as in TB-00. |
| FALSIFIER | Any `cmd_rd_en=1` or `s_go=1` in the 50 `s_clk` window while `s_busy` held 1. |
| UNIT | One `m_go` command (not clock-cycle farm). |
| CONTROL | `E2R-WDMA-CMDCDC-TB-00` same DUT clocks/window, `s_busy=0`, `s_go=1` / `rd_en=1`. |
| METRICS | XSIM compile+run+probes; `s_go` 0\|1; `cmd_rd_en` ever 0\|1; VERDICT B-FIX. |

## ONE CHANGE

Unit TB variant of `tests/xsim/tb_e2r_wdma_cmdcdc_00.sv`: **`s_busy` held 1** for the whole window after one `m_go`.  
**No** B1 / grant / `r_path_idle` / tile / board. **No** product RTL edit.

## DUT freeze (observation)

| Item | Value |
|------|-------|
| File | `rtl/board/a7ng_wdma_cdc.sv` |
| SHA256 | `024CC88BFFC588F8C4527528E32B4C02BE6F90F363835055E4A72A46A072494D` |
| Read law | `cmd_rd_en = s_rst_n && (cmd_st==C_IDLE) && !cmd_pend && !cmd_empty && !s_busy` |

## Protocol

1. Instantiate only `a7ng_wdma_cdc` (+ `xpm` + `glbl`).
2. `m_clk` 80 ns; `s_clk` 10 ns; window = 50 `s_clk` after `m_go`.
3. Hold both resets ≥25 `m_clk`; release; XPM recovery (40 m + 80 s).
4. Set `s_busy=1` before `m_go`; hold through the window. Pulse **one** `m_go` for 1 `m_clk`.
5. Log `m_go`, `s_go`, `s_busy`, `cmd_wr_en`, `cmd_full`, `cmd_empty`, `cmd_rd_en`, `cmd_pend`, `s_go_r`.
6. XSIM=PASS if TB compiles and records probes. Do **not** require `s_go=1`.
7. VERDICT **B-FIX supported** iff `cmd_rd_en` never and `s_go` never while `s_busy=1` and empty cleared (write accepted).
8. VERDICT **B-FIX falsified** iff `cmd_rd_en=1` or `s_go=1` while `s_busy=1`.
9. No EXISTENCE. No BOARD_PASS.

## Interpretation (post-run; do not rewrite)

| TB result | Favored |
|-----------|---------|
| empty clears, `rd_en=0`, `s_go=0` | H_CANDIDATE **supported** (B-FIX) |
| `rd_en=1` or `s_go=1` while busy | H_CANDIDATE **falsified** |
| empty never clears | indeterminate (write/rst), not B-FIX |
