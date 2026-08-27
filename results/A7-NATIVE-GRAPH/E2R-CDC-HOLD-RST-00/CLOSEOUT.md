# E2R-CDC-HOLD-RST-00 CLOSEOUT — HUMAN_F1B

**Worktree:** `arty-a7-online-lm-board` ONLY  
**Agent:** a7-vivado-gate  
**Authority:** `STATUS/E2R_F1B_DISPATCH.md`  
**Prior F1a:** E2R-CDC-AR-FIX-00 / `CDC_INTERNAL_STUCK`  
**Date:** 2026-08-26T04:48+07

## Ack

`HUMAN_F1B` — ONE change: `u_axi_cdc.m_rst_n = core_rst_n` (remove `&& !core_hold`). FWFT CDC RTL retained from F1a.

## ONE UNKNOWN (answered)

Does removing `core_hold` from CDC master reset restore `CDC_S_ARV` / MIG_AR / pred=664?  
**NO.** F1b **falsified** on board. UART trace **identical** to F1a stall.

## Verdict

| Claim | Result |
|-------|--------|
| Build / timing / CDC / BRAM gates | **PASS** |
| F1b functional (CDC_S_ARV restored) | **FAIL** |
| Board subclass | **`CDC_INTERNAL_STUCK`** (unchanged) |
| Existence (`pred=664`) | **FAIL** (`NO_PRED`) |

**Do not claim** existence PASS or full BOARD_PASS. **DECIDE F1c** next (AR FIFO dual-domain reset / empty sticky). Do not stack F1c silently.

## ONE CHANGE (applied)

`rtl/board/arty_a7_ng_native_v1_ab_soc_top.sv` SHA256=`623DC613374F3F8D34606B3F07654F45808011C209CC0597D9C55A7AA1D84900`

```systemverilog
// Before (F1a):
.m_rst_n(core_rst_n && !core_hold),
// After (F1b):
.m_rst_n(core_rst_n),
```

FWFT `a7ng_axi_read_cdc.sv` unchanged from F1a.

## Build (post-route)

| Metric | Value | Provenance | Gate |
|--------|-------|------------|------|
| maxThreads | 8 | build_stdout | OK |
| Design WNS | 1.092 ns | report_timing_summary | PASS (≥0) |
| Design TNS | 0.000 ns | post-route | PASS (=0) |
| Design WHS | 0.013 ns | post-route | PASS |
| Design THS | 0.000 ns | post-route | PASS |
| core_clk WNS | 10.275 ns | e2r_metrics | PASS |
| core_clk TNS | 0 ns | e2r_metrics | PASS |
| clk_pll_i (ui) WNS | 2.243 ns | e2r_metrics | PASS |
| clk_pll_i (ui) TNS | 0 ns | e2r_metrics | PASS |
| unsafe_cdc | 0 | e2r_metrics / report_cdc | PASS |
| Block RAM Tile / RAMB36 | 104 / 104 | post-route util | PASS (≤135) |
| DSP48E1 | 19 | post-route util | (info) |
| SIM_FULL | 0 | generic | OK |
| gate_pass | 1 | e2r_metrics | PASS |

Bit archived: `arty_a7_ng_native_v1_cdc_hold_rst_00.bit`  
**BIT_SHA256:** `D57E6A51DF0DC939159EF985466667BC214AC5E105AC5EC8AF4004AC67FD6A9B`

## Board program

| Item | Value |
|------|-------|
| UART arm | COM12 @115200, 180s **before** program |
| JTAG | `Digilent/210319BE776EA` (Arty A7-100T) |
| Program | `CDC_HOLD_RST_BIT_PROGRAM_PASS` in `bit_program.log` |
| Ports seen | COM12,COM3,COM4 |

## UART markers (board)

```
BOOT MIG_OK WMEM_OK SOA_OK CORE_START OWNER_RDY Q_GO SOA_RUN
AR_BEAT R_BUSY R_IDLE RREADY1 OUTST CDC_M_ARF CDC_S_ARR
```

| Marker | F1b | F1a (prior) | Gate |
|--------|-----|-------------|------|
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

## F1b vs F1a delta

No functional delta on board. `core_hold` was already 0 during QS_WAIT_SOA (latent-only hypothesis confirmed). Severing `core_hold` from CDC `m_rst_n` does not unstick AR slave valid.

## Next

**F1c candidate:** AR FIFO reset in both domains / empty-sticky CDC fix. Human DECIDE required.
