# GO-EXISTENCE-SOC-00 — CLOSEOUT

**Date:** 2026-08-30  
**Tree:** `D:\Jetking_sem4\SEM_4\arty-a7-online-lm-grok-orch-00`  
**Branch:** `research/native-ai-v1-grok-orch-00`  
**PROGRAM:** NO. **JTAG this gate:** NO. **QSTAR on SoC:** NO.  
**EXISTENCE:** not claimed. **BOARD_PASS:** not claimed.

## Unknown

Can this checkout produce a bitstream of `arty_a7_ng_native_v1_ab_soc_top` with WNS≥0 TNS=0 BRAM36≤135, SHA-pinned to the six sealed fence files?

**Answer:** YES — `BIT_OK`. Not UART `pred=664`.

## Product SHA (pinned at synth)

| File | SHA256 |
|------|--------|
| `a7ng_wdma_cdc.sv` | `E951F1F37D9FE7353103860CA0185D74A1C6D12FB43348C07C91816B093AA582` |
| `arty_a7_ng_native_v1_ab_soc_top.sv` | `57BD7B4D94F160A082734CFFC4A508556CD45FB2A291C2EB9E0DEDFF99EC717F` |
| `tiny_gpt803k_core.sv` | `355182A70E586B12C0F3EFA67D7A37971864D205660384199EF8AF75228F3DD7` |
| `ddr_tile_dma.sv` | `20BAE36ECCB6C94C2C5C9635D5FB7F771F09539E252316CC75D8F723810AD7C5` |
| `weight_tile803k.sv` | `A4E5FEACC29B1B69BF525915FECB81DEAEF7032A89035582AE513B23F432FCF1` |

## Physical result

| Metric | Value |
|--------|-------|
| synth | completed, 0 errors |
| `u_ab` RAMB36 preplace | 19 (gate 120) |
| RAMB36 chip | 103 (gate 135) |
| route | completed successfully |
| Design Timing Summary | **WNS=0.164 TNS=0.000 WHS=0.015 THS=0.000** |
| core_WNS / ui_WNS | 10.079 / 1.948 |
| constraints | All user specified timing constraints are met |
| DRC at bitgen | 0 errors after ja-only NSTD-1/UCIO-1 waive (no LiteScope XDC) |
| BIT | `arty_a7_ng_native_v1_grok_orch_existence_00.bit` |
| BIT SHA256 | `B64B26498F960980903FD4D7CF305FD4861996EBC60307901B32F89454870F17` |

## CDC

`clk_pll_i` → `core_clk` uns=2 **FINDING_ONLY**, not bitstream skip (INTEGRATE law): combo-before-sync into `u_wdma_rel_sync` (`sync_bits` WIDTH=3). Clock-gen falsepaths: 3 (c166_raw).

First TCL pass treated `cdc_cand=2` as `GATE_FAIL` and skipped the bit. That was **stricter than the sealed INTEGRATE classify**. Second pass wrote the bit from `e2r_post_route.dcp` with FINDING_ONLY documented.

`TIMING_PARSE WNS=NA` was `-return_string` regex miss; file Design Timing Summary is WNS=0.164.

## Not done

- No `open_hw_manager`
- No leftover LONGBOOT/two-pass/`9C1F4565` program
- UART `NATIVE_V1_EXIST_ROW,pred=664` not observed
- Token `com12_authorized_gate=research/native-ai-v1-grok-orch-00` still required before program
