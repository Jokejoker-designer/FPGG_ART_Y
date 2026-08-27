# E2R-CDC-RST-PROBE-00 CLOSEOUT — F1g

**Worktree:** `arty-a7-online-lm-board` ONLY  
**Agent:** `a7-vivado-gate`  
**Authority:** `STATUS/E2R_F1G_DISPATCH.md`  
**Prior:** F1e UART identical stall; F1f XSim PASS (`s_arv` in 16 `s_clk`)  
**Date:** 2026-08-26T11:16+07

## Scientific frame

| Field | Value |
|-------|-------|
| OBSERVATION | Silicon: M_ARF yes, HOLD no. Sim: same RTL presents s_arv |
| UNKNOWN | Does `m_rst_n`/`core_rst_n` or `s_rst_n`/`ui_rst_n` glitch LOW after Q_GO? |
| H_CANDIDATE | Post-Q_GO reset glitch clears AR FIFO → M_ARF without HOLD |
| H_RIVAL | Other silicon issue (clock stop, probe bug) — RST_LO stay NO |
| FALSIFIER | No RST_LO after Q_GO on UART |
| UNIT | One query boot after program |
| CONTROL | F1e UART + F1f sim PASS |
| METRICS | `M_RST_LO`, `S_RST_LO`; existing CDC_*; pred |

## ONE UNKNOWN (answered)

Does post-Q_GO `core_rst_n` or `ui_rst_n` go LOW on silicon (UART `M_RST_LO` / `S_RST_LO`)?  
**NO.** Both markers **NO**. H_CANDIDATE **falsified**. H_RIVAL remains open.

## Verdict

| Claim | Result |
|-------|--------|
| Build / timing / CDC / BRAM gates | **PASS** |
| Probe observation (`M_RST_LO` / `S_RST_LO`) | **PASS** (markers emitted path; both NO) |
| Reset-glitch hypothesis | **FAIL** (falsified) |
| Board subclass | **`CDC_INTERNAL_STUCK`** (unchanged vs F1e) |
| Existence (`pred=664`) | **FAIL** (`NO_PRED`) |

**Do not claim** existence PASS or BOARD_PASS.

## ONE CHANGE (probe only — applied)

`rtl/board/arty_a7_ng_native_v1_ab_soc_top.sv` heartbeat/sticky only:

- Sync `core_rst_n` / `ui_rst_n` into CLK100MHZ.
- After Q_GO on 100 MHz: sticky `M_RST_LO` / `S_RST_LO` if domain rst seen LOW.
- Rebuild also registered rst before sync (CDC fix from first route `unsafe_cdc=1`).

No change to `a7ng_axi_read_cdc.sv`, mux, or arready.

## Build (post-route rebuild)

| Metric | Value | Provenance | Gate |
|--------|-------|------------|------|
| maxThreads | 8 | build_stdout | OK |
| Design WNS | 1.276 ns | report_timing_summary | PASS (≥0) |
| Design TNS | 0.000 ns | post-route | PASS (=0) |
| Design WHS | 0.012 ns | post-route | PASS |
| Design THS | 0.000 ns | post-route | PASS |
| core_clk WNS | 13.736 ns | e2r_metrics | PASS |
| core_clk TNS | 0 ns | e2r_metrics | PASS |
| clk_pll_i (ui) WNS | 2.381 ns | e2r_metrics | PASS |
| clk_pll_i (ui) TNS | 0 ns | e2r_metrics | PASS |
| unsafe_cdc | 0 (mig_benign_falsepath=3 ignored) | e2r_metrics / report_cdc | PASS |
| Block RAM Tile / RAMB36 | 104 / 104 | post-route util | PASS (≤135) |
| DSP48E1 | 19 | post-route util | (info) |
| LUT | 54905 | post-route util | (info) |
| FF | 56326 | post-route util | (info) |
| SIM_FULL | 0 | generic | OK |
| gate_pass | 1 | e2r_metrics | PASS |

Bit archived: `arty_a7_ng_native_v1_cdc_rst_probe_00.bit`  
**BIT_SHA256:** `1FF2EFF404E8C6D79ADA2B993D98B03A8B0D2672DC0FC47D352F053EA4715965`

## Board program

| Item | Value |
|------|-------|
| UART arm | COM12 @115200, 180s **before** program (`capture_uart_hb.py`) |
| JTAG | `Digilent/210319BE776EA` (Arty A7-100T) |
| Program | `CDC_RST_PROBE_BIT_PROGRAM_PASS` in `bit_program.log` |
| Ports seen | COM12, COM3, COM4 |

## UART markers (board)

```
BOOT MIG_OK WMEM_OK SOA_OK CORE_START OWNER_RDY Q_GO SOA_RUN
AR_BEAT R_BUSY R_IDLE RREADY1 OUTST CDC_M_ARF CDC_S_ARR
```

| Marker | F1g | F1e (control) | Note |
|--------|-----|---------------|------|
| CDC_M_ARF | YES | YES | — |
| CDC_S_ARV | **NO** | NO | stuck |
| CDC_S_ARR | YES | YES | — |
| M_RST_LO | **NO** | n/a | new probe |
| S_RST_LO | **NO** | n/a | new probe |
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

- Falsifier fired: neither `M_RST_LO` nor `S_RST_LO` after Q_GO.
- Post-Q_GO reset glitch is **not** the silicon explanation for M_ARF without HOLD.
- Stall pattern identical to F1e control.

## Next

**F1h alternate** (both RST_LO NO): clock enable / CDC empty probe raw — **not** freeze AR FIFO rst.  
Human DECIDE on exact F1h alternate patch. Existence PASS only if `pred=664`.
