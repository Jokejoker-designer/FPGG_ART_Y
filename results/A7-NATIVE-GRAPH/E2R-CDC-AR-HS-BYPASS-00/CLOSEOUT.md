# E2R-CDC-AR-HS-BYPASS-00 CLOSEOUT — F1k

**Worktree:** `arty-a7-online-lm-board` ONLY  
**Agent:** `a7-vivado-gate`  
**Authority:** `STATUS/E2R_F1K_DISPATCH.md`  
**Prior:** F1j — `AR_FIFO_NE=NO`, `CDC_M_ARF=YES` (write never reaches rd_clk)  
**Date:** 2026-08-26T14:16+07

## Scientific frame

| Field | Value |
|-------|-------|
| OBSERVATION | XPM `xpm_fifo_async` AR: master handshake yes, `ar_empty` never clears on s_clk |
| UNKNOWN | Does replacing AR XPM async FIFO with `xpm_cdc_handshake` restore `CDC_S_ARV` / `AR_FIFO_NE` / `pred=664`? |
| H_CANDIDATE | XPM AR async FIFO gray/CDC fails on this silicon; handshake CDC works |
| H_RIVAL | Broader SoC/clock issue — handshake also stuck |
| FALSIFIER | Still `CDC_S_ARV=NO` and no AR-empty-clear after F1k |
| UNIT | One query boot after program |
| CONTROL | F1j UART + bit `B732E788…` |
| METRICS | `AR_FIFO_NE`, `CDC_S_ARV`, `CDC_HOLD`, `MIG_AR`, `R_BEAT`, `pred=664`; unsafe_cdc=0; WNS≥0 |

## ONE UNKNOWN (answered)

Does AR `xpm_cdc_handshake` restore `CDC_S_ARV` / empty-clear on silicon?  
**YES for CDC path.** `CDC_S_ARV=YES`, `CDC_HOLD=YES`, `MIG_AR=YES`; sticky empty-clear printed (UART string `AR_FIFFO_NE` — pre-existing ROM typo for `AR_FIFO_NE`). H_CANDIDATE **supported**. Falsifier **fired false**. Existence (`pred=664`) **not** restored (`NO_PRED`, last stage `LM`).

## Verdict

| Claim | Result |
|-------|--------|
| Narrow XSim (s_arv ≤50 s_clk) | **PASS** (`s_cycles_after_m=14`) |
| Build / timing / CDC / BRAM gates | **PASS** |
| Handshake restores AR CDC (`CDC_S_ARV` / empty-clear) | **PASS** |
| Existence (`pred=664`) | **FAIL** (`NO_PRED`) |
| Overall gate | **FAIL** (existence required for PASS claim) |

**Do not claim** existence PASS or BOARD_PASS.

## ONE CHANGE (applied)

`rtl/board/a7ng_axi_read_cdc.sv` AR path only:

- Removed `u_ar_fifo` (`xpm_fifo_async`) + F1i POR AR FIFO rst.
- 47-bit `{arburst,arsize,arid,arlen,araddr}` via `xpm_cdc_handshake` (DEST_EXT_HSK=1, sync FF=3, 1 outstanding).
- R path XPM async FIFO unchanged.
- Probes: `dbg_ar_empty_o` = !payload-pending-on-s; `dbg_ar_ne_o` / `dbg_ar_hold_o` = s-side valid hold.
- Top UART / mux / markers unchanged (ROM still spells `AR_FIFFO_NE`).

CDC RTL SHA256: `AF3EDB1ACD9DF1EA1B52C5B7E06F5C0799AB8E65813A74CB5037FBB18C032B45`  
SOC top SHA256: `C1842761A08B1E35F0886822C29A32B2FEE3FBB527AE0A35A8EC640C11BE8A35` (unchanged this gate)

## Narrow XSim

| Metric | Value | Provenance | Gate |
|--------|-------|------------|------|
| Marker | `E2R_CDC_AR_HS_XSIM_PASS` | xsim_stdout.txt | PASS |
| s_cycles_after_m | 14 | SUMMARY | PASS (≤50) |
| addr | `0001000` | S_ARVALID | OK |

