# A7-LM-02R — ping-pong / counter / requant closure

**Status:** OPEN  
**Requires:** A7-LM-02 BOARD_PASS archive frozen  
**Does not:** overwrite `arty_a7_lm00.bit` / `arty_a7_lm01.bit` / `arty_a7_lm02.bit`  
**Does not:** overwrite frozen 00/01/02 bits. A7-LM-03 isolation image `C98B…23D1` is BOARD_PASS (2026-08-17). 02R acc_cont bit is still not board-gated.  
**Authority:** original `docs/contracts/A7-LM-02.md` + this revision  

A7-LM-02 silicon result (128 MAC, 10K aggregate fold, U_MAC, DDR roof) stays archived.  
This revision closes the contract/implementation gaps: real weight ping-pong, split counters, requant/corner board tests, honest 10K wording.

## Frozen originals

| Bit | SHA256 |
|-----|--------|
| `arty_a7_lm00.bit` | `449A330B…34783` |
| `arty_a7_lm01.bit` | `96065A17…507B8` |
| `arty_a7_lm02.bit` | `7CEBA854…95CC4` |

Revision image: `build/out/arty_a7_lm02r.bit` only.

acc_cont rebuild (2026-08-17, not yet board-gated):

```text
arty_a7_lm02r.bit  SHA256 2F620A309A25B853A27D538D887EEE1A97986611DF81E1520C10E3421EB243F9
POST_ROUTE_WNS    +0.276 ns
```

Frozen 00/01/02 SHA unchanged (`449A330B…34783`, `96065A17…507B8`, `7CEBA854…95CC4`).

## Why reopen

1. `wr_bank`/`rd_bank` were tied to 0; `ntile` forced to 1. Dual-bank RAM existed but the datapath never swapped.
2. `hazards==0` was taken from the 10K compute batch, which does not stream DDR tiles. `dma_under` was folded into the same counter.
3. Opcode `0x28` requant was never board-called. Closeout spots `0,1,7,17,19` are not corner/sat (`case 13` = corner, `case 8` = sat).
4. “10,000 cases exact” is one 32+32 aggregate fold, not per-case folds.

## Gates (conjunctive)

| Gate | Pass |
|------|------|
| K=257 GEMV N=128 vs `fixed_gemm.py` | fold match |
| K=511 GEMV N=128 | fold match |
| K=513 GEMV N=128 | fold match |
| bank swaps | > 0 on each K>256 run |
| overlap cycles | > 0 (`mac_en && dma_busy` or `mac_en && fill_busy`) |
| DMA underflow | 0 |
| bank hazard | 0 |
| AXI BRESP err | 0 |
| AXI RRESP err | 0 |
| case 13 corner | fold match |
| case 8 saturation | fold match |
| opcode `0x28` requant after case 8 | fold match vs Python `sat16(psum>>>shift)` |
| 10K per-case folds | 10000/10000 host compare (case fold, not one batch xor) |
| WNS | ≥ 0 |
| frozen 00/01/02 SHA | unchanged |

Host compares only. Host does not compute the board GEMM/GEMV.

## UART addenda (still `A5 72`)

| op | |
|----|--|
| `0x29` | ping-pong DDR GEMV: K=a, seed (N=128) |
| `0x2C` | counters2 → `0x94` under32, bank_haz16, berr8, rerr8, swaps16 |
| `0x2D` | overlap → `0x95` overlap32, ntile16 |

`0x24`/`0x92` unchanged (cycles, mac-enable cycles, legacy hazards field = 0 on 02R).

## K tile rule

```
ntile = (K + 255) >> 8
Ktile[t] = 256 if t+1 < ntile else K - 256*t
wr_bank = fill/DMA destination
rd_bank = MAC source
acc_cont = 1 for t>0
```

K=257 → tiles 256+1; K=511 → 256+255; K=513 → 256+256+1.
