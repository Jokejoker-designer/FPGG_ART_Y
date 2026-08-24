# A7-LM-05 BOARD PASS — 2026-08-18

**Claim:** `ARTY_A7_399K_DDR_DEPTH_LM_BOARD_VALIDATED`  
**Scope:** 399,360-parameter **4-layer** DDR-resident FPGA-updated Transformer: tiled W, compact act, exact oracle folds, all-layer updates, persist 399360 B, first-try K257→K511→K513.  
**Not claimed:** 8-way contextual retrieval, conversation, open-domain LM, or any 5% CE quality story.  
**law_id:** `lm05-signsgd-v1`

## Frozen implementation

| Item | Value |
|------|--------|
| board / part | Digilent Arty A7-100T / `xc7a100tcsg324-1` |
| UART | COM12, Digilent `210319BE776EA`, 115200 |
| bit | `build/out/arty_a7_lm05.bit` (copy `arty_a7_lm05c2_hw_pass.bit`) |
| bit SHA-256 | `1AA0B5C481B0ADF3CAA599F081B430AF3C28A26FB4715DC56A0D25D940548F51` |
| timing | WNS +0.332 ns / TNS 0 / WHS +0.028 ns |
| core clock | 50 MHz; MIG ui_clk ~83.33 MHz |

## Root cause repaired (C01 → C02)

Fold walked `caddr` one ahead of `waddr`. Tile miss on two different layers plus `w_stall` freezing the FSM caused L(n)/L(n+1) refill oscillation. C02 parks weight `addr_b` in emb during `ST_FOLD`/`ST_SNAP`.

## Conjunctive board result (C02)

- K257 → K511 → K513 first issue each, tensor fold exact;
- upload 399360 and every spot (emb / L0–L3 / head) exact;
- fold0 `248 / 46987446`;
- one-full pred=5 loss=16 `wr_n=344256`;
- fold1 `243 / 46931969` `wr_n=344256`;
- all four layers moved and matched the oracle after-line;
- persist flush+reload 399360 B; reload fold = fold1;
- AFTER adds zero writes.

## Evidence integrity

| Artifact | SHA-256 |
|----------|---------|
| C02 bit | `1AA0B5C481B0ADF3CAA599F081B430AF3C28A26FB4715DC56A0D25D940548F51` |
| C02 ladder | `49FF0BD565928670E7A697F53FFBC1AA5FBEE7DDEA3F8DBC4C8DE7619395CC81` |
| C02 manifest | `9D2DAE6948384382E2803B385C2485190DF1F54120E250A97B53649A1B751E4B` |
| C01 fold-fail bit (keep) | `B7E68295E3277D5761EC8E4F92D73714B13287398DA79D9E0627FDF19B83A1C1` |
| C00 stall-fail bit (keep) | `31D869D62A2CC1A2067F11A288B663509E9374156696A8C2422BEDF815D9772B` |

Frozen 00–03 and `arty_a7_lm04r5.bit` SHA unchanged.

## Authorization

WNS +0.332 ≥ +0.20 and TNS = 0 → **LM-06 AUTHORIZED**.  
LM-04 R5 claim stays bounded. This close does not reopen R4.
