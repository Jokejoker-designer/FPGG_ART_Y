# GO-GRANT-MISS-SOC-00 — board run 2026-08-30 15:36

**PROGRAM_DONE.** Token consumed. **EXISTENCE:** false. **BOARD_PASS:** not_claimed.

| Field | Value |
|-------|--------|
| Gate | GO-GRANT-MISS-SOC-00 |
| Bit SHA256 | `885DC99C559B92129C29207FF0870F9E7AF1688A2446D65FB6A761FB231A59D4` |
| JTAG | `210319BE776EA` startup HIGH |
| COM12 arm | 15:36:31 DTR/RTS false |
| Program | 15:37:23 |
| UART stop | 90.3 s max_seconds |
| PRED | **NONE** |
| Last | `W_STALL` `PHASE=02` (`ST_EMB_TOK`) `TILE_DST=1` `GRANT=0` `RPATH_IDLE=0` `OWNER=1` |

H1 (3× GO → 371) **not scored** — forward did not reach `ST_ARG`. Same grant/`r_path_idle` class as wait-busy stall (`PHASE=01` then). COM12/JTAG released after capture.
