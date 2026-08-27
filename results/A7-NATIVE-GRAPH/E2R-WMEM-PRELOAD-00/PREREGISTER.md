# E2R-WMEM-PRELOAD-00 — PREREGISTER

**Gate:** E2R-WMEM-PRELOAD-00  
**Date:** 2026-08-25  
**Worktree:** `arty-a7-online-lm-board` ONLY  
**Depends:** E2R-CLOCK-CDC-00 PASS (unsafe_cdc=0 sealed)

## ONE UNKNOWN

Can an FPGA-owned AXI master write exact **802816** B from frozen `a7lm06_wmem.hex` (SHA `9A6BBC7AC8AF82725CAFD0B50241EE683C07FB9943C754753025F3569967D10F`) to `DDR_WBASE=0x0010_0000`, assert `wmem_load_done`, and enforce boot firewall `core_start = mig_calib && wmem_load_done && soa_load_done`?

## Architecture (from T2_WMEM_BYTE_SPEC)

- Store for Gate 2 XSim verify: `$readmemh` into boot img[] (not silicon evidence)
- Silicon store (Gate 4): **T2-SPI** preferred — not claimed here
- Firewall wired in `arty_a7_ng_native_v1_ab_soc_top.sv`

## Falsifier

bytes_written ≠ 802816, readback mismatch, or core released before all three ready.

## Accept

| Check | Threshold |
|-------|-----------|
| bytes @ DDR_WBASE | 802816 exact match to frozen hex |
| wmem_load_done | 1 |
| firewall | core_rst_n requires calib∧soa∧wmem |
| BRAM (SoC) | ≤135 (no 802k ROM in synth) |
| Program | NO |
