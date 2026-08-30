# GO-H2PACK-SOC-00 — PLAN (offline BIT_OK)

**PROGRAM=NO.** Investigate/fix until this bag has **BIT_OK**. Board program only after that BIT_OK + named token.

## Facts (not guesses)

| Claim | Class | Evidence |
|-------|--------|----------|
| XSim H4 SIM_FULL=0 + golden pack + hex DMA stub | EVIDENCE | `GO-H4-SIMFULL0-00/xsim.log` `H4_PRED=664` `H4_CLASS=MATCH_664` `pack=3b392b291b190b09` GO=7296 DONE=7296 |
| Silicon grant-soa | EVIDENCE | UART `NATIVE_V1_EXIST_ROW,pred=733` GRANT=1 CORE_DONE. Bit SHA `00517465…` |
| H4 (tiling/quant with correct hex+pack) | FALSIFIED as cause of 733 | H4 MATCH_664 |
| Silicon pack hex | MISSING | `.ctx_pack_o()` was tied off; UART `PACK` had no 16 hex |
| Live flash SHA vs hex `9A6BBC7A…` | MISSING | T2-SPI 2026-08-25 only |

## This bit (one instrument + already-landed RTL)

Product SHA locked in `build_go_h2pack_soc_00.tcl`:

- CDC REQUEST_HELD (unchanged) `5AF2FBDA…`
- Tile wait-busy 1-cycle D_GO (unchanged) `06F62A3A…`
- DMA (unchanged) `20BAE36E…`
- Core stall-idle freeze only if `st != ST_IDLE` `29D230FC…` (not in 733 bit)
- Bind S_START hold + S_WAIT re-pulse `C5F57AD1…` (not in 733 bit)
- Top grant `!soa_running` + **UART `PACK=` 16 hex** `1926EFCF…`

Golden compare on later UART: `PACK=3B392B291B190B09`.

## Gates

WNS≥0 TNS=0 BRAM36≤135 DRC ja-only waive CDC classify then `write_bitstream` → **BIT_OK**.

No `open_hw_manager`. No COM12. No BOARD_PASS.
