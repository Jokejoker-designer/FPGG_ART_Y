# E2R-T2-SPI-WMEM-00 CLOSEOUT

**Date:** 2026-08-25  
**Worktree:** `arty-a7-online-lm-board` ONLY  
**Agent:** a7-vivado-gate

## Ack

| Item | Status |
|------|--------|
| **F2 CONFIRMED** | UART hex nibbles → 664 printed as 298. **Fixed** in same top: decimal `/100,/10,%10` |
| B1 | PLAUSIBLE only — not treated as E2 root cause; not patched |
| C2 / OA-1 | Skipped per inject |

## ONE UNKNOWN (T2)

Can FPGA-owned QSPI→AXI→DDR @ `0x0010_0000` (802816 B) replace synth-zero `rd_img` so UART shows ASCII **pred=664**?

## Rebuild gate metrics (post-route)

| Metric | Value | Gate | Verdict |
|--------|-------|------|---------|
| core_clk WNS | **+9.915 ns** | ≥0 | **PASS** |
| core_clk TNS | 0 | =0 | **PASS** |
| ui (clk_pll_i) WNS | **+0.860 ns** | ≥0 | **PASS** |
| ui TNS | 0 | =0 | **PASS** |
| unsafe user CDC | **0** | =0 | **PASS** |
| RAMB36 | **104** | ≤135 | **PASS** |
| SIM_FULL | 0 | =0 | **PASS** |
| Bitstream | written | — | **PASS** |

**Bit SHA256:** `993CB84FED85FA4F1FD7E5791DD564B85B44CD5668AE55A19336DB72AA53E9F0`  
**Path:** `results/A7-NATIVE-GRAPH/E2R-T2-SPI-WMEM-00/arty_a7_ng_native_v1_t2_spi_wmem_00.bit`

## Flash payload

| Field | Value |
|-------|-------|
| Hex SHA256 (control) | `9A6BBC7AC8AF82725CAFD0B50241EE683C07FB9943C754753025F3569967D10F` |
| Bin length | 802816 |
| Flash offset | `0x400000` |
| Program | **PASS** (erase+program+verify) JTAG `210319BE776EA` |
| MCS | `wmem_at_0x400000.mcs` |

## Gate 4 board (E2R-BOARD-EXISTENCE-01)

| Step | Result |
|------|--------|
| JTAG program bit | **PASS** (`210319BE776EA`) |
| COM12 capture (listener armed before reprogram, 180 s) | **0 bytes** |
| pred | **none** |
| `NATIVE_V1_EXISTENCE_BOARD_PASS` | **NOT claimed** |

Same symptom class as E2-BOARD-EXISTENCE-00 (`raw_bytes: 0`). Timing is no longer the blocker; functional hang before UART `bind` TX is open.

## Verdict

| Gate | Verdict |
|------|---------|
| T2 rebuild (timing/CDC/BRAM/bit) | **PASS** |
| T2 flash image @ 0x400000 | **PASS** |
| F2 decimal UART in bit | **PASS** (RTL) |
| Gate 4 existence (pred=664) | **FAIL / BLOCKED** — UART silent |

## DECIDE (do not program zeros; do not host-poke weights)

| Opt | Action |
|-----|--------|
| **A** | Add early UART heartbeat (`BOOT/MIG_OK/WMEM_OK/bytes`) + LED sticky before bind; rebuild once; localize hang |
| **B** | Retarget SCK to `STARTUPE2` USRCCLKO (vs Digilent L16 user tap); keep flash image |
| **C** | Pause Gate 4; seal T2 timing+flash evidence; human board bring-up |

**Cursor preference:** **A** (cheap diagnose; F2 already in tree).

## Forbidden not done

- No host UART/JTAG weight poke  
- No self-claim `NATIVE_V1_MINI_AI_BOARD_PASS` / §14 complete  
- No T2-COMPRESS invent  

## Artifacts

```
results/A7-NATIVE-GRAPH/E2R-T2-SPI-WMEM-00/
  PREREGISTER.md
  CLOSEOUT.md (this file)
  e2r_metrics.txt
  BIT_SHA256.txt
  PAYLOAD.txt
  a7lm06_wmem.bin
  wmem_at_0x400000.mcs
  arty_a7_ng_native_v1_t2_spi_wmem_00.bit
  report_timing_summary.rpt
  report_cdc.rpt
  vivado_build_t2.log
  flash_program.log
  bit_program.log / bit_program_r2.log
  uart_capture.txt (empty)
  uart_listen_stdout.txt (NO_MARKER bytes=0)
```
