# LM06-Q0 — BRAM ownership audit

Read-only audit of the archived post-route checkpoint
`build/out/a7lm06_post_route.dcp` (Vivado 2026.1). Nothing was rebuilt, no bit
was touched, and the encoder lane was not disturbed.

Method: enumerate every `BMEM` primitive with `get_cells -hier`, record
`REF_NAME`, `RAM_MODE` and the four port widths, then aggregate by hierarchy.
Raw per-cell data in `bram_cells.tsv` (132 rows).

## The gating question, answered

The question was: are the 132 tiles mostly activation/scratch, in which case
low-bit weights barely help BRAM, or mostly weight staging, in which case they
attack the integration problem directly?

**Neither. It is almost exactly half and half.**

| owner | tiles | share of 132 | share of 135 available |
|-------|-----:|------------:|----------------------:|
| `u_a` — activation path | **66** | 50.0% | 48.9% |
| `u_w` — weight path | **64** | 48.5% | 47.4% |
| `u_snap` — snapshot | 2 | 1.5% | 1.5% |

Breakdown by mode and per-tile port width:

| owner | mode | rd_a | wr_b | tiles |
|-------|------|----:|----:|-----:|
| `u_a` | TDP | 1 | 1 | 64 |
| `u_a` | SDP | 72 | 72 | 2 |
| `u_w` | TDP | 1 | 1 | 32 |
| `u_w` | SDP | 72 | 72 | 32 |
| `u_snap` | TDP | 9 | 9 | 2 |

Representative names: `u_core/u_w/TILE.u_bank/mem_reg_0_*`,
`u_core/u_a/mem_reg_0_*`, `u_a/mem_reg_*`, `u_core/u_snap/mem_reg_*`.

A caution on the width column: `READ_WIDTH_A = 1` is the **per-tile** port width
Vivado reports when a wide logical memory is split bit-wise across parallel
tiles. It is not the logical word width and must not be read as "this memory is
one bit wide". The load-bearing numbers here are the tile counts, which are
unambiguous.

## What `u_w` actually is

64 tiles × 36 Kbit = **2.36 Mbit** of capacity. A full 8-bit weight image for
`P_LM = 802,816` is **6.42 Mbit**. So `u_w` holds at most ~37% of the model and
cannot be the weight store — it is a staging buffer, which is consistent with the
frozen design's DDR-resident weights.

That distinction decides how much low-bit weights can free, and it is a design
choice rather than something this audit can measure:

- If the buffer is sized by **logical tile shape** (it must hold N weights for a
  compute tile), then 8-bit → 2-bit lets the same tile fit in ~1/4 the BRAM, and
  roughly 48 of the 64 tiles are freed.
- If the buffer is sized by **available BRAM** (take what is spare, stage as much
  as fits), then low-bit weights stage 4× more per fetch and free **nothing**.
  The gain shows up as DDR bandwidth and burst efficiency instead.

Which one holds must be settled by reading the LM-06 RTL's buffer sizing, not
inferred from the tile count. That is the first thing LM06-Q1 should establish,
before any quantised kernel is written.

## Arithmetic on the integration problem

Best case for W2, assuming the buffer is shape-sized and scales 4×:

```
LM-06 today   : 66 activation + 64 weight + 2 snap = 132 tiles  (97.8%)
LM-06 with W2 : 66 activation + 16 weight + 2 snap =  84 tiles  (62.2%)
```

Then the four-subsystem sum a Native AI V1 must hold at once:

| | today | with W2 (best case) |
|---|---:|---:|
| LM-06 | 132 | 84 |
| 01R router | 56 | 56 |
| 02M episodic memory | 52 | 52 |
| A0.3 encoder | 3 | 3 |
| **total** | **243 = 180%** | **195 = 144%** |

**W2 does not solve the integration problem.** In the most favourable
interpretation it moves BRAM pressure from 180% to 144%, which is still over
budget. The reason is now measurable and specific: after quantisation the
dominant BRAM consumers are no longer LM-06 weights but LM-06 **activations**
(66) plus 01R (56) plus 02M (52) — and none of those three is touched by weight
precision.

So the load-bearing change for integration is **DDR-backing 01R and 02M**, which
is already what Step 8 of the proposal draws. Low-bit weights are worth doing for
DDR bandwidth and for headroom, but they are not the thing that makes V1 fit.

Stated as a ranking of what actually buys BRAM:

1. Move 01R index and 02M episode storage to DDR — releases up to 108 tiles.
2. Share or time-multiplex the activation scratch — 66 tiles, currently
   untouched by any proposal in the lane.
3. Quantise weights — up to 48 tiles, and only if the buffer is shape-sized.

## What this audit does not claim

It does not claim the buffer is shape-sized; that is the open question above.
It does not claim any DSP or LUT figure for a quantised kernel — nothing has been
synthesised. It does not claim a quality delta, since no quantised model exists.
It is post-route data for the **LM-06-only** bitstream; an integrated design
would share UART, clocking and possibly MIG, so the activation and snapshot
counts would move.

Parameter count is unchanged by any of this: `P_LM = 802,816` at W8 and at W2
alike. Only precision and storage change, and the two must never be conflated in
a claim.

## Suggested ordering, revised by this measurement

The proposal's ladder had Q0 audit → Q1 W4A8 → Q2 W2A8. The audit says the
integration blocker is elsewhere, so the honest revision is:

```
Q0  BRAM ownership audit                     <- done, this document
Q0b read LM-06 RTL: is u_w shape-sized?      <- decides whether Q1/Q2 free BRAM
D1  DDR-back 01R index and 02M episodes      <- the actual 108-tile lever
Q1  W4A8                                     <- bandwidth + headroom
Q2  blockwise ternary W2A8                   <- only after Q1 passes its gate
```

`D1` outranks `Q1` on measured impact. It is also independent of the encoder
lane and of quantisation, so it can be specified without waiting for either.

None of this starts before the encoder closes. E6 is still running.
