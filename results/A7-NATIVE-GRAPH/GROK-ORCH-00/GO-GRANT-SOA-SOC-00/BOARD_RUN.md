# GO-GRANT-SOA-SOC-00 — board 2026-08-30 16:44

**PROGRAM_DONE.** Token consumed. **EXISTENCE:** false (`pred=733` ≠ 664). **BOARD_PASS:** not_claimed.

| Field | Value |
|-------|--------|
| Bit SHA256 | `00517465B4A6A560310B052D4301D2B435D0576C22D8E6B6FA56FFBC372DD282` |
| JTAG | `210319BE776EA` startup HIGH |
| UART | 87.6 s `STOP_EARLY` exist-row |
| Row | `NATIVE_V1_EXIST_ROW,pred=733` |
| GRANT | **1** (deadlock broken) |
| TILE_DST | 0 IDLE after done |
| CORE_DONE | yes |
| CMD_EMPTY | 0 leftover |

Grant `!soa_running` unblocked forward. Not 371, not stall, **not 664**.

H1 (3× GO → 371) **not sufficient** for 664: 1-GO still `733`. Cursor UART also recorded `pred=733` on another bit — points to H2 pack / H3 flash / H4 SIM_FULL=0.
