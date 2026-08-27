# RESULTS — E2R-CLOCK-CDC-00

**Date:** 2026-08-25  
**Build:** `vivado/tcl/build_e2r_clock_cdc_00.tcl` + `route_e2r_clock_cdc_00.tcl` (async groups)

## Post-route metrics (after `set_clock_groups` core ↔ ui)

| Metric | Measured | Gate | Verdict |
|--------|----------|------|---------|
| RAMB36 | 96 | ≤ 135 | PASS |
| DSP48 | 19 | info | — |
| Overall WNS | +0.879 ns | ≥ 0 | PASS |
| Overall TNS | 0 | 0 | PASS |
| core_raw WNS | +9.915 ns | ≥ 0 | PASS |
| core_raw TNS | 0 | 0 | PASS |
| clk_pll_i WNS | +1.340 ns | ≥ 0 | PASS |
| clk_pll_i TNS | 0 | 0 | PASS |
| WHS | +0.009 ns | report | OK |
| THS | 0 | report | OK |
| report_cdc Unsafe (core→ui) | 128 | 0 | **FAIL** |
| report_cdc Unsafe (ui→core) | 33 | 0 | **FAIL** |
| report_cdc Unsafe (MIG infra) | 3 | 0 | **FAIL** |

## RTL changes (board worktree only)

- `rtl/board/clk_core_12p5.sv` — MMCM 12.5 MHz
- `rtl/board/a7ng_axi_read_cdc.sv` — XPM FIFO AXI read CDC
- `rtl/board/arty_a7_ng_native_v1_ab_soc_top.sv` — `u_ab` on core_clk, AXI via CDC
- `constraints/e2r_core_clk.xdc` — generated clock + async groups

## Artifacts

```text
results/A7-NATIVE-GRAPH/E2R-CLOCK-CDC-00/e2r_post_route.dcp
results/A7-NATIVE-GRAPH/E2R-CLOCK-CDC-00/report_timing_summary.rpt
results/A7-NATIVE-GRAPH/E2R-CLOCK-CDC-00/report_clocks_route.rpt
results/A7-NATIVE-GRAPH/E2R-CLOCK-CDC-00/report_clock_interaction.rpt
results/A7-NATIVE-GRAPH/E2R-CLOCK-CDC-00/report_cdc.rpt
results/A7-NATIVE-GRAPH/E2R-CLOCK-CDC-00/report_utilization_route.rpt
results/A7-NATIVE-GRAPH/E2R-CLOCK-CDC-00/e2r_metrics.txt
```

## Notes

- First integrated route without async groups: WNS −4.131 ns (cross-clock core↔ui).
- After `set_clock_groups` between `core_raw` and `clk_pll_i`: all user timing constraints met.
- `report_cdc` still flags Critical unsafe endpoints on core↔ui (wdma `clk_dma` multi-bit + FIFO gray), and 3 MIG infra crossings.
