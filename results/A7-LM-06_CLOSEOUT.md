# A7-LM-06 BOARD PASS — 2026-08-19

**Claim:** `ARTY_A7_803K_DDR_SCALE_LM_BOARD_VALIDATED`  
**Scope:** 802,816-parameter DDR-resident FPGA-updated Transformer: tiled W (one 131072 INT8 region), exact oracle folds, all-layer updates, persist 802816 B flush+reload, first-try K257→K511→K513.  
**Not claimed:** 8-way contextual retrieval, conversation, open-domain LM, or any 5% CE quality story.  
**law_id:** `lm06-signsgd-v1`

## Frozen implementation

| Item | Value |
|------|--------|
| board / part | Digilent Arty A7-100T / `xc7a100tcsg324-1` |
| UART | COM12, Digilent `210319BE776EA`, 115200 |
| bit | `build/out/arty_a7_lm06c3.bit` |
| bit SHA-256 | `222F804351261B5878D73E5501E4E34A28D330B09BB4BC3E1590EE79402884C6` |
| timing | WNS +0.359 ns / TNS 0 / WHS +0.031 ns |
| core clock | 50 MHz; MIG ui_clk ~83.33 MHz |

## Root cause repaired (C1/C2 → C3)

C1 persist **flush** worked; **reload** hung (`A6` never returned). Dest pulsed `dma_go` while MIG was still busy (owner-masked `busy` looked free) and persist STORE waited a TOK miss that could not refill because persist held the DMA mux.

C2 gave tile DMA priority, raw `dma_busy`, dest hold-go-until-busy, and reload `B_TOUCH`. xsim persist-reload PASS. Silicon **flush** then hung: `mem_sel` released the tile port in persist `B_REQ`, so the tile snapped to the last UART address and missed every chunk.

C3 keeps the C2 dest/mux/TOUCH fixes and drives the tile port from `p_busy` for the whole persist op.

## Conjunctive board result (C3)

- K257 → K511 → K513 first issue each, tensor fold exact;
- upload 802816 and every spot (TOK / POS / L0–L3 / HEAD / last) exact;
- fold0 `5 / 94638317`;
- one-full pred=744 loss=16 `wr_n=655616`;
- fold1 `23 / 94627297` `wr_n=655616`;
- all four layers moved and matched the oracle after-line;
- persist flush+reload 802816 B, xor=23, no under/berr/rerr; reload fold = fold1;
- AFTER adds zero writes.

## Evidence integrity

| Artifact | SHA-256 |
|----------|---------|
| C3 bit | `222F804351261B5878D73E5501E4E34A28D330B09BB4BC3E1590EE79402884C6` |
| C3 ladder | `37A53A73ED551910F4F28E164749F86967B2B1B376B29027B859DA165E689B61` |
| C3 manifest | `B14B190A21F642D5E2170B45C3386A1739A6B1303E948783F2FF803920566BF5` |
| C1 bit (locked fail) | `67C37DD51AED30F82B5B72EC9EF0736DDABA534ED1D724D0ADCAFD2B4282E3BA` |
| C2 bit (locked fail) | `EDAAF1204072664DFA5E62CA445B65DAE680C18777AC73DDEFD075C0ED6DD483` |

## Authorization

LM-07 is **authorized** (WNS +0.359 ≥ +0.20, TNS 0) and **not started**.  
Operating memory for the next law: `docs/contracts/A7-LM-06-LESSONS.md`.
