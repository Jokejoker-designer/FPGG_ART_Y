# pred=371 vs pred=664 — evidence audit

**Bit that printed 371:** `B64B2649…` (level-hold `D_GO`, tile `A4E5FEAC…`, `SIM_FULL=0`).  
**A-FAST that printed 664:** core `355182A7…` **`SIM_FULL=1`**, no MIG, no tile DMA.  
**BOARD_PASS:** not claimed. 744 is LM-06 golden, not this row.

## What 664 and 371 are

A-FAST golden pack `64'h3b392b291b190b09` = eight tokens `[9,11,25,27,41,43,57,59]`.  
TinyGPT argmax (`ST_ARG`): `vix=0` seeds `arg_best`; later `vix` wins only if `logit > arg_v` (tie → smaller index).  
`pred <= arg_best` then `ST_DONE`. UART `pred=DDD` is decimal of that 10-bit register.

| | 664 | 371 |
|--|-----|-----|
| binary | `10'b1010011000` | `10'b0101110011` |
| hex | `0x298` | `0x173` |

Not a 1-bit flip. Not “print 0x298 as 298”. Not “still computing” (`CORE_DONE` + `PRED_NZ` on the 371 bit).

## Two vehicles (must not be mixed)

| | A-FAST XSim | Silicon 371 bit |
|--|-------------|-----------------|
| `SIM_FULL` | **1** (`stall=0`, 1M sim BRAM, `$readmemh`) | **0** (131072-B resident tile + DDR refill) |
| Memory | AXI **stub** | MIG + QSPI boot 802816 B `@FLASH 0x40_0000` → DDR |
| Tile DMA | **none** | `D_GO` level-hold until `dma_busy` |
| Pack check | `CAPTURE_OK pack=3b392b291b190b09` | UART `PACK` only — **no hex** |
| SOA IDs | top1=9 score=165, 8-way law | UART `TOPK ACCEPT` — **no IDs** |
| Result | `pred=664` | `pred=371` |

## Silicon UART (CONFIRMED)

Forward **did finish**: `WMEM_OK` → `SOA_OK` → `PACK` `FWD` `LM` → `TILE_MISS` → `CORE_DONE` → `NATIVE_V1_EXIST_ROW,pred=371`.

After done, leftover DMA: `CMD_EMPTY=0` `SBUSY_PEND=1` `CMD_ST=2` `MGO=1` `GRANT=1` `SDONE=0`.  
`RID_BAD` sticky (at least one AXI R ID mismatch).  
`PHASE=07` is UART ROM order (printed before `PRED_NZ`); last latched busy can be `ST_MV`.

## XSim3 on the **same** 371 tile (CONFIRMED)

`SIM_FULL=0` + completable **stub** (not MIG):

- Embedding POS then TOK **bit-exact** vs DDR patterns: `EMB_EXACT=1`
- `DEST4_TOTAL=1152` (128 POS + 1024 TOK lines)
- `GO_COUNT=3456` `DONE_COUNT=1152` `GO_WHILE_BUSY=2304` → **exactly 3 `dma_go` per line**
- TB law: `STUB_NOT_AXI` `STUB_NE_MIG` `STUB_NE_BOARD`
- **Does not run** layers/HEAD; `NEXT_LAYER=1` then stop
- Extra GO ignored by stub → embedding still exact

So: 3× GO is **real on this tile**. It does **not** by itself prove silicon `pred=371`. It does prove extra commands exist; silicon leftover `CMD_EMPTY=0` after `CORE_DONE` matches extra cmds **surviving** into/after layers+HEAD (those refills were **not** checked in XSim3).

## Ranked hypotheses

### H1 — wrong/partial **layer/HEAD tiles** from 3× GO (supported, not closed)

Resident bank is **one 131072-B region**. Forward after embed walks L0–L3 + HEAD (`OFF_HEAD=671744`). Each miss refills 1024 lines. Extra `m_go` while hold/busy → overflow/relatch (CDC) → extra AXI cmds. Stub dropped them (`EMB_EXACT=1`). MIG + `REQUEST_HELD` queued them (`CMD_EMPTY=0`). HEAD/layer INT8 then ≠ A-FAST BRAM → argmax **371**.

Fits leftover FIFO after `CORE_DONE`. Does **not** need 371 to be a “magic” index.

### H2 — silicon **ctx pack ≠** `3b392b291b190b09` (open)

A-FAST 664 is golden **only** for that pack. Silicon UART never printed pack hex or topk IDs. `RID_BAD` can poison SOA R. If prefix tokens differ, 371 can be a **correct** argmax of a **different** prefix (weights OK). **MISSING** measurement.

### H3 — QSPI WMEM ≠ A-FAST hex (open)

Silicon `WMEM_OK` = 802816 B copied from flash `@0x40_0000`, not “bytes match `a7lm06_wmem.hex`”. A-FAST loads hex into sim BRAM. **MISSING** flash vs hex hash on this run.

### H4 — `SIM_FULL=0` numerics with **perfect** tiles still 371 (open)

Untested. Need SIM_FULL=0 forward XSim (or 1-GO silicon) of the **same** hex, print `pred`. If 664 → H4 false. If 371 → tiling/quant path, not 3× GO.

### H5 — UART/CDC tore 664→371 (falsified)

Many bits differ; value held across `CORE_DONE` then F2 decimal print.

### H6 — 600 s / WNS (falsified)

371 bit already printed the row. Place/route WNS was ≥0 on later bits; this bit completed forward.

## What is **not** proven

“3× GO caused 371.” Embedding on a stub was exact. Layers/HEAD on MIG were not scored. Pack and flash were not scored.

## One-unknown order (do not mix)

1. Print `ctx_pack` / topk IDs on UART (closes H2).  
2. SIM_FULL=0 XSim **full** forward with 1-GO tile + same hex → `pred=?` (closes H4 vs H1).  
3. Confirm flash 802816 SHA vs hex (closes H3).  
4. Only then treat 3× GO as the 371 mechanism.

Do not program leftover LONGBOOT. Do not stamp BOARD_PASS. Do not mix 744.
