# E2R-HB-RVALID-00 PREREGISTER — D3 AXI-R sticky probe

**Date:** 2026-08-25  
**Worktree:** `arty-a7-online-lm-board` ONLY  
**Agent:** a7-vivado-gate  
**Authorization:** HUMAN_D3 (after D2 B1 silicon FAIL)

## ONE UNKNOWN

After AR handshake, why never R beat — no RVALID? wrong RID? CDC FIFO drop? MIG silent?

## OBSERVATION

B1 bit `87C04F57…AF0D6616`: `…→AR_BEAT→R_BUSY→R_IDLE` — no `R_BEAT`, no SOA_Q/pred. Stall class `AXI_MIG_R_PATH`. B1 form falsified as sole fix.

## H_CANDIDATE

Sticky mid-query markers on real DUT bits (`RV_SEEN` / `RREADY1` / `RID_OK|RID_BAD` / `OUTST` / `MIG_RV` / `CDC_NE`) localize the R-path failure subclass after AR.

## H_RIVAL

Markers stay opaque (none of the D3 lines fire beyond D1) → UNKNOWN subclass; DECIDE next RTL fix (do not invent second fix in this gate).

## FALSIFIER

If `pred=664` appears → existence PASS only (unexpected given D2). If D3 markers contradict a subclass claim → that subclass FAIL.

## UNIT / CONTROL

- Unit = one board program + COM12 capture after Q_GO (not clock cycles).
- Control = D1 heartbeats retained (`AR_BEAT`/`R_BEAT`/`R_BUSY`/`R_IDLE`); B1 grant interlock kept unchanged (no re-patch).

## METRICS (preregistered)

| Metric | Gate |
|--------|------|
| core_clk WNS | ≥0 |
| ui (clk_pll_i) WNS | ≥0 |
| unsafe user CDC | =0 |
| RAMB36 | ≤135 |
| SIM_FULL | =0 |
| F2 decimal pred row | kept |
| LAST_STAGE + stall subclass | NO_RVALID / RVALID_NO_READY / RID_MISMATCH / CDC_DROP / UNKNOWN |
| Existence | only if pred=664 |

## ONE CHANGE

Probe-only sticky UART markers + minimal CDC `dbg_r_ne_o` export. No B1 re-patch, no STARTUPE2, no host weight poke, no R6 main tree, no full BOARD_PASS.
