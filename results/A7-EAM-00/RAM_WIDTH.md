# Actual EAM record width (00S vs 00B silicon)

Not a bug. Vivado inferred the full 256-bit TDP template, then **deleted unused bit-slices** on the board wrap.

## Official `report_ram_utilization`

| Build | Array | Geometry | Primitives | Bits |
|-------|-------|----------|------------|------|
| **00S** OOC `a7eam00_top` | `u_core/u_mem/mem` | **4096 × 256** | 28×RAMB36 (4K×9) + 1×RAMB18 (4K×4) | **1,048,576** |
| **00B** board | `u_link/u_core/u_mem/mem` | **4096 × 171** | 19×RAMB36 (4K×9) | **700,416** |
| **00G** board | same as 00B | **4096 × 171** | 19×RAMB36 | **700,416** |

Evidence: `ram_00s_ramutil.rpt`, `ram_00b_ramutil.rpt`, `ram_*_util_hier.rpt`.

Hierarchical 00B: all 19 RAMB36 sit in `u_link/u_core/u_mem` (`eam_tdp256`). LUTRAM = 0.

## How 256 bits are sliced

Each RAMB36 is **4096 × 9**. One RAMB18 is **4096 × 4**.

```
28×9 + 4 = 256   →  00S mem_reg_0 .. mem_reg_28
19×9     = 171   →  00B mem_reg_0..7 and mem_reg_16..26
```

00B synth log (`build/a7eam00b.log`) first maps `4K × 256` as 28+1, then **constant-propagation** removes:

```
mem_reg_8  .. mem_reg_15   (8 × RAMB36)
mem_reg_27                 (1 × RAMB36)
mem_reg_28                 (1 × RAMB18)
```

If slices are packed 9 bits from LSB `[0]`:

| Slice | Bits | Field (packed struct, key at LSB) | 00B |
|------:|------|-----------------------------------|-----|
| 0–7 | [71:0] | **key[63:0]** + vec[7:0] | **kept** |
| 8–15 | [143:72] | vec[79:8] | **removed** |
| 16–21 | [197:144] | vec[127:80] + **token[5:0]** | **kept** (token shares a slice) |
| 22–26 | [242:198] | token[7:6], **conf**, **age**, **tag[8:0]**, **flags[2:0]** | **kept** (scan/evict/token) |
| 27–28 | [255:243] | flags[15:3] | **removed** (RTL constant 0) |

RTL pack (`a7eam00_pkg.sv`):

```
[255:240] flags   [239:224] tag   [223:208] age
[207:200] conf    [199:192] token
[191:64]  vec     [63:0]    key
```

`eam_new_entry` writes `flags=16'd1`, `tag={8'd0,epoch}`. So **flags[15:1]** and **tag[15:8]** are compile-time zeros → slices 27–28 die even on 00S they exist only because the 256-bit port is kept whole.

## Why 00S keeps 256 bits and 00B does not

| | 00S `a7eam00_top` | 00B/00G `eam00b_uart` |
|--|-------------------|------------------------|
| `out_vector` [127:0] | **top-level port** (every vec bit observable) | wired to `ovec` **with no load** |
| `out_confidence` | top-level port | `oconf` unused |
| `out_way` | top-level port | `oway` unused |
| Hamming `key` | used | used |
| valid `flags[0]`, `tag[7:0]` | used | used |
| evict `conf`, `age` | used | used |
| UART token | used | used |

00S cannot delete vec: it is an OOC output.  
00B never sends vec/conf/way over UART → synth DCE + constant-prop drops **85 bits** (mostly mid-vec + constant flag padding).

00B/00G **do not store a full 32-byte record in silicon**. Token + key + evict metadata are real. The 128-bit value vector is **only partially present** (bits that share a 9-bit BRAM column with a live field, plus leftover EMA columns).

## Implication for EAM-01 DDR

- **Nominal RTL width** remains 256 bits / 32 B.
- **00B immutable silicon width** is **171 bits / entry**, not 32 B.
- Do not size DDR rows, DMA beats, or persist format from the 00B BRAM count.
- To force a 32-byte store on a board bit: observe `out_vector` (UART payload or `dont_touch` on `mem`), or instantiate the OOC-style top.
- 00B ladder still valid: it only required token / hit / hamming / evict / epoch — all live.

## Not a capacity bug

19 × 36,864 = 700,416 < 1,048,576. That inequality is **expected** once 85 bits are deleted. The inferred array is 4096×171, which fills 19 RAMB36 exactly.
