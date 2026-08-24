# A7-LM-06 packing (LOCKED)

XC7A100T: 135 RAMB36. LM-05 C02 used 134. Do not copy emb+layer+head.

## Lock

| Bank | Cells | Bits | RAMB36 |
|------|------:|-----:|-------:|
| W tile (one region) | 131072 × INT8 | tok / layer / head | 32 |
| Act | 131072 × INT16 = 8×C×D | `q_act` | 64 |
| Snap last-token | 4096 × INT16 | n1/n2/attn/hid | 2 |
| Tensor + MIG | — | ~34 | ~34 |
| **Total** | | | **~132 / 135** |

POS (16384) is **not** a second resident bank. ST_EMB / ST_BEM **serialize** tok then pos (one region miss at a time). Fold/snap park `addr_b = waddr`.

Regions: TOK, POS, L0–L3, HEAD. Miss = flush dirty 128 B lines of the live region, refill that region (POS=16384 B, else 131072 B).

`SIM_FULL=1`: behavioral 1M×INT8 W, stall=0 (xsim). Silicon `SIM_FULL=0`.

Do not store last-token snaps as FF arrays.  
Do not put 802816 W in BRAM.  
Do not program until `arty_a7_lm06.bit` exists with WNS ≥ 0.

## Persist

802816 / 128 = **6272** lines. Stall-aware.  
DMA mux (C3 close): **tile-W > persist > tensor**. Mem port stays on persist for the whole `p_busy` op.  
Do not use owner-masked `dma_busy` on tile/persist dest. See `A7-LM-06-LESSONS.md`.

## UART

20-bit W addr: `{buf[5][7:4], buf[4], buf[3]}`.  
10-bit tgt/pred: tgt `{buf[4][5:4], buf[3]}`; pred[9:8] on A0 byte5 / A1 byte11.  
7-bit ctx index/count.
