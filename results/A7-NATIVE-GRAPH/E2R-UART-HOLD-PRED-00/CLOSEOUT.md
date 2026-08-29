# E2R-UART-HOLD-PRED-00 — CLOSEOUT (CLASS SILENT, no BOARD_PASS)

**Agent:** `a7-vivado-gate`  
**Workspace:** `D:/Jetking_sem4/SEM_4/arty-a7-online-lm-board`  
**Authority:** `STATUS/E2R_UART_HOLD_PRED_DISPATCH.md`  
**com12_authorized_gate:** consumed `E2R-ATOMIC-SDONE-PROBE-00` (LISTEN-ONLY; not re-authorized to program)  
**PROGRAM:** **NO** (`open_hw_manager` / `program_hw_devices` / JTAG / rebuild not used)  
**RESET:** **NO** (COM12 opened with `dtr=False` `rts=False`; `BOOT` not seen in either window)  
**UART:** COM12 115200 listen only  
**UART_BYTES:** **0** (attempt 1 = 0; one recapture attempt 2 = 0)  
**C_FIX:** **NONE**  
**BOARD_PASS:** **not claimed**  
**EXISTENCE:** **not claimed** (`pred=664` absent)

XSim ≠ board. One listen unit (plus the preregistered 0-byte recapture of the same unit). Class from **this** hold window only — do not re-class from the ATOMIC-SDONE control capture. ATOM reprints are not a stop condition and were not observed. No LiteScope/ILA. No A2 / Phase 2. Did not reprogram bit `9DC0F8DF…`. Did not steal Grok `BRIDGE.lock`.

## Scientific frame

| Field | Value |
|-------|-------|
| OBSERVATION | Control UART `E2R-ATOMIC-SDONE-PROBE-00/uart_capture.txt` (593 B) ended `ATOM1=0000059D` `W_STALL` `PHASE=01`. CLASS=SDONE_HIT. `core_done` bit 0. `pred=664` absent. Bit SHA `9DC0F8DF…` already on FPGA. |
| UNKNOWN | On that already-programmed bit, if COM12 is listened ≥180 s without reprogram, does `CORE_DONE` or `pred=664` appear? |
| H_CANDIDATE | `SILENT` or `STILL_STALL` |
| H_RIVAL | `CORE_DONE_LATER` or `PRED_LATER` (`pred=664`) |
| FALSIFIER | reprogram; stop at ATOM; C-FIX. **Not used.** |
| UNIT | one listen window ≥180 s or until `pred=664`; 0-byte → one recapture of the same unit |
| CONTROL | `uart_capture.txt` last lines `ATOM1=` + `W_STALL` + `PHASE=01` |
| METRICS | bytes, `CORE_DONE` present, `pred=` value. Existence = exact `pred=664` only. |

Gate PASS = listen completed and classed. Existence only if `pred=664`. 0-byte after recapture is class `SILENT`, not design FAIL by itself.

## Numeric gates (not re-run; BUILD provenance only)

This gate did not start Vivado. Post-route numbers below are **copied** from `E2R-ATOMIC-SDONE-PROBE-00` BUILD (bit already on the FPGA). They are not new measurements of this listen.

| Metric | Value | Provenance | Gate |
|--------|-------|------------|------|
| WNS | 0.372 ns | post-route BUILD `E2R-ATOMIC-SDONE-PROBE-00` | not re-measured |
| TNS | 0.000 ns | post-route BUILD | not re-measured |
| WHS | 0.013 ns | post-route BUILD | not re-measured |
| THS | 0.000 ns | post-route BUILD | not re-measured |
| DSP | 19 | post-route BUILD (SoC; not encoder DSP=0) | not re-measured |

## Bit (not programmed this gate)

