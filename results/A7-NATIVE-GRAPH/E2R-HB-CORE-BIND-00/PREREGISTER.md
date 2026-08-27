# E2R-HB-CORE-BIND-00 PREREGISTER

**Date:** 2026-08-25  
**Worktree:** `arty-a7-online-lm-board` ONLY  
**Parent:** Option **A+** after E2R-HB-UART-00 localize PASS

## ONE UNKNOWN

Where between `CORE_START` and `BIND_DONE` does silicon stall?

## H_CANDIDATE

Hang is after `core_rst_n` release in QS/`owner_ready` / query SOA / Top-K / accept / pack / bind / LM path — finer UART sticky heartbeats will name the last stage.

## H_RIVAL

Hang is UART/CDC artifact (false localize); or AXI/WDMA ownership needs B1 `r_path_idle` interlock.

## FALSIFIER

COM12 shows a stage past `CORE_START` (e.g. `OWNER_RDY` … `LM`) or reaches `NATIVE_V1_EXIST_ROW,pred=664`.

## CONTROL

Prior bit `261C0CA1…5504F` chain: `BOOT→MIG_OK→WMEM_OK→SOA_OK→CORE_START` then silence.

## UNIT

One JTAG reprogram + one COM12 capture (not cycle count).

## METRICS

| Metric | Gate |
|--------|------|
| core_clk WNS | ≥0 |
| ui (clk_pll_i) WNS | ≥0 |
| unsafe user CDC | =0 |
| RAMB36 | ≤135 |
| SIM_FULL | =0 |
| F2 decimal pred format | kept |
| LAST_STAGE | named from new heartbeats |
| pred | 664 → existence PASS only |

## Heartbeat order (DUT sticky)

`BOOT → MIG_OK → WMEM_OK → SOA_OK → CORE_START → OWNER_RDY → Q_GO → SOA_Q → TOPK → ACCEPT → PACK → BIND → FWD → LM → PRED`
