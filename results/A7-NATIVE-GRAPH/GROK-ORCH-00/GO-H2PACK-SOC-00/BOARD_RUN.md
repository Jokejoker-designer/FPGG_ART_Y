# GO-H2PACK-SOC-00 — board 2026-08-30 19:52

**PROGRAM_DONE.** Token consumed. **EXISTENCE:** false (`pred=733` ≠ 664). **BOARD_PASS:** not_claimed.

| Field | Value |
|-------|--------|
| Bit SHA256 | `EC286E9EAAEC1651B7C43687DB2B71FA45A30AABB3525D38F813FA342ED0211C` |
| JTAG | `210319BE776EA` startup HIGH |
| UART | 43.6 s `STOP_EARLY` exist-row, 662 B |
| Row | `NATIVE_V1_EXIST_ROW,pred=733` |
| PACK | **`FFFFFFFFFFFFFFFF`** (not `3B392B291B190B09`) |
| GRANT | 1 |
| CORE_DONE | yes PHASE=07 |
| WMEM_OK | yes |

## H2

Silicon pack is eight bytes `0xFF` = token id 255 × 8.

Cause (RTL, not a guess): SoC ties `.poison_i(1'b1)` and `poison_id[gi]=32'd255`.  
`a7ng_native_v1_ab_core` does `bind_gid = poison_i ? poison_id : topk_id`.  
Bind therefore always packs `FF…FF`, never A-FAST `[9,11,25,27,41,43,57,59]`.

H4 XSim used `poison=0` around bind → pack golden → `pred=664`.  
Silicon poison-on → pack FF → `pred=733`.

H2 **CONFIRMED** as the 733-vs-664 mechanism. Next product change: `.poison_i(1'b0)` then new BIT_OK. Do not reprogram this `EC286E9E` bit.
