# A7-LM-01 — DDR foundation

**Status:** BOARD_PASS — 2026-08-16. Claim `ARTY_A7_DDR_FOUNDATION_BOARD_VALIDATED`. Archive `releases/A7-LM-01-BOARD-PASS-20260816/`.  
**Requires:** A7-LM-00 BOARD_PASS  
**Authority:** `docs/architecture/PROGRAM.md`  
**Do not:** train Transformer, scale V/d, hand-edit `mig.prj`, start A7-LM-02.

## MIG (official, unmodified)

File: `third_party/digilent/arty-a7-100/E.0/1.0/mig.prj`  
SHA-256: `914A9E4BB1B3002837592944CDF49F8DFBAF4D112552DD8B5BE48602FF1AC329`

| Property | Value |
|----------|-------|
| FPGA | xc7a100t-csg324/-1 |
| Device | MT41K128M16XX-15E |
| Width | 16 |
| tCK | 3000 ps (~333.3 MHz) |
| PHY | 4:1 → UI 128-bit @ ~83.33 MHz |
| Map | BANK_ROW_COLUMN |
| Size | 268435456 bytes |
| Port | **AXI** (official Digilent — not edited) |

Conflict noted: program *recommends* native `app_*`. Official Digilent preset is AXI. Compass forbids hand-editing `mig.prj`. **AXI wins.** DMA/BIST are AXI masters.

## Gates (conjunctive)

| Gate | Pass |
|------|------|
| `init_calib_complete` | 100/100 soft-reset / re-calib |
| walking-1 / walking-0 | 0 errors |
| address-as-data | 0 errors |
| PRBS32 | 0 errors |
| sequential burst | 0 errors |
| random address | 0 errors |
| row/bank boundary | 0 errors |
| whole-memory equivalents | ≥ 4 (record bytes) |
| sequential read BW | ≥ 0.85 GB/s (prefer ≥ 0.95) |
| write / mixed / random BW | recorded |
| WNS | ≥ 0 |

Bitstream **separate**: `build/out/arty_a7_lm01.bit`. Do not overwrite `arty_a7_lm00.bit`.

## UART (15-byte A5)

Host → FPGA `A5 72 op a b … xor`

| op | meaning |
|----|---------|
| `0x13` | start BIST. `a`=mode 0..6, `b`=size 0=1MB / 1=16MB / 2=256MB |
| `0x14` | status → `0x81` flags=`{pass,busy,calib}` + phase + err |
| `0x15` | counters → `0x82` rd_bytes, rd_cycles, wr_bytes |
| `0x16` | soft-reset MIG (2 ms) then re-calib; UART domain stays up |
| `0x17` | write counters → `0x84` wr_cycles, wr_bytes |

Mode 0 runs walk1, walk0, addr, PRBS, seq, rand, bound in one pass.

LED0 = calib, LED1 = busy, LED2 = pass, LED3 = err≠0. SW0 = one-shot 1 MB BIST. SW1 = stream status. Keep both off for UART ladder.
