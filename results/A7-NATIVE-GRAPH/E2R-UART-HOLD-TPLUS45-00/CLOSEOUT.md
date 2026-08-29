# E2R-UART-HOLD-TPLUS45-00 — CLOSEOUT (CLASS SILENT, PROGRAM=NO)

**Agent:** `a7-vivado-gate`  
**Workspace:** `D:/Jetking_sem4/SEM_4/arty-a7-online-lm-board`  
**Authority:** `STATUS/E2R_UART_HOLD_TPLUS45_DISPATCH.md`  
**com12_authorized_gate:** consumed `E2R-ATOMIC-SDONE-PROBE-00` (LISTEN-ONLY; not re-authorized to program)  
**PROGRAM:** **NO** (`open_hw_manager` / `program_hw_devices` / JTAG / rebuild / REARM tcl not used)  
**RESET:** **NO** (COM12 opened with `dtr=False` `rts=False`; `BOOT` not seen in either window)  
**UART:** COM12 115200 listen only via `E2R-UART-HOLD-PRED-00/listen_uart_hold.py`  
**UART_BYTES:** **0** (attempt 1 = 0 / 600.234 s; one recapture attempt 2 = 0 / 300.328 s)  
**C_FIX:** **NONE**  
**BOARD_PASS:** **not claimed**  
**EXISTENCE:** **not claimed** (`pred=664` absent)

XSim ≠ board. One listen unit on one already-programmed boot (plus the preregistered 0-byte recapture of the same unit). Class from **this** T+45 hold window only. Did not use `capture_uart_atom.py` or `capture_uart_rearm.py`. No LiteScope/ILA. No A2 / Phase 2. Did not reprogram bit `9DC0F8DF…`. Did not steal Grok `BRIDGE.lock`. Did not Task `graph_late_materialize_00`.

## Scientific frame

| Field | Value |
|-------|-------|
| OBSERVATION | SDONE_HIT ~10:51 ATOM0=`0000059C`. ATOM capture truncated. Listen 11:05–11:12 SILENT 0 B. `hb_next` prints CORE_DONE/PRED if flags rise. This unit ~T+45 min @ 12.5 MHz. |
| UNKNOWN | without reprogram, does COM12 now show `CORE_DONE` or `pred=664`? |
| H_CANDIDATE | `SILENT` |
| H_RIVAL | `PRED_LATER` or `CORE_DONE_LATER` |
| FALSIFIER | 0-byte as design FAIL; any program; DTR reset; ATOM-stop script. **Not used.** |
| UNIT | one listen window on one already-programmed boot |
| CONTROL | UART-HOLD 2×180 s SILENT; same bit SHA `9DC0F8DF…` |
| METRICS | bytes, class, `CORE_DONE`, `pred=` value. Existence = exact `pred=664` only |

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

## UART hold (board listen; no arm-before-program)

| Window | Start (+07) | End (+07) | Elapsed | Bytes | `CORE_DONE` | `pred=` | Stop |
|--------|-------------|-----------|---------|-------|-------------|---------|------|
| Attempt 1 | 2026-08-28T11:37:58 | 2026-08-28T11:47:59 | 600.234 s | **0** | no | none | window_elapsed |
| Attempt 2 (recapture) | 2026-08-28T11:48:10 | 2026-08-28T11:53:10 | 300.328 s | **0** | no | none | window_elapsed |

Authoritative file: `uart_hold.txt` (0 bytes). Recapture: `uart_hold_retry.txt` (0 bytes). Transcripts: `listen_stdout.log`, `listen_stdout_retry.log`.

COM12 was present (`COM3`, `COM4`, `COM12`) and opened both times (`dtr=False` `rts=False`). No TX. Did not stop on ATOM (ATOM lines did not appear). `BOOT` not seen (no evidence this listen reset the board). JTAG was not opened.

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
| H_CANDIDATE (`SILENT`) | **supported** — 0 B on attempt 1 (600 s) and recapture (300 s) |
| H_RIVAL (`CORE_DONE_LATER`) | **not supported** — `CORE_DONE` absent |
| H_RIVAL (`PRED_LATER`) | **not supported** — `pred=664` absent |

n=1 listen unit + 1 same-unit 0-byte recapture. Descriptive only. Does not falsify silicon still being stalled; it shows no further UART bytes in the T+45 600 s window plus 300 s recapture.

## Gate

| Item | Value |
|------|-------|
| GATE | E2R-UART-HOLD-TPLUS45-00 |
| CHANGED | none (listen-only; no RTL; no program; no C-FIX) |
| TESTS | COM12 present; 600.234 s listen; 0-byte recapture 300.328 s |
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
| NEXT | `a7-evidence-auditor` on this listen PASS_NARROW; existence still OPEN; REARM still blocked without new `com12_authorized_gate` |
