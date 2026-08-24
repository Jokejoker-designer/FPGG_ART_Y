# CLOSEOUT — mig_board_r2

**Result:** PASS  
**Evidence_class:** BOARD_MIG  
**Agent:** a7-ng-memory-arch  
**Marker:** A7NG_MIG_BOARD_R2_OK  
**Artifact:** results/A7-NATIVE-GRAPH/MIG-BOARD-R2/BOARD_MIG_R2_SWEEP.md

## Unknown closed

Per-run metric_clear deltas reproduce on Digilent AXI MIG silicon across the full 4×4 burst×outstanding grid (16 cells). Integrity counters clean on every cell.

## Measured (file-backed: `board_uart_capture.uart.txt`)

- 16/16 grid cells captured after COM12-open-then-program procedure
- Marker `A7NG_MIG_BOARD_R2_OK` received
- All cells: axi_read_bytes=1024, axi_read_beats=64, data/rresp/rlast=0, exp/rcv/cons=64/64/64

## CONTROL

| cell | silicon | MIG-METRIC-00 XSim | match |
|------|---------|-------------------|-------|
| (1,1) | 1024 B / 64 bursts / 64 beats | 1024 / 64 / 64 | YES |
| (4,8) | 1024 B / 16 bursts / 64 beats | 1024 / 16 / 64 | YES |

## Falsifiers

| Falsifier | Fired? |
|-----------|--------|
| Invent GB/s | No |
| Feed/search law change | No |
| mig.prj hand-edit | No — SHA MATCH |
| AI BOARD_PASS | No |
| Quarantined rows cited as trusted | No |

## Bit / timing

- SHA256 `c08ae8634fe2b4568de0eaeed5f6e750bd3ef2b7aad4e401467afac3c01957cc`
- WNS +1.060 ns (HS-12 PASS; `wns.txt` post-route for bit `c08ae863…`)
- Board `210319BE776EA` programmed 2026-08-22 resume session

## NEXT

**STOP.** Parent verify trio + HLB. AI does not declare BOARD_PASS.

## Doc correction (2026-08-22)

Verify trio: WNS corrected to +1.060 ns (`wns.txt`); `BOARD_MIG_R2_SWEEP.md` stall_frac recomputed from raw UART; capture parser maps UART burst field `10` → 16. Silicon evidence unchanged.
