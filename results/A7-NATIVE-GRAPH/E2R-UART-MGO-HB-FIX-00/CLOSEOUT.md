# E2R F1w CLOSEOUT — E2R-UART-MGO-HB-FIX-00

**Date:** 2026-08-27  
**Agent:** a7-vivado-gate  
**Gate:** E2R-UART-MGO-HB-FIX-00 (F1w)  
**Build path:** exclusive `E2R-UART-MGO-HB-FIX-00-EXCL` (concurrent resume voided; same RTL)

## Scientific frame

| Item | Value |
|------|-------|
| OBSERVATION | F1v: OWNER=1 GRANT=0 RPATH_IDLE=0; MGO missing; BOOT flood after RPATH_IDLE |
| UNKNOWN | MGO absent = no m_go vs UART HB stuck before msg 64 |
| H_CANDIDATE | `6'd64` truncates to BOOT (Synth 8-10929) → msg 64 aliases BOOT / loops |
| H_RIVAL | m_go never sticky |
| ONE CHANGE | UART HB only: `7'd64` in `hb_char`/`hb_len`; refuse BOOT retransmit after `sent_mask[0]` |
| CONTROL | F1v BIT `6DA35A623B185592D07DB19D82EEC2009F82E9DB77714C49AC9B1CC402E47534` |

## GATE (post-route — board provenance)

| Metric | Value | Verdict |
|--------|-------|---------|
| core_WNS | 9.150 ns | **PASS** (≥0) |
| core_TNS | 0 | **PASS** |
| ui_WNS | 2.089 ns | **PASS** |
| ui_TNS | 0 | **PASS** |
| unsafe_cdc | 0 | **PASS** |
| RAMB36 | 103 | **PASS** (≤135) |
| DSP | 19 | note |
| Synth 8-10929 (`6'd64`) | **0** | **PASS** (absent) |
| gate_pass | 1 | **PASS** |

## BIT / PROGRAM

| Item | Value |
|------|-------|
| BIT_SHA256 | `4933B19BCC6C06603979896565E31DCD9703AFF7FD99EA8CD564DA0E659C25D6` |
| Bit file | `E2R-UART-MGO-HB-FIX-00-EXCL/arty_a7_ng_native_v1_uart_mgo_hb_fix_00_excl.bit` (+ copy in this dir) |
| SOC_TOP_SHA256 | see `SOC_TOP_SHA256.txt` |
| JTAG | `210319BE776EA` |
| COM | COM12 @115200 |
| PROGRAM | **PASS** (`UART_MGO_HB_FIX_EXCL_BIT_PROGRAM_PASS`) |
| Arm | UART capture armed **before** program |

## UART probe (board)

| Marker | Value |
|--------|-------|
| TILE_DST | **4** |
| DMA_ST | **0** |
| SGO | **0** |
| WDMA_OWNER | **1** |
| WDMA_GRANT | **0** |
| RPATH_IDLE | **0** |
| MGO | **1** |
| BOOT after probe | **NO** (1× BOOT at start only; 59 lines total) |
| pred | **NO** |

## Hypothesis result

| Hypothesis | Result |
|------------|--------|
| H_CANDIDATE (UART HB 6'd64 truncation) | **SUPPORTED** — `MGO=1` prints; no BOOT flood |
| H_RIVAL (m_go never sticky) | **FALSIFIED** — `MGO=1` |

## Classification (EXCL dispatch)

| Class | Match |
|-------|-------|
| **B** MGO=1 SGO=0 | **YES** — next = WDMA cmd-CDC (cmd_wr_en/full/empty/rd_en/pend/s_go_r); no B1 edit |

## Verdict

| Check | Result |
|-------|--------|
| PROBE_PASS | **YES** — MGO=0\|1 present + triad + no BOOT flood |
| EXISTENCE_PASS | **NO** — pred≠664 |
| GATE | **PASS** (timing/CDC/BRAM) |

## NEXT

**F1x / Class B:** WDMA cmd-CDC unit probe (`s_go` path) — why `MGO=1` but `SGO=0` / `DMA_ST=0`. Do **not** change B1 grant / `r_path_idle` yet.

## Artifacts

- `uart_capture.txt`
- `capture_stdout.log`
- `program_stdout.log`
- `BIT_SHA256.txt` / `e2r_metrics.txt`
- `arty_a7_ng_native_v1_uart_mgo_hb_fix_00.bit`
- Exclusive build logs under `../E2R-UART-MGO-HB-FIX-00-EXCL/`
