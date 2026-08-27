# E2R-CDC-AR-POR-RST-00 CLOSEOUT — F1i

**Worktree:** `arty-a7-online-lm-board` ONLY  
**Agent:** `a7-vivado-gate`  
**Authority:** `STATUS/E2R_F1I_DISPATCH.md`  
**Prior:** F1g RST_LO NO; F1h board-seq XSim PASS  
**Date:** 2026-08-26T12:19+07

## Scientific frame

| Field | Value |
|-------|-------|
| OBSERVATION | Isolated CDC OK in XSim; board M_ARF without HOLD; no post-Q_GO rst LO |
| UNKNOWN | Does live `!(m_rst_n&&s_rst_n)` on AR FIFO leave XPM gray pointers wedged on silicon? |
| H_CANDIDATE | POR-only AR FIFO reset restores `CDC_HOLD`/`CDC_S_ARV` |
| H_RIVAL | SoC mux/other — POR-only still stuck |
| FALSIFIER | UART still CDC_HOLD=NO after F1i |
| UNIT | One query boot after program |
| CONTROL | F1g UART |
| METRICS | CDC_HOLD, CDC_S_ARV, MIG_AR, pred |

## ONE UNKNOWN (answered)

Does POR-only AR FIFO reset restore `CDC_S_ARV` and `CDC_HOLD` on silicon?  
**NO.** Both markers **NO**. H_CANDIDATE **falsified**. H_RIVAL remains open.

## Verdict

| Claim | Result |
|-------|--------|
| Build / timing / CDC / BRAM gates | **PASS** |
| POR-only AR FIFO reset hypothesis | **FAIL** (falsified) |
| Board subclass | **`CDC_INTERNAL_STUCK`** (unchanged vs F1g) |
| Existence (`pred=664`) | **FAIL** (`NO_PRED`) |

**Do not claim** existence PASS or BOARD_PASS.

## ONE CHANGE (applied)

`rtl/board/a7ng_axi_read_cdc.sv` AR FIFO only:

- Added POR counter on `m_clk`: assert `ar_fifo_rst` while either domain in reset or until both `m_rst_n` and `s_rst_n` high for ≥16 `m_clk` cycles.
- After release, `ar_fifo_rst` held at 0 forever (ignores later domain rst).
- Replaced `.rst(!(m_rst_n && s_rst_n))` with `.rst(ar_fifo_rst)`.
- R FIFO / AR FWFT direct presentation unchanged.

## Build (post-route)

| Metric | Value | Provenance | Gate |
|--------|-------|------------|------|
| maxThreads | 8 | build_stdout | OK |
| Design WNS | 1.276 ns | report_timing_summary | PASS (≥0) |
| Design TNS | 0.000 ns | post-route | PASS (=0) |
| Design WHS | 0.008 ns | post-route | PASS |
| Design THS | 0.000 ns | post-route | PASS |
| core_clk WNS | 11.203 ns | e2r_metrics | PASS |
| core_clk TNS | 0 ns | e2r_metrics | PASS |
| clk_pll_i (ui) WNS | 2.326 ns | e2r_metrics | PASS |
| clk_pll_i (ui) TNS | 0 ns | e2r_metrics | PASS |
| unsafe_cdc | 0 (mig_benign_falsepath=3 ignored) | e2r_metrics / report_cdc | PASS |
| Block RAM Tile / RAMB36 | 104 / 104 | post-route util | PASS (≤135) |
| DSP48E1 | 19 | post-route util | (info) |
| LUT | 54907 | post-route util | (info) |
| FF | 56332 | post-route util | (info) |
| SIM_FULL | 0 | generic | OK |
| gate_pass | 1 | e2r_metrics | PASS |

Bit archived: `arty_a7_ng_native_v1_cdc_ar_por_rst_00.bit`  
**BIT_SHA256:** `36E3D2F995BD1F9DD543F0F6C7FF92F01876F27C61BF191AE919F1A6B279A970`

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

| Marker | F1i | F1g (control) | Note |
|--------|-----|---------------|------|
| CDC_M_ARF | YES | YES | — |
| CDC_S_ARV | **NO** | NO | stuck |
| CDC_S_ARR | YES | YES | — |
| M_RST_LO | NO | NO | probe retained |
| S_RST_LO | NO | NO | probe retained |
| CDC_S_ARF | NO | NO | — |
| CDC_HOLD | **NO** | NO | — |
| MIG_AR | NO | NO | — |
| R_BEAT | NO | NO | — |
| pred | NO_PRED | NO_PRED | FAIL |

**STALL_CLASS:** `AXI_MIG_AR_PATH`  
**STALL_SUBCLASS:** `CDC_INTERNAL_STUCK`  
**BYTES:** 117  
**Artifact:** `uart_capture.txt` (+ `uart_capture.log` summary)

## Hypothesis result

- Falsifier fired: `CDC_S_ARV` and `CDC_HOLD` still NO after POR-only AR FIFO reset.
- Live domain-rst coupling on AR FIFO is **not** the silicon explanation for M_ARF without HOLD.
- Stall pattern identical to F1g control.

## Next

**H_RIVAL** path: SoC mux / MIG ui bind / clock stop / XPM silicon behavior — not another AR FIFO rst variant without new sealed unknown. Human DECIDE on F1j alternate. Existence PASS only if `pred=664`.
