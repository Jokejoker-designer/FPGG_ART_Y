# GO-H2PACK-SOC-00 — PREBUILD_READY

**PREBUILD_READY = YES.** **PROGRAM=NO** until a human token names `GO-H2PACK-SOC-00` and this SHA.

| Field | Value |
|-------|--------|
| Gate | `GO-H2PACK-SOC-00` |
| Bit | `arty_a7_ng_native_v1_grok_orch_h2pack_00.bit` |
| SHA256 | `EC286E9EAAEC1651B7C43687DB2B71FA45A30AABB3525D38F813FA342ED0211C` |
| Size | 3826011 B |
| WNS | +0.510 ns |
| TNS | 0.000 |
| WHS | +0.019 |
| THS | 0.000 |
| core_WNS | +13.150 |
| ui_WNS | +1.937 |
| RAMB36 | 103 (≤135) |
| DSP | 19 |
| CDC candidate_logic | 2 (FINDING, same class as grant-soa `u_wdma_rel_sync`; not bitstream skip) |
| Impl exit | 2026-08-30 19:40:04 |
| `open_hw_manager` | not used |
| COM12 | Cursor (not held) |
| BOARD_PASS | not_claimed |

Do **not** program leftover bits: `00517465` grant-soa (pred=733), grant-miss, pulse, wait-busy, existence 371, LONGBOOT, two-pass.

After named token: arm COM12 DTR/RTS false → program this SHA on JTAG `210319BE776EA` only → UART look for `PACK=` and `NATIVE_V1_EXIST_ROW,pred=`. Golden pack `PACK=3B392B291B190B09`. Existence still only `pred=664`.
