# E2R-UART-HOLD-LONG-00 — CLOSEOUT (CLASS SILENT, PROGRAM=NO)

**Agent:** `a7-vivado-gate`  
**Workspace:** `D:/Jetking_sem4/SEM_4/arty-a7-online-lm-board`  
**Authority:** `STATUS/E2R_UART_HOLD_LONG_DISPATCH.md`  
**BRIDGE.lock.owner:** grok (not stolen)  
**com12_authorized_gate:** consumed `E2R-UART-HOLD-REARM-00` (LISTEN-ONLY; REARM program authorize not reused)  
**PROGRAM:** **NO** (`open_hw_manager` / `program_hw_devices` / JTAG / rebuild / REARM tcl not used)  
**RESET:** **NO** (COM12 opened with `dtr=False` `rts=False`; `BOOT` not seen in either window)  
**UART:** COM12 115200 listen only via `E2R-UART-HOLD-PRED-00/listen_uart_hold.py`  
**UART_BYTES:** **0** (attempt 1 = 0 / 1800.297 s; one recapture attempt 2 = 0 / 300.312 s)  
**C_FIX:** **NONE**  
**BOARD_PASS:** **not claimed**  
**EXISTENCE:** **not claimed** (`pred=664` absent)

XSim ≠ board. One listen unit on one already-programmed REARM boot (plus the preregistered 0-byte recapture of the same unit). Class from **this** 1800 s hold window only. Did not use `capture_uart_atom.py` or `capture_uart_rearm.py`. No LiteScope/ILA. No A2 / Phase 2 / C-FIX. Did not reprogram bit `9DC0F8DF…`. Did not steal Grok `BRIDGE.lock`. Did not Task `graph_late_materialize_00`.

## Scientific frame

| Field | Value |
|-------|-------|
| OBSERVATION | REARM 300 s after ATOM1 → no CORE_DONE (CLASS STILL_STALL, 593 B, end `2026-08-28T12:08:23+07:00`). Unstall compute would finish in seconds. Refill @ ~1 ms/chunk ≈ 20 min. Gap 12:08–this listen unrecorded. |
| UNKNOWN | on the same programmed boot, if we listen **1800 s** now, does `CORE_DONE` or `pred=664` appear? |
| H_CANDIDATE | `WINDOW_SHORT` → `PRED_LATER` or `CORE_DONE_LATER` |
| H_RIVAL | `SILENT` (still no rows; does **not** falsify finish-in-gap 12:08–12:43) |
| FALSIFIER | program; DTR reset; 0-byte as design FAIL; ATOM-stop; C-FIX. **Not used.** |
| UNIT | one listen window on one already-programmed boot |
| CONTROL | REARM 300 s STILL_STALL; T+45 SILENT (earlier boot) |
| METRICS | bytes, class, `CORE_DONE`, `pred=`. Existence = exact `pred=664` only |

Gate PASS = listen completed and classed. Existence only if `pred=664`. 0-byte after recapture is class `SILENT`, not design FAIL.

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
| CONTROL | REARM `E2R-UART-HOLD-REARM-00` programmed this same SHA ~12:03+07 |

## UART hold (board listen; no arm-before-program)

| Window | Start (+07) | End (+07) | Elapsed | Bytes | `CORE_DONE` | `pred=` | Stop |
|--------|-------------|-----------|---------|-------|-------------|---------|------|
| Attempt 1 | 2026-08-28T12:43:55 | 2026-08-28T13:13:56 | 1800.297 s | **0** | no | none | window_elapsed |
| Attempt 2 (recapture) | 2026-08-28T13:26:57 | 2026-08-28T13:31:57 | 300.312 s | **0** | no | none | window_elapsed |

Authoritative file: `uart_hold.txt` (0 bytes). Recapture: `uart_hold_retry.txt` (0 bytes). Transcripts: `listen_stdout.log`, `listen_stdout_retry.log`.

COM12 was present before both windows (`COM3`, `COM4`, `COM12`) and opened both times (`dtr=False` `rts=False`). No TX. Did not stop on ATOM (ATOM lines did not appear). `BOOT` not seen (no evidence this listen reset the board). JTAG was not opened. No Vivado process and no `vivado_pid*.str` after the listen.

Operator interval 13:13:56–13:26:57+07 between windows is not a second unknown; recapture is the preregistered 0-byte retry of the same unit.

## Classification (exactly one, this hold unit)

**CLASS = SILENT**

0 useful lines after the preregistered recapture. Not `STILL_STALL` (that class requires `W_STALL` / `PHASE=` / ATOM reprint **in this window**). Not `CORE_DONE_LATER`. Not `PRED_LATER`.

| Class | This unit |
|-------|-----------|
| SILENT | **yes** (0 B / 0 lines, both windows) |
| STILL_STALL | no (no `W_STALL`/`PHASE` in hold) |
| CORE_DONE_LATER | no |
| PRED_LATER | no |

## Hypothesis status (this unit only)

| Hypothesis | Status |
|------------|--------|
| H_CANDIDATE (`WINDOW_SHORT` → `PRED_LATER` / `CORE_DONE_LATER`) | **not supported** — `CORE_DONE` absent; `pred=664` absent |
| H_RIVAL (`SILENT`) | **supported** — 0 B on attempt 1 (1800.297 s) and recapture (300.312 s) |

n=1 listen unit + 1 same-unit 0-byte recapture. Descriptive only. Does **not** falsify finish-in-gap 12:08–12:43 (REARM end to this listen start). It shows no further UART bytes in the 1800 s window plus 300 s recapture on the already-programmed REARM boot.

## Gate

| Item | Value |
|------|-------|
| GATE | E2R-UART-HOLD-LONG-00 |
| CHANGED | none (listen-only; no RTL; no program; no C-FIX) |
| TESTS | COM12 present; 1800.297 s listen; 0-byte recapture 300.312 s |
| EXPECTED | class `SILENT` / `STILL_STALL` / `CORE_DONE_LATER` / `PRED_LATER`; stop early only on `pred=664` |
| ACTUAL | CLASS=`SILENT`; UART 0 B both windows; `CORE_DONE` absent; `pred=` absent; no program |
| PASS\|FAIL | **PASS_NARROW** (listen completed and classed; 0-byte ≠ design FAIL) |
| CLASS | SILENT |
| pred | absent |
| UART_BYTES | 0 |
| C_FIX | NONE |
| PROGRAM | NO |
| BOARD_PASS | not_claimed |
| EXISTENCE | not_claimed (`pred=664` absent) |
| NEXT | `a7-evidence-auditor` on this listen PASS_NARROW; existence still OPEN; do not Task `graph_late_materialize_00` |
