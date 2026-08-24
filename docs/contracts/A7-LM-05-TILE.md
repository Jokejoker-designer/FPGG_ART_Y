# A7-LM-05 tile + compact-act packing

Status: RTL written. Compact-act re-xsim **PASS**. Tile mode (`SIM_FULL=0`) not yet xsim'd. No bitstream. Do not program.

## Why

XC7A100T = 135 RAMB36. LM-04 r3 used 130. Full 399360×8 W (128 BRAM if 512K deep) + 04-style 64K×32 act (64) does not fit with MIG + tensor tiles.

## Compact act (silicon and xsim)

48K × INT32 = 8 tensors × 64 tok × 96 dim. `ly` is reused.

- `aa(t,tk,d) = t*6144 + tk*96 + d`
- `ah` overlays t=3/4 after attention (K/V dead; FF hidden)
- `ay` overlays t=0 after ADD ten=0 consumes residual-in
- Last-token bwd snapshots: `n1_last`, `n2_last`, `a_last`, `hid_last` (FF)

Oracle match after this change: pred=5, fold0 248/46987446, fold1 243/46931969, wr_n=344256.

## Tiled W

Resident banks: emb 55296 + one layer 73728 + head 49152.
Miss: writeback dirty layer (128 B lines, persist-style CDC clk50↔ui_clk) then refill from `DDR_WBASE+OFF_L0+ly*LAYER_W`.
Core FSM holds on `w_stall`.

Budget (target): act 48 + W 44 + tensor/MIG ~34 ≈ 126 / 135.

## Persist

`lm05_persist`: 3120 × 128 B = 399360. Walks the mem port; waits `mem_stall` across a tile miss. DMA owner yields during fill so the tile can use AXI.

## UART deltas vs LM-04

- Addr 19-bit: `{buf[5][6:4], buf[4], buf[3]}` (0x30/0x31)
- tgt 9-bit: `{buf[4][4], buf[3]}` (0x34)
- ctx 6-bit
- pred[8] in A0 byte 5 / A1 byte 11

## Bit

`build/out/arty_a7_lm05.bit` only. Frozen 00–03 and `arty_a7_lm04*.bit` stay untouched.
