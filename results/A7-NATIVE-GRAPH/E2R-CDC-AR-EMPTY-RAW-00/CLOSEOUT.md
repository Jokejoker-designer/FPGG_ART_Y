# E2R-CDC-AR-EMPTY-RAW-00 CLOSEOUT — F1j

**Worktree:** `arty-a7-online-lm-board` ONLY  
**Agent:** `a7-vivado-gate`  
**Authority:** `STATUS/E2R_F1J_DISPATCH.md`  
**Prior:** F1i POR-only rst FAIL — UART identical to F1g  
**Date:** 2026-08-26T13:10+07

## Scientific frame

| Field | Value |
|-------|-------|
| OBSERVATION | `CDC_M_ARF=YES`, `CDC_HOLD=NO`, all CDC RTL fixes falsified; XSim PASS |
| UNKNOWN | On silicon, does AR async FIFO `ar_empty` ever deassert after M_ARF? |
| H_CANDIDATE | Write never reaches rd_clk (`AR_FIFO_NE=NO`) — true CDC silicon/XPM gap |
| H_RIVAL | FIFO has data (`AR_FIFO_NE=YES`) but `cdc_arvalid`/mux never fires — presentation bug |
| FALSIFIER | `AR_FIFO_NE=YES` on UART |
| UNIT | One query boot after program |
| CONTROL | F1i UART |
| METRICS | `AR_FIFO_NE`, `CDC_S_ARV`, `CDC_HOLD`, `pred` |

## ONE UNKNOWN (answered)

Does AR async FIFO `ar_empty` ever deassert on silicon after `CDC_M_ARF`?  
**NO.** `AR_FIFO_NE=NO` — registered `ar_empty` stays asserted on rd_clk. H_CANDIDATE **supported**. H_RIVAL **falsified**.

## Verdict

| Claim | Result |
|-------|--------|
| Build / timing / CDC / BRAM gates | **PASS** |
| AR write reaches rd_clk (H_RIVAL) | **FAIL** (falsified) |
| AR write stuck at wr_clk (H_CANDIDATE) | **SUPPORTED** |
| Board subclass | **`AR_WRITE_NEVER_RD_CLK`** |
| Existence (`pred=664`) | **FAIL** (`NO_PRED`) |

**Do not claim** existence PASS or BOARD_PASS.

## ONE CHANGE (applied, probe only)

1. `a7ng_axi_read_cdc.sv`: `dbg_ar_empty_o` = registered `ar_empty` on `s_clk`.
2. `arty_a7_ng_native_v1_ab_soc_top.sv`: sticky `AR_FIFO_NE` if `!dbg_ar_empty_o` after `sticky_qgo_ui`; UART marker after `CDC_S_ARR`.

FIFO rst, FWFT, mux, arready unchanged.

## Build (post-route)

| Metric | Value | Provenance | Gate |
|--------|-------|------------|------|
| maxThreads | 8 | build_stdout | OK |
| Design WNS | 1.276 ns | report_timing_summary | PASS (≥0) |
| Design TNS | 0.000 ns | post-route | PASS (=0) |
| Design WHS | 0.007 ns | post-route | PASS |
| Design THS | 0.000 ns | post-route | PASS |
| core_clk WNS | 10.710 ns | e2r_metrics | PASS |
| core_clk TNS | 0 ns | e2r_metrics | PASS |
| clk_pll_i (ui) WNS | 1.729 ns | e2r_metrics | PASS |
| clk_pll_i (ui) TNS | 0 ns | e2r_metrics | PASS |
| unsafe_cdc | 0 (mig_benign_falsepath=3 ignored) | e2r_metrics / report_cdc | PASS |
| Block RAM Tile / RAMB36 | 104 / 104 | post-route util | PASS (≤135) |
| DSP48E1 | 19 | post-route util | (info) |
| gate_pass | 1 | e2r_metrics | PASS |

Bit archived: `arty_a7_ng_native_v1_cdc_ar_empty_raw_00.bit`  
**BIT_SHA256:** `B732E7887A1C84E60F4BA9906EEA00B1C2FBADFF9EDBB2603590998E2C1EBD07`

## Board program

| Item | Value |
|------|-------|
| UART arm | COM12 @115200, 180s **before** program (`capture_uart_hb.py`) |
| JTAG | `Digilent/210319BE776EA` (Arty A7-100T) |
| Program | `CDC_AR_POR_RST_BIT_PROGRAM_PASS` in `bit_program.log` |
| Ports seen | COM12, COM3, COM4 |

## UART markers (board)

```
BOOT MIG_OK WMEM_OK SOA_OK CORE_START OWNER_RDY Q_GO SOA_RUN
AR_BEAT R_BUSY R_IDLE RREADY1 OUTST CDC_M_ARF CDC_S_ARR
```

| Marker | F1j | F1i (control) | Note |
|--------|-----|---------------|------|
| CDC_M_ARF | YES | YES | m-side fire confirmed |
| **AR_FIFO_NE** | **NO** | (n/a) | **new probe — empty stays asserted** |
| CDC_S_ARV | NO | NO | stuck |
| CDC_S_ARR | YES | YES | arready seen |
| M_RST_LO | NO | NO | probe retained |
| S_RST_LO | NO | NO | probe retained |
| CDC_S_ARF | NO | NO | — |
| CDC_HOLD | NO | NO | — |
| MIG_AR | NO | NO | — |
| pred | NO_PRED | NO_PRED | FAIL |

**STALL_CLASS:** `H_CANDIDATE`  
**STALL_SUBCLASS:** `AR_WRITE_NEVER_RD_CLK`  
**BYTES:** 117  
**Artifact:** `uart_capture.txt` (+ `uart_capture.log` summary)

## Hypothesis result

- Falsifier **not** fired: `AR_FIFO_NE` never asserted → beat does not appear on rd_clk.
- H_RIVAL (presentation/mux bug with data present) **falsified**.
- H_CANDIDATE (XPM async FIFO gray-pointer / CDC silicon gap) **supported**.
- `CDC_S_ARV=NO` is consistent with empty FIFO on s_clk, not a separate mux defect.

## Next

**F1k (DECIDE):** XPM CDC depth/sync stages or bypass experiment — AR write not crossing to rd_clk on silicon. Existence PASS only if `pred=664`.
