# Dest-wait leftover map — stub + encode sealed

## Law (unchanged)

`r_path_idle = !r_drain_hold && fifo_cnt==0 && !m_axi_rvalid && tr_cnt==0`  
B1: `wdma_owner_grant` rises only when `wdma_owner && r_path_idle`.

## FACT (XSim)

| Bag | dest | grant | idle | encode digits |
|-----|------|-------|------|---------------|
| MUX after grant | 4 | 1 | 0 | 4,1,0 |
| GRANT0 | 3 | 0 | 1 | — |
| GRANT0-RINJ | 4 | 0 | 1 | 4,0,1 |
| GRANT0-RMUX | 3 | 0 | 0 | 3,0,0 |
| UART-ENC | — | — | — | **FAITHFUL** (only 4,0,0 prints 4,0,0) |

UART-ENC agent: [a7-ng-xsim-verify](a20ccc54-abc7-429d-b657-ae20389d6c81). SHA `9EDC1B3D…`.

## FACT (silicon)

B-FIX BIT `6023D9A3…`: `TILE_DST=4` `GRANT=0` `RPATH_IDLE=0` `SGO=0` `pred` absent.

## CONTRADICTED on stub+encode

Silicon triple `4 ∧ 0 ∧ idle=0` is **not** stub occupancy and **not** a hex_nib collision. Open: true MIG leftover or A2. C-FIX still **NONE**.

## Forbidden

- C-FIX / `assign r_path_idle=1` / A2 without DECIDE
- F1x / B4 without DECIDE
- Phase 2
- Overwrite frozen LM-06 / 01R / 02M / A0.3
