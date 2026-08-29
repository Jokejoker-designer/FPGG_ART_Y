# E2R-ATOMIC-SDONE-PROBE-00 — PROGRAM GO (human board plugged)

**Agent:** `a7-vivado-gate`  
**Workspace:** `D:/Jetking_sem4/SEM_4/arty-a7-online-lm-board`  
**com12_authorized_gate:** `E2R-ATOMIC-SDONE-PROBE-00` only  
**Bit:** `results/A7-NATIVE-GRAPH/E2R-ATOMIC-SDONE-PROBE-00/arty_a7_ng_native_v1_atomic_sdone_probe_00.bit`  
**SHA256:** `9DC0F8DFF7BF068A92ED3E5A1A5B66FF5C56BEB7D6B3FACA7911912D498F951B`  
**JTAG:** `210319BE776EA` · COM12 115200  
**Arm COM12 before program.** No rebuild.

Human plugged 2026-08-28 ~10:46+07 after MASTER named this observer. Do **not** reprogram SGO `832E55E2…` or F1x `77116381…`.

## Do not

A2 / C-FIX / LiteScope / Phase 2 / UART strip / BOARD_PASS / sequential `SDONE=` as class / steal Grok R6 / second JTAG / PYNQ.

## Sequence

1. Re-read `BRIDGE.json`. STOP if `com12_authorized_gate` ≠ this id.
2. Re-hash bit = `9DC0F8DF…`.
3. Write `vivado/tcl/program_e2r_atomic_sdone_probe_00_excl.tcl` (copy SGO program tcl; this bit path only; refuse SGO/F1x/B-FIX/R6/frozen).
4. **Arm COM12 first** (adapt SGO `capture_uart_atom.py` to SDONE pack). 0-byte = recapture, not design FAIL.
5. Program JTAG `210319BE776EA` only.
6. Decode ATOM0/ATOM1. Class from ATOM0 UNIT.

## Pack (`[31:13]=0`, `[12:11]=0`)

| bits | field |
|------|--------|
| [2:0] | dest |
| [3] | owner |
| [4] | grant |
| [5] | idle |
| [6] | sdone latch |
| [7] | sdone sticky |
| [8] | w_stall |
| [9] | core_done |
| [10] | mgo |

Class: `NO_DST4` / `SDONE_HIT` (bit6 or bit7 =1) / `SDONE_MISS` (dest=4, both done 0, w_stall=0) / `WSTALL` (done=0 and w_stall=1).  
Gate PASS = rows decoded. Existence = `pred=664` only.