## Build (post-route)

| Metric | Value | Provenance | Gate |
|--------|-------|------------|------|
| maxThreads | 8 | build_stdout | OK |
| Design WNS | 1.196 ns | report_timing_summary | PASS (≥0) |
| Design TNS | 0.000 ns | post-route | PASS (=0) |
| Design WHS | 0.008 ns | post-route | PASS |
| Design THS | 0.000 ns | post-route | PASS |
| core_clk WNS | 11.660 ns | e2r_metrics | PASS |
| core_clk TNS | 0 | e2r_metrics | PASS |
| clk_pll_i (ui) WNS | 2.654 ns | e2r_metrics | PASS |
| clk_pll_i (ui) TNS | 0 | e2r_metrics | PASS |
| unsafe_cdc | 0 | e2r_metrics / report_cdc | PASS |
| Block RAM Tile / RAMB36 | 103 / 103 | post-route util | PASS (≤135) |
| DSP48E1 | 19 | post-route util | (info) |
| gate_pass | 1 | e2r_metrics | PASS |

Bit archived: `arty_a7_ng_native_v1_cdc_ar_hs_bypass_00.bit`  
**BIT_SHA256:** `C95316F847DB2C63C3818E29F818398E243160F127217D7E6D3F10FF16CC99A6`

## Board program

| Item | Value |
|------|-------|
| UART arm | COM12 @115200, 180s **before** program (`capture_uart_hb.py`) |
| JTAG | `Digilent/210319BE776EA` (Arty A7-100T) |
| Program | `CDC_AR_HS_BYPASS_BIT_PROGRAM_PASS` in program_stdout / bit_program.log |
| Ports seen | COM12, COM3, COM4 |

## UART markers (board)

```
BOOT MIG_OK WMEM_OK SOA_OK CORE_START OWNER_RDY Q_GO SOA_RUN
AR_BEAT R_BEAT R_BUSY R_IDLE RV_SEEN RREADY1 RID_OK RID_BAD OUTST
MIG_RV CDC_NE MIG_AR OWN_WDMA CDC_AR MUX_CDC
CDC_M_ARF CDC_S_ARV CDC_S_ARR AR_FIFFO_NE CDC_S_ARF CDC_HOLD
SOA_Q TOPK ACCEPT PACK FWD LM
```

| Marker | Value | Notes |
|--------|-------|-------|
| **AR_FIFO_NE** | **YES*** | UART printed `AR_FIFFO_NE` (ROM typo F1j); sticky `!cdc_ar_empty` fired |
| **CDC_S_ARV** | **YES** | restored vs F1j NO |
| **CDC_S_ARR** | **YES** | |
| **CDC_HOLD** | **YES** | restored vs F1j NO |
| **MIG_AR** | **YES** | |
| **R_BEAT** | **YES** | |
| **CDC_M_ARF** | **YES** | |
| **pred** | **NO_PRED** | stopped at LM; no BIND line |

\*Capture script exact-match `AR_FIFO_NE` → printed NO; board evidence is the `AR_FIFFO_NE` line.

## vs F1j control

| | F1j | F1k |
|--|-----|-----|
| CDC_S_ARV | NO | **YES** |
| AR empty-clear sticky | NO | **YES** (`AR_FIFFO_NE`) |
| CDC_HOLD | NO | **YES** |
| MIG_AR | NO | **YES** |
| Last stage | ~CDC_S_ARR | **LM** |
| pred | NO_PRED | NO_PRED |

## NEXT

AR async-FIFO silicon gap **bypassed** by handshake. Remaining unknown: boot reaches `LM` but no `BIND`/`pred=664`. Do not claim existence PASS. Next DECIDE: post-AR path after LM (BIND/PRED), and optional UART ROM typo fix (`AR_FIFFO_NE`→`AR_FIFO_NE`) as separate probe-only gate.
