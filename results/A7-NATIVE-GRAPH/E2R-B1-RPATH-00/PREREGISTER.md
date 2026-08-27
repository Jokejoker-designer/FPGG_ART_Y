# E2R-B1-RPATH-00 PREREGISTER

**Date:** 2026-08-25  
**Worktree:** `arty-a7-online-lm-board` ONLY  
**Authorization:** HUMAN_D2 / GOAL_D2  
**Prior:** E2R-HB-SOA-AXI-00 (D1) — stall class `AXI_MIG_R_PATH`, no R_BEAT

## ONE UNKNOWN

Does B1 `r_path_idle` ownership interlock on the shared MIG AR/R mux restore R beats → SOA_Q → pred=664?

## H_CANDIDATE

Registered WDMA grant gated on `r_path_idle` prevents reverse dual-drive (CDC AR outstanding → WDMA steals `rready`), restoring R_BEAT / SOA_Q / pred=664.

## H_RIVAL

Hang is deeper MIG/RID/outstanding defect; B1 alone does not restore R beats → DECIDE D3.

## FALSIFIER

Board program + COM12 @115200: after Q_GO+AR_BEAT, observe R_BEAT and `NATIVE_V1_EXIST_ROW,pred=664`. No R_BEAT → H_CANDIDATE falsified.

## ONE CHANGE

`arty_a7_ng_native_v1_ab_soc_top.sv`: `wdma_owner_grant` FF — grant only when `wdma_owner && r_path_idle`; release on `!wdma_owner`; CDC `m_owner` uses grant. Keep D1 heartbeats + F2 decimal pred. SIM_FULL=0.

## XSim choice

**Skip** dedicated XSim — no mux-hazard TB; D1 board already localizes `AXI_MIG_R_PATH`; falsifier is board UART.

## Gates

| Metric | Threshold |
|--------|-----------|
| core / ui WNS | ≥0 |
| unsafe_cdc | 0 |
| RAMB36 | ≤135 |
| JTAG | `210319BE776E*` |
| UART | COM12 armed before program |

## Existence claim rule

pred=664 → seal `NATIVE_V1_EXISTENCE_BOARD_PASS` only (not full BOARD_PASS).  
No R_BEAT → FAIL honest; DECIDE D3.
