# A7-LM-01 BOARD PASS — 2026-08-16

Official Digilent AXI MIG + on-FPGA BIST/DMA counters. No Transformer. No scale-up.

**Claim:** `ARTY_A7_DDR_FOUNDATION_BOARD_VALIDATED`

Not an LLM. Not A7-LM-02. Not the 1.5M family claim. Not native `app_*` (official `mig.prj` is AXI and was not hand-edited).

## Silicon

| | |
|--|--|
| Board | Digilent Arty A7-100T JTAG `210319BE776EA` / UART `210319BE776EB` |
| UART | COM12 115200 |
| Bit | `arty_a7_lm01.bit` `96065A174F22B6F79B6A04B79EBA4DDEF094B2BFAF36F5C93F0C376C679507B8` |
| WNS / TNS | +1.276 / 0 |
| MIG | official `mig.prj` `914A9E4BB1B3002837592944CDF49F8DFBAF4D112552DD8B5BE48602FF1AC329` AXI MT41K128M16 16-bit 333.3 MHz 4:1 256 MB |
| Frozen LM-00 | `449A330BD2E23E1D9714ECF94142A0555914D6C76EDE6310EF347A3596534783` unchanged |

## Gates (conjunctive, all met)

| Gate | Result |
|------|--------|
| `init_calib_complete` | 100/100 UART soft-reset (`0x16`, 100 ms hold) 0→1 |
| walking-1 / walking-0 | 0 errors (mode 1 + mode 0) |
| address-as-data | 0 errors |
| PRBS32 | 0 errors |
| sequential burst | 0 errors; 256 MB × 2 |
| random address | 0 errors (1 MB + 16 MB) |
| row/bank boundary | 0 errors |
| whole-memory equivalents | **5.234** (wr+rd 702 545 920 B each) |
| sequential read BW | **1.166 GB/s** (256-beat INCR; gate 0.85) |
| write / mixed / random BW | 1.152 / 1.159 / 0.533 GB/s recorded |
| WNS | +1.276 |
| post-recal 1 MB seq | pass, 1.177 GB/s |

Random/16-beat isolated reads sit ~0.53 GB/s because each 256 B burst pays MIG read latency. Sequential gate uses 256-beat bursts. That is a measurement choice, not a DRAM fail.

## Honest limits

- Host does not compute DDR data or check bytes; FPGA compares on chip.
- Soft-reset report bit is `calib && !sys_rst` so a 100 ms hold is visible over UART (`ui_clk` otherwise freezes `init_calib_complete`).
- AXI wrapper around unmodified Digilent preset. Program text preferred native `app_*`; compass forbade editing `mig.prj`.

## Next

A7-LM-02 DSP/BRAM tensor engine only after this archive is treated as frozen.
