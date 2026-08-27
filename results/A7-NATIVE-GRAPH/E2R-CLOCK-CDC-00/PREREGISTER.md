# PREREGISTER — E2R-CLOCK-CDC-00

**Gate:** E2R-CLOCK-CDC-00  
**Date:** 2026-08-25  
**Worktree:** `D:\Jetking_sem4\SEM_4\arty-a7-online-lm-board` ONLY

## ONE UNKNOWN

Can integrated SoC close timing with Native/LM core @ 12.5 MHz (`core_clk`) and MIG on `ui_clk` with explicit AXI read CDC?

## Architecture

- `clk_core_12p5` MMCM: 100 MHz → 12.5 MHz (`core_raw` 80 ns)
- `u_ab` on `core_clk`; `clk_dma` on `ui_clk`
- `a7ng_axi_read_cdc` (XPM async FIFO) for AXI AR/R
- `set_clock_groups -asynchronous` between `core_raw` and `clk_pll_i`

## Acceptance (no program)

| Metric | Threshold |
|--------|-----------|
| core domain WNS | ≥ 0 |
| core domain TNS | 0 |
| ui domain WNS | ≥ 0 |
| ui domain TNS | 0 |
| unsafe CDC | 0 |
| RAMB36 | ≤ 135 |
| SIM_FULL | 0 |

## Falsifier

Any intra-domain WNS < 0, nonzero unsafe CDC, or RAMB36 > 135.
