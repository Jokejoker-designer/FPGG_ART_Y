# One unknown — D_GO level-hold vs 1-cycle pulse

**PROGRAM=NO. JTAG=NO. COM12 released to Cursor.**

## Diff (only functional delta in `weight_tile803k.sv`)

Grok-orch silicon tile `A4E5FEAC…` (this bit):

```systemverilog
D_GO: begin
    dma_go <= 1'b1;
    ...
    if (dma_busy)
        dst <= is_flush ? D_FEED : D_DRAIN;
end
```

`dma_go` is defaulted `<= 0` then set `1` **every cycle spent in D_GO**. Leave D_GO only when `dma_busy` is already 1.

close664 CFIX tile `9EE30702…` (published law, **not copied onto this tree this note**):

```systemverilog
D_GO: begin
    // E2R-OWNER-FENCE-CFIX: 1-cycle dma_go pulse (not level hold)
    dma_go <= 1'b1;
    ...
    dst <= is_flush ? D_FEED : D_DRAIN;  // always advance
end
```

## Arithmetic (CONFIRMED on grok-orch XSim3)

| | grok-orch tile | close664 CFIX tile |
|--|----------------|-------------------|
| SHA | `A4E5FEAC…` | `9EE30702…` |
| `GO_COUNT` | **3456** | **1152** |
| `DONE_COUNT` | 1152 | 1152 |
| `GO_WHILE_BUSY` | **2304** | **0** |
| 3456/1152 | **exactly 3** | 1 |

1152 = 128 POS lines + 1024 TOK lines. Three `dma_go=1` cycles per line while waiting for `dma_busy` → 1152×3=3456.

On the **completable stub**, `EMB_EXACT=1` still (extra GO ignored). On **MIG + REQUEST_HELD**, extra `m_go` while hold is **overflow** — later layer tiles can be wrong. Silicon UART: `TILE_MISS` `W_STALL` `SDONE=0` `MGO=1` `CMD_EMPTY=0` `SBUSY_PEND=1` then `pred=371`.

## Not claimed

That CFIX pulse **will** make silicon print 664. That is the next experiment, after Cursor returns the board. Do not copy their dirty file wholesale; re-implement the **1-cycle pulse law** on this checkout.

A-FAST `pred=664` remains `SIM_FULL=1` (no DMA). XSim ≠ board.
