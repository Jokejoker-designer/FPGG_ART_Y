# E2R-HB-CDC-AR-00 PREREGISTER — HUMAN_E3

**Worktree:** `arty-a7-online-lm-board` ONLY  
**Authority:** `results/A7-NATIVE-GRAPH/STATUS/E2R_E3_CDC_DISPATCH.md`  
**Prior:** E2R-HB-MIG-AR-00 CASE A — AR_BEAT=YES, MIG_AR/CDC_AR=NO, OWN_WDMA=NO

## ONE UNKNOWN

Core accepted AR into CDC (`AR_BEAT`) but after Q_GO `cdc_arvalid` never sticky — stuck inside CDC vs `cdc_arready` starve?

## H_CANDIDATE / H_RIVAL

- H_CANDIDATE: AR stuck **inside** `a7ng_axi_read_cdc` (master fire, slave never presents).
- H_RIVAL: `cdc_arready` starve (mux/boot/WDMA) so slave AR cannot complete.

## FALSIFIER

UART sticky after Q_GO: `CDC_M_ARF`, `CDC_S_ARV`, `CDC_S_ARR`, `CDC_S_ARF`, `CDC_HOLD` (+ retained D1–D4).

| Pattern | Class |
|---------|-------|
| M_ARF=1, S_ARV=0 forever | `CDC_INTERNAL_STUCK` |
| S_ARV=1, S_ARR=0 | `CDC_READY_STARVE` |
| S_ARF=1, MIG_AR=0 | `MUX_AFTER_CDC` |
| M_ARF=0 after Q_GO | `AR_BEAT_PRE_QGO` |
| else | `UNKNOWN` |

## CONTROL / METRICS

- Control: D1–D4 heartbeats retained; no B1 re-patch; no host weight poke; no R6; no functional fix.
- Gates: maxThreads 8; WNS≥0; unsafe_cdc=0; BRAM≤135; SIM_FULL=0; F2 decimal.
- Existence: `pred=664` → existence PASS only (not full BOARD_PASS).
- JTAG: `210319BE776E*`; arm COM12 before program.

## UNIT

One board query after program (not clock-cycle pseudoreplication).
