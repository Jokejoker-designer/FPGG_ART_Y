# E2R-HB-UART-00 PREREGISTER

**Date:** 2026-08-25  
**Worktree:** `arty-a7-online-lm-board` ONLY  
**Parent decision:** Option **A** (early UART heartbeat) after Gate 4 COM12 silence

## ONE UNKNOWN
Does early UART heartbeat (`BOOT` / `MIG_OK` / `WMEM_OK` / `SOA_OK` / `CORE_START` / …) appear on COM12 after reprogram, localizing where silicon hangs before pred?

## Scientific frame
| Field | Value |
|-------|-------|
| OBSERVATION | T2 bit programmed; flash @0x400000 verified; COM12 0 bytes / 180s; no pred=664 |
| H_CANDIDATE | Hang is after fabric boot but before bind TX; staged HB localizes stage |
| H_RIVAL | UART pin/baud dead / clock never locks / STARTUPE2 QSPI (opt B) |
| FALSIFIER | Still 0 bytes after HB bit OR pred≠664 with full HB chain |
| UNIT | HB stage string ≠ clock cycle |
| CONTROL | Prior T2 bit SHA `993CB84F…E9F0`; flash image unchanged |

## Keep
- F2 decimal `pred=` digits
- No host weight poke; no full BOARD_PASS self-claim

## B1
PLAUSIBLE only — optional; not required for this unknown.
