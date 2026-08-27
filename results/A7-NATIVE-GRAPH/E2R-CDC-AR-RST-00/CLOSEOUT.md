# E2R-CDC-AR-RST-00 CLOSEOUT — HUMAN_F1C

**Worktree:** `arty-a7-online-lm-board` ONLY  
**Agent:** a7-vivado-gate  
**Authority:** `STATUS/E2R_F1C_DISPATCH.md`  
**Prior F1d:** E2R-CDC-ARREADY-MIG-00 / `CDC_INTERNAL_STUCK`  
**Date:** 2026-08-26T06:38+07

## Ack

`HUMAN_F1C` — ONE change: AR FIFO dual-domain reset `!(m_rst_n && s_rst_n)`.

## Scientific frame

| Field | Value |
|-------|-------|
| OBSERVATION | F1d: `CDC_M_ARF=YES`, `CDC_HOLD=NO`, `CDC_S_ARV=NO` (AR FIFO write without s_clk drain) |
| UNKNOWN | Does AR async FIFO reset tied only to `m_rst_n` leave read-side stuck empty after ui-domain reset? |
| H_CANDIDATE | AR FIFO `.rst = !(m_rst_n && s_rst_n)` (both domains out of reset) |
| H_RIVAL | FWFT FSM bug unrelated to reset |
| FALSIFIER | `CDC_HOLD` still NO after fix |
| UNIT | One AR beat visible on s_clk |
| CONTROL | F1d bit `38C12831…` UART baseline |

## ONE UNKNOWN (answered)

Does dual-domain AR FIFO reset restore `CDC_HOLD` / `CDC_S_ARV` → `MIG_AR` / `pred=664`?  
**NO.** F1c **falsified** on board. UART trace **identical** to F1d stall.

## Verdict

| Claim | Result |
|-------|--------|
| Build / timing / CDC / BRAM gates | **PASS** |
| F1c functional (CDC_HOLD / CDC_S_ARV restored) | **FAIL** |
| Board subclass | **`CDC_INTERNAL_STUCK`** (unchanged) |
| Existence (`pred=664`) | **FAIL** (`NO_PRED`) |

**Do not claim** existence PASS or full BOARD_PASS. **Recommend F1e** (FWFT FSM / empty-drain rival).

## ONE CHANGE (applied)

`rtl/board/a7ng_axi_read_cdc.sv` SHA256=`8ED249AE170E2872F8E808BCB9BE3B4F22D030C64B477E2AC1DDE5CFEA5FCA85`

```systemverilog
// Before (F1d):
.rst(!m_rst_n),
// After (F1c):
.rst(!(m_rst_n && s_rst_n)),
```

`u_ar_fifo` only. R FIFO, FWFT FSM, top.sv unchanged.

## Build (post-route)

| Metric | Value | Provenance | Gate |
|--------|-------|------------|------|
| maxThreads | 8 | build_stdout | OK |
| Design WNS | 0.738 ns | report_timing_summary | PASS (≥0) |
| Design TNS | 0.000 ns | post-route | PASS (=0) |
| Design WHS | 0.021 ns | post-route | PASS |
| Design THS | 0.000 ns | post-route | PASS |
| core_clk WNS | 6.745 ns | e2r_metrics | PASS |
| core_clk TNS | 0 ns | e2r_metrics | PASS |
| clk_pll_i (ui) WNS | 2.594 ns | e2r_metrics | PASS |
| clk_pll_i (ui) TNS | 0 ns | e2r_metrics | PASS |
| unsafe_cdc | 0 | e2r_metrics / report_cdc | PASS |
| Block RAM Tile / RAMB36 | 104 / 104 | post-route util | PASS (≤135) |
| DSP48E1 | 19 | post-route util | (info) |
| LUT | 54888 | post-route util | (info) |
| FF | 56357 | post-route util | (info) |
| SIM_FULL | 0 | generic | OK |
| gate_pass | 1 | e2r_metrics | PASS |

Bit archived: `arty_a7_ng_native_v1_cdc_ar_rst_00.bit`  
**BIT_SHA256:** `F0D86DC6686D2C34FB263B813F72FE24C54D8B7F241D24ED08786801723EB9D7`

## Board program

| Item | Value |
|------|-------|
| UART arm | COM12 @115200, 180s **before** program |
| JTAG | `Digilent/210319BE776EA` (Arty A7-100T) |
| Program | `CDC_AR_RST_BIT_PROGRAM_PASS` in `bit_program.log` |
| Ports seen | COM12,COM3,COM4 |

## UART markers (board)

```
BOOT MIG_OK WMEM_OK SOA_OK CORE_START OWNER_RDY Q_GO SOA_RUN
AR_BEAT R_BUSY R_IDLE RREADY1 OUTST CDC_M_ARF CDC_S_ARR
```

| Marker | F1c | F1d (control) | Gate |
|--------|-----|---------------|------|
| CDC_M_ARF | YES | YES | — |
| CDC_S_ARV | **NO** | NO | **FAIL** |
| CDC_S_ARR | YES | YES | — |
| CDC_S_ARF | NO | NO | — |
| CDC_HOLD | **NO** | NO | **FAIL** (falsifier) |
| MIG_AR | NO | NO | **FAIL** |
| R_BEAT | NO | NO | **FAIL** |
| pred | NO_PRED | NO_PRED | **FAIL** |

**STALL_CLASS:** `AXI_MIG_AR_PATH`  
**STALL_SUBCLASS:** `CDC_INTERNAL_STUCK`

## F1c vs F1d delta

No functional delta on board. Dual-domain AR FIFO reset does not unstick read-side occupancy or `cdc_arvalid`.

## Next

**F1e candidate:** FWFT FSM / `s_ar_hold` drain logic (H_RIVAL). Human DECIDE required.
