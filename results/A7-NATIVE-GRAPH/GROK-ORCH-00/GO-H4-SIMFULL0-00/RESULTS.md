# GO-H4-SIMFULL0-00 — RESULTS

**PROGRAM=NO.** Stub DMA + golden pack. Stub ≠ MIG ≠ board.

| Check | Result |
|-------|--------|
| SOA top8 | PASS ids 9,11,25,27,41,43,57,59 |
| Pack | `3b392b291b190b09` **CAPTURE_OK** |
| TinyGPT `SIM_FULL=0` | ran after stall-idle + bind hold |
| H4_GO / DONE | 7296 / 7296 `GO_WHILE_BUSY=0` |
| SMX logit0 | 1310985 |
| H4_PRED | **664** |
| H4_CLASS | **MATCH_664** |

Log: `xsim.log` finish 2026-08-30 18:50:41, sim 202930595 ns, elapsed 5m27s.

H4 (tiling/quant with correct hex + golden pack) is **falsified** as the cause of silicon `pred=733`.

Next silicon-ready bit: `GO-H2PACK-SOC-00` UART `PACK=` 16 hex. Board nạp only after **BIT_OK** of that bit.
