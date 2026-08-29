# E2R-UART-HOLD-LONGBOOT-PREP-00 — pointer CLOSEOUT (PREP_READY, PROGRAM=NO)

Copy-ready for main-tree STATUS. Authoritative bag: `D:/Jetking_sem4/SEM_4/arty-a7-online-lm-board/results/A7-NATIVE-GRAPH/E2R-UART-HOLD-LONGBOOT-00/CLOSEOUT.md`.

| Field | Value |
|-------|-------|
| GATE | E2R-UART-HOLD-LONGBOOT-PREP-00 |
| AGENT | a7-vivado-gate |
| CLASS | **PREP_READY** |
| PROGRAM | **NO** |
| SHA256 | `9DC0F8DFF7BF068A92ED3E5A1A5B66FF5C56BEB7D6B3FACA7911912D498F951B` |
| BIT | `results/A7-NATIVE-GRAPH/E2R-ATOMIC-SDONE-PROBE-00/arty_a7_ng_native_v1_atomic_sdone_probe_00.bit` |
| CAPTURE | `results/A7-NATIVE-GRAPH/E2R-UART-HOLD-LONGBOOT-00/capture_uart_longboot.py` |
| TCL | `vivado/tcl/program_e2r_uart_hold_longboot_00_excl.tcl` + bag copy |
| ATOM-stop in new script | **absent** (grep 0 for `STOP: ATOM0+ATOM1` and `if has0 and has1: break`) |
| hold_after_atom_s | 2400 default (refuse `<2400`) |
| max_s | 2700 default (refuse `<2700`) |
| Marker | `E2R_UART_HOLD_LONGBOOT_PREP_00_READY` |
| BOARD_PASS | not_claimed |
| EXISTENCE | not_claimed |
| C_FIX | NONE |
| graph_late_materialize_00 | not tasked |
| BRIDGE.lock.owner | grok (unchanged) |
| com12_authorized_gate | still consumed `E2R-UART-HOLD-REARM-00` |
| NEXT | `E2R-UART-HOLD-LONGBOOT-00` only after `com12_authorized_gate` is exactly that id |

Do not program. Do not claim BOARD_PASS or EXISTENCE from this PREP.
