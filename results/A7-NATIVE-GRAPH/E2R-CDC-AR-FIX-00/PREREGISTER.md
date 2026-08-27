# E2R-CDC-AR-FIX-00 PREREGISTER — HUMAN_F1A

**Worktree:** `arty-a7-online-lm-board` ONLY  
**Authority:** `STATUS/E2R_F1_CDC_FIX_DISPATCH.md`  
**Prior E3:** E2R-HB-CDC-AR-00 / `CDC_INTERNAL_STUCK`

## ONE UNKNOWN

Does F1a (AR FIFO → FWFT + simple `s_arvalid` hold) restore `CDC_S_ARV` → `MIG_AR` → R → `pred=664`?

## ONE CHANGE

`rtl/board/a7ng_axi_read_cdc.sv` only — F1a. No F1b (`core_hold` on `m_rst_n`).

## FALSIFIER

Board after rebuild+program: still `CDC_S_ARV=0` with `CDC_M_ARF=1` → F1a FAIL; DECIDE F1b.

## Gates

maxThreads 8; WNS≥0; unsafe_cdc=0; BRAM≤135; SIM_FULL=0.
