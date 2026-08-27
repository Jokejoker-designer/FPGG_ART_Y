# E2R-HB-MIG-AR-00 PREREGISTER — HUMAN_E1

**Date:** 2026-08-25  
**Worktree:** `arty-a7-online-lm-board` ONLY  
**Agent:** a7-vivado-gate  
**Authorization:** HUMAN_E1 — probe-only MIG AR / mux sticky markers after Q_GO

## OBSERVATION

D3 bit `889602B4…5ACF`: `…→AR_BEAT→RREADY1→OUTST` — no RV_SEEN / MIG_RV / CDC_NE. Subclass **NO_RVALID**. B1 falsified as sole fix.

## ONE UNKNOWN

Does MIG UI ever accept an AR (`arvalid && arready`) on the query path after Q_GO — or is AR blocked/stolen before MIG?

## H_CANDIDATE

MIG never sees query AR after Q_GO (mux/`wdma_owner_ui`/`cdc_arready` steal or CDC never presents).

## H_RIVAL

MIG accepts AR (`MIG_AR` fires) but still returns no RVALID → address/len or MIG silent (E2 class).

## FALSIFIER

If UART shows `MIG_AR` after Q_GO, H_CANDIDATE is falsified (AR reaches MIG).

## UNIT / CONTROL / METRICS

- Unit = one board program + COM12 capture after Q_GO (not clock cycles).
- Control = D1/D3 heartbeats retained; B1 grant interlock unchanged (no re-patch).
- Metrics: LAST_STAGE; MIG_AR YES/NO; OWN_WDMA YES/NO; CDC_AR YES/NO; MUX_CDC YES/NO; pred (existence only if 664); post-route WNS≥0; unsafe_cdc=0; BRAM≤135; SIM_FULL=0.

## ONE CHANGE

Sticky ui-domain UART markers: `MIG_AR`, `OWN_WDMA`, `CDC_AR`, `MUX_CDC` on real DUT bits after Q_GO. No B1 logic re-patch beyond tree.