| Item | Value |
|------|-------|
| ARTIFACT (already on FPGA) | `results/A7-NATIVE-GRAPH/E2R-ATOMIC-SDONE-PROBE-00/arty_a7_ng_native_v1_atomic_sdone_probe_00.bit` |
| SHA256 | `9DC0F8DFF7BF068A92ED3E5A1A5B66FF5C56BEB7D6B3FACA7911912D498F951B` |
| This gate | listen only; bit file not opened for program |

## UART hold (board listen; no arm-before-program)

| Window | Start (+07) | End (+07) | Elapsed | Bytes | `CORE_DONE` | `pred=` | Stop |
|--------|-------------|-----------|---------|-------|-------------|---------|------|
| Attempt 1 | 2026-08-28T11:05:14 | 2026-08-28T11:08:14 | 180.297 s | **0** | no | none | window_elapsed |
| Attempt 2 (recapture) | 2026-08-28T11:08:34 | 2026-08-28T11:11:34 | 180.219 s | **0** | no | none | window_elapsed |

Authoritative file: `uart_hold.txt` (0 bytes). Copies: `uart_hold_attempt1.txt`, `uart_hold_attempt2.txt`. Transcript: `listen_stdout.log`.

COM12 was present and opened both times (`dtr=False` `rts=False`). No TX. Did not stop on ATOM (ATOM lines did not appear). `BOOT` not seen (no evidence this listen reset the board).

**Gap caveat (descriptive, not a new class):** control capture closed ~10:52+07; hold attempt 1 opened 11:05:14+07. Bytes printed in that gap were not recorded by this unit. This class is for the two ≥180 s windows only.

## Classification (exactly one, this hold unit)

**CLASS = SILENT**

0 useful lines after the preregistered recapture. Not `STILL_STALL` (that class requires `W_STALL` / `PHASE=` / ATOM reprint **in this window**). Not `CORE_DONE_LATER`. Not `PRED_LATER`.

| Class | This unit |
|-------|-----------|
| SILENT | **yes** (0 B / 0 lines, both windows) |
| STILL_STALL | no (no `W_STALL`/`PHASE` in hold) |
| CORE_DONE_LATER | no |
| PRED_LATER | no |

Control-capture `W_STALL` `PHASE=01` remains the prior query's last printed state. It is not reprinted here and is not this gate's class.

## Hypothesis status (this unit only)

| Hypothesis | Status |
|------------|--------|
| H_CANDIDATE (`SILENT`) | **supported** — 0 B on attempt 1 and recapture |
| H_CANDIDATE (`STILL_STALL`) | **not supported in this window** — no stall/PHASE lines received |
| H_RIVAL (`CORE_DONE_LATER`) | **not supported** — `CORE_DONE` absent |
| H_RIVAL (`PRED_LATER`) | **not supported** — `pred=664` absent |

n=1 listen unit + 1 same-unit 0-byte recapture. Descriptive only. Does not falsify silicon still being stalled; it shows no further UART bytes in two 180 s holds.

## Gate

| Item | Value |
|------|-------|
| GATE | E2R-UART-HOLD-PRED-00 |
| CHANGED | none (listen-only script + archive; no RTL; no program; no C-FIX) |
| TESTS | COM12 open (no DTR/RTS); 180.297 s listen; 0-byte recapture 180.219 s |
| EXPECTED | class `SILENT` / `STILL_STALL` / `CORE_DONE_LATER` / `PRED_LATER`; stop early only on `pred=664` |
| ACTUAL | CLASS=`SILENT`; UART 0 B both windows; `CORE_DONE` absent; `pred=` absent; no program |
| PASS\|FAIL | **PASS_NARROW** (listen completed and classed; 0-byte ≠ design FAIL) |
| CLASS | SILENT |
| pred | absent |
| UART_BYTES | 0 |
| C_FIX | NONE |
| BOARD_PASS | not_claimed |
| EXISTENCE | not_claimed (`pred=664` absent) |
| NEXT | `a7-evidence-auditor` on this listen PASS_NARROW; existence still OPEN |
