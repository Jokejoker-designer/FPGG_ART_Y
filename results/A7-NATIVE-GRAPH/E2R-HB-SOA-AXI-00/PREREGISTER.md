# E2R-HB-SOA-AXI-00 PREREGISTER (D1)

**Date:** 2026-08-25  
**Worktree:** `arty-a7-online-lm-board` ONLY  
**Parent:** HUMAN_D1 confirmed after A+ localize PASS (LAST_STAGE=`Q_GO`)  
**Prior:** `E2R-HB-CORE-BIND-00` bit SHA `139526F78D390174002F60A4CBE1BBD9555F1992A85BFAD10FA8E83AD74A5EB5`

## ONE UNKNOWN

Why does query SOA never assert `soa_done` after `Q_GO`? (QS_WAIT_SOA hang)

## OBSERVATION

COM12: `BOOT→MIG_OK→WMEM_OK→SOA_OK→CORE_START→OWNER_RDY→Q_GO` then silence. No SOA_Q/BIND/pred.

## H_CANDIDATE

Hang is inside query SOA AXI/wavefront after start: either no AR, AR without R, or R without `soa_done`.

## H_RIVAL

UART/CDC artifact (false localize); or B1 `r_path_idle` ownership interlock needed mid-query.

## FALSIFIER

D1 mid-query sticky markers on real DUT bits after Q_GO:
`SOA_RUN` / `AR_BEAT` / `R_BEAT` / `R_BUSY` / `R_IDLE` then `SOA_Q` if `soa_done`.

## UNIT

One board program + COM12 capture (not clock-cycle pseudoreplication).

## CONTROL

Keep A+ chain BOOT…Q_GO…; F2 decimal pred format; SIM_FULL=0; no host weight poke; no STARTUPE2; no B1 patch unless D1 shows R-path non-idle hang.

## METRICS (preregistered)

| Metric | Gate |
|--------|------|
| core_clk WNS | ≥0 ns |
| ui (clk_pll_i) WNS | ≥0 ns |
| TNS both domains | =0 |
| unsafe_cdc (user) | =0 |
| RAMB36 | ≤135 |
| SIM_FULL | 0 |
| JTAG | `210319BE776EA` |
| UART | COM12 @115200, arm before program |
| Existence | `pred=664` only → `NATIVE_V1_EXISTENCE_BOARD_PASS` |

## Stall class (post-hoc)

| Pattern | Class |
|---------|-------|
| no AR_BEAT | start/command path |
| AR_BEAT, no R_BEAT | AXI/MIG R-path |
| R_BEAT, no SOA_Q | wavefront/logic |
| R_BUSY hang, no progress | B1 candidate (DECIDE; do not blind-patch) |
