# E2R-UART-HOLD-LONGBOOT-PREP-00 — CLOSEOUT (PREP_READY, PROGRAM=NO)

**Agent:** `a7-vivado-gate`  
**Workspace:** `D:/Jetking_sem4/SEM_4/arty-a7-online-lm-board`  
**Authority:** `STATUS/E2R_UART_HOLD_LONGBOOT_PREP_DISPATCH.md`  
**BRIDGE.lock.owner:** grok (not stolen)  
**com12_authorized_gate:** leftover consumed `E2R-UART-HOLD-REARM-00` — **not used**  
**PROGRAM:** **NO** (no `open_hw_manager`, no `program_hw_devices`, no COM12)  
**C_FIX:** **NONE**  
**BOARD_PASS:** **not claimed**  
**EXISTENCE:** **not claimed**  
**Marker:** `E2R_UART_HOLD_LONGBOOT_PREP_00_READY`

XSim ≠ board. This PREP freezes a from-boot ≥2400 s after-ATOM1 capture vehicle. It does **not** run that listen. REARM 300 s `STILL_STALL` and LONG listen SILENT (late window) are CONTROL, not this unit. Did not Task `graph_late_materialize_00`.

## Scientific frame

| Field | Value |
|-------|-------|
| OBSERVATION | CORE_PRED + OSC_2ND + FWD_HEAVY (`rg_switches=2048`). REARM 300 s STILL_STALL. LONG listen SILENT was a late window, not a from-boot 40 min test. |
| UNKNOWN | can we freeze a ≥2400 s after-ATOM1 capture vehicle + exclusive same-bit program path without programming? |
| H_CANDIDATE | `PREP_READY` |
| H_RIVAL | `PREP_FAIL` |
| FALSIFIER | any program this turn; C-FIX; leftover 300 s defaults as the only knobs. **Not used.** |
| UNIT | one capture script + one exclusive tcl + SHA verify |
| CONTROL | `capture_uart_rearm.py` hold 300 / max 600; REARM excl tcl |
| METRICS | no ATOM-stop; `hold_after_atom_s>=2400`; `max_s>=2700`; bit SHA `9DC0F8DF…`; PROGRAM=NO |

## Vehicle (board worktree; not executed)

| Item | Value | Provenance |
|------|-------|------------|
| CAPTURE | `results/A7-NATIVE-GRAPH/E2R-UART-HOLD-LONGBOOT-00/capture_uart_longboot.py` | new file; SHA256 `3ABE6425BFA65B1ADA4E748977B71B42690A16A86DC9E68D82D28901C3B669F7`; 8571 B |
| Open | COM12 115200; `dtr=False` `rts=False` | copy of REARM `open_com_no_reset` |
| ATOM-stop | **absent** | grep 0 for `STOP: ATOM0+ATOM1` and `if has0 and has1` |
| Early stop | `pred=664` / `PRED=664` only | first `break` is `_has_pred_664` |
| hold_after_atom_s | default **2400**; refuse `<2400` | argparse; CONTROL 300 leftover is not a knob |
| max_s | default **2700**; refuse `<2700` | argparse; CONTROL 600 leftover is not a knob |
| Classes | `PRED_LATER` / `CORE_DONE_LATER` / `STILL_STALL` / `SILENT` / `NO_ATOM` | same `classify()` as REARM |
| Executed this gate | **NO** | no `uart_longboot.txt`; COM12 not opened |

## Exclusive program tcl (archived; **not run**)

| Item | Value | Provenance |
|------|-------|------------|
| Vivado copy | `vivado/tcl/program_e2r_uart_hold_longboot_00_excl.tcl` | SHA256 `A825187D7D4AE42D068DF6198F8EDE2A227AF601CF447465194A2B569B029E5F`; 3188 B |
| Bag copy | `E2R-UART-HOLD-LONGBOOT-00/program_e2r_uart_hold_longboot_00_excl.tcl` | byte-identical to vivado copy |
| Bit name | only `arty_a7_ng_native_v1_atomic_sdone_probe_00.bit` under `E2R-ATOMIC-SDONE-PROBE-00` | `bit_name` + path-match refuse |
| JTAG | `210319BE776EA`; refuse 2nd target / PYNQ / `1234-TUL` / `xc7z020` | file text |
| Refuse | SGO / F1x / B-FIX / R6 / frozen / lm06 | refuse list only |
| `[\s\S]` | **absent** | grep 0 both copies |
| `e2r_la_pmod_ja.xdc` | **omitted** (not sourced) | comment-only omit; no `read_xdc` / `source` |
| Executed this gate | **NO** | no `program_*.log` / `*.jou` in this bag |

## Bit (re-hashed; not rewritten)

| Item | Value | Provenance |
|------|-------|------------|
| ARTIFACT | `results/A7-NATIVE-GRAPH/E2R-ATOMIC-SDONE-PROBE-00/arty_a7_ng_native_v1_atomic_sdone_probe_00.bit` | existing BUILD |
| SHA256 | `9DC0F8DFF7BF068A92ED3E5A1A5B66FF5C56BEB7D6B3FACA7911912D498F951B` | PowerShell `Get-FileHash -Algorithm SHA256` |
| Size | 3826011 B | filesystem |
| mtime | 2026-08-28 01:55:44 | BUILD; not rewritten this PREP |

## Numeric gates (not re-run)

This gate did not synth/impl/XSim. Post-route numbers remain BUILD provenance of `E2R-ATOMIC-SDONE-PROBE-00`.

| Metric | Value | Provenance | Gate |
|--------|-------|------------|------|
| WNS | 0.372 ns | post-route BUILD (not re-run) | PASS (≥0) prior bag |
| TNS | 0.000 ns | post-route BUILD (not re-run) | PASS (=0) prior bag |
| DSP | 19 | post-route BUILD SoC (not encoder DSP=0) | reported prior bag |

## Hypothesis status (this unit only)

| Hypothesis | Status |
|------------|--------|
| H_CANDIDATE (`PREP_READY`) | **supported** — vehicle + SHA match + exclusive tcl on disk; PROGRAM=NO; floors 2400/2700 |
| H_RIVAL (`PREP_FAIL`) | **not supported** — ATOM-stop absent; 300/600 not the knobs; bit SHA match; no program |

PREP_READY is a file-backed class, not a silicon class. Existence remains OPEN.

## Gate

| Item | Value |
|------|-------|
| GATE | E2R-UART-HOLD-LONGBOOT-PREP-00 |
| CLASS | PREP_READY |
| CHANGED | capture vehicle + archived excl tcl + this CLOSEOUT. No RTL. No rebuild. |
| TESTS | re-hash bit; grep ATOM-stop=0; defaults 2400/2700; tcl SHA match; PROGRAM=NO |
| EXPECTED | PREP_READY or PREP_FAIL; this bit SHA only; PROGRAM=NO |
| ACTUAL | CLASS=`PREP_READY`; SHA `9DC0F8DF…`; PROGRAM=NO |
| PASS\|FAIL | **PASS_NARROW** (vehicle frozen; not a listen) |
| PROGRAM | NO |
| C_FIX | NONE |
| BOARD_PASS | not_claimed |
| EXISTENCE | not_claimed |
| graph_late_materialize_00 | not tasked |
| NEXT | wait new `com12_authorized_gate=E2R-UART-HOLD-LONGBOOT-00`; then program+capture. Do not program from this PREP. |
