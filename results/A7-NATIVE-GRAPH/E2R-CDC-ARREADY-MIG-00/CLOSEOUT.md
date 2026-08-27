# E2R-CDC-ARREADY-MIG-00 CLOSEOUT — HUMAN_F1D

**Worktree:** `arty-a7-online-lm-board` ONLY  
**Agent:** a7-vivado-gate  
**Authority:** `STATUS/E2R_F1D_DISPATCH.md`  
**Prior F1b:** E2R-CDC-HOLD-RST-00 / `CDC_INTERNAL_STUCK`  
**Date:** 2026-08-26T05:43+07

## Ack

`HUMAN_F1D` — ONE change: wire `cdc_arready` to real MIG `arready` when CDC owns AR mux.

## Scientific frame

| Field | Value |
|-------|-------|
| OBSERVATION | F1a/F1b: `CDC_M_ARF=YES`, `CDC_S_ARR=YES`, `CDC_S_ARV=NO`, `MIG_AR=NO`, no pred |
| UNKNOWN | Does fake `cdc_arready` block real MIG AR handshake? |
| H_CANDIDATE | `cdc_arready = !boot_active && !wdma_owner_ui && arready` |
| H_RIVAL | AR FIFO never drains on s_clk / FWFT FSM bug (F1c) |
| FALSIFIER | UART still `CDC_S_ARV=NO` after F1d |
| UNIT | One MIG AR handshake |
| CONTROL | F1b bit `D57E6A51…` UART baseline |

## ONE UNKNOWN (answered)

Does wiring `cdc_arready` to real MIG `arready` restore `CDC_S_ARV` / `MIG_AR` / `pred=664`?  
**NO.** F1d **falsified** on board. UART trace **identical** to F1a/F1b stall.

## Verdict

| Claim | Result |
|-------|--------|
| Build / timing / CDC / BRAM gates | **PASS** |
| F1d functional (CDC_S_ARV restored) | **FAIL** |
| Board subclass | **`CDC_INTERNAL_STUCK`** (unchanged) |
| Existence (`pred=664`) | **FAIL** (`NO_PRED`) |

**Do not claim** existence PASS or full BOARD_PASS. **Recommend F1c** (AR FIFO dual-domain reset / empty sticky).

## ONE CHANGE (applied)

`rtl/board/arty_a7_ng_native_v1_ab_soc_top.sv` SHA256=`3A849CFFC82B8FBA9FC5B2ED21FACA5C6CDFDEA32A56E31567D8CAA68C0B522B`

```systemverilog
// Before (F1b):
assign cdc_arready = !boot_active && !wdma_owner_ui;
// After (F1d):
assign cdc_arready = !boot_active && !wdma_owner_ui && arready;
```

`a7ng_axi_read_cdc.sv` unchanged from F1a/F1b.

## Build (post-route)

| Metric | Value | Provenance | Gate |
|--------|-------|------------|------|
| maxThreads | 8 | build_stdout | OK |
| Design WNS | 0.768 ns | report_timing_summary | PASS (≥0) |
| Design TNS | 0.000 ns | post-route | PASS (=0) |
| Design WHS | 0.022 ns | post-route | PASS |
| Design THS | 0.000 ns | post-route | PASS |
| core_clk WNS | 5.817 ns | e2r_metrics | PASS |
| core_clk TNS | 0 ns | e2r_metrics | PASS |
| clk_pll_i (ui) WNS | 2.783 ns | e2r_metrics | PASS |
| clk_pll_i (ui) TNS | 0 ns | e2r_metrics | PASS |
| unsafe_cdc | 0 | e2r_metrics / report_cdc | PASS |
| Block RAM Tile / RAMB36 | 104 / 104 | post-route util | PASS (≤135) |
| DSP48E1 | 19 | post-route util | (info) |
| SIM_FULL | 0 | generic | OK |
| gate_pass | 1 | e2r_metrics | PASS |

Bit archived: `arty_a7_ng_native_v1_cdc_arready_mig_00.bit`  
**BIT_SHA256:** `38C12831FCD1A2825B609AF55E1193007E8571636C04DF38855C3D2C868394EA`

## Board program

| Item | Value |
|------|-------|
| UART arm | COM12 @115200, 180s **before** program |
| JTAG | `Digilent/210319BE776EA` (Arty A7-100T) |
| Program | `CDC_ARREADY_MIG_BIT_PROGRAM_PASS` in `bit_program.log` |
| Ports seen | COM12,COM3,COM4 |

## UART markers (board)

```
BOOT MIG_OK WMEM_OK SOA_OK CORE_START OWNER_RDY Q_GO SOA_RUN
AR_BEAT R_BUSY R_IDLE RREADY1 OUTST CDC_M_ARF CDC_S_ARR
```

| Marker | F1d | F1b (control) | Gate |
|--------|-----|---------------|------|
| CDC_M_ARF | YES | YES | — |
| CDC_S_ARV | **NO** | NO | **FAIL** |
| CDC_S_ARR | YES | YES | — |
| CDC_S_ARF | NO | NO | — |
| CDC_HOLD | NO | NO | — |
| MIG_AR | NO | NO | **FAIL** |
| R_BEAT | NO | NO | **FAIL** |
| pred | NO_PRED | NO_PRED | **FAIL** |

**STALL_CLASS:** `AXI_MIG_AR_PATH`  
**STALL_SUBCLASS:** `CDC_INTERNAL_STUCK`

## F1d vs F1b delta

No functional delta on board. Fake `cdc_arready` was not the root cause; real MIG `arready` gating does not unstick AR slave valid.

## Next

**F1c candidate:** AR FIFO reset in both domains / empty-sticky CDC fix. Human DECIDE required.
