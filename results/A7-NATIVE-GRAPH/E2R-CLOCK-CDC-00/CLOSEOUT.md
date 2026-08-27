# E2R-CLOCK-CDC-00 CLOSEOUT — PASS

**Verdict:** **PASS**  
**Date:** 2026-08-25  
**Build:** `vivado_build_r2e.log` (fix loop 2) — full `build_e2r_clock_cdc_00.tcl`  
**Worktree:** `arty-a7-online-lm-board` ONLY

## Metrics (post-route)

| Metric | Value | Gate | Status |
|--------|-------|------|--------|
| overall WNS / TNS | +1.026 / 0 ns | info | OK |
| core_clk WNS / TNS | **+12.126 / 0** ns | ≥0 / 0 | **PASS** |
| clk_pll_i WNS / TNS | **+2.046 / 0** ns | ≥0 / 0 | **PASS** |
| user unsafe_cdc | **0** | 0 | **PASS** |
| MIG false-path (BENIGN) | 3 (c166→div2/pll/mmcm_ps) | document | BENIGN |
| RAMB36 | **104** | ≤135 | **PASS** |
| SIM_FULL | 0 | 0 | **PASS** |
| `u_wdma_cdc` integrated | yes | required | **PASS** |

## Fixes that closed CDC

1. TILE DMA FSM on `clk` (same as fabric) — removed dual-clock BRAM CDC
2. Block-RAM XPM async FIFOs + dest-side registered beats; write-clock-only FIFO rst
3. Registered `boot_done`/`busy_o` in `a7ng_ddr_soa_boot` (no combo into synchronizers)
4. Constraints via Tcl (`e2r_core_clk_constraints.tcl`); metrics via `get_timing_paths`

## Artifacts

- `e2r_post_route.dcp`, `e2r_metrics.txt`, `report_cdc.rpt`, `report_timing_summary.rpt`
- `vivado_build_r2e.log`

**Next:** Gate 2 `E2R-WMEM-PRELOAD-00` (same session).
