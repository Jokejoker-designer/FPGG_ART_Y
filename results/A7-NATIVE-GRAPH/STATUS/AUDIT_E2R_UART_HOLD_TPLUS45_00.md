# AUDIT — E2R-UART-HOLD-TPLUS45-00 (LISTEN-ONLY, CLASS=SILENT)

**Auditor:** `a7-evidence-auditor` (adversarial, VERIFY_ONLY)  
**Date:** 2026-08-28  
**Gate:** `E2R-UART-HOLD-TPLUS45-00` (existence side-lane; not `LOOP_STATE.next`)  
**Author claim:** LISTEN-ONLY **PASS_NARROW** / CLASS=`SILENT` (`a7-vivado-gate`)  
**MUST_READ_UNBLOCK_H5:** read. Next = ungated DIFF twin (not S2, not glue). This gate is not an encoder closeout; H5 / S2 / 01R-glue routes were not used.

```text
AUDIT: CLEAN
VERDICT: PASS_NARROW
CLASS=SILENT: supported (0 B / 0 lines, both windows; no CORE_DONE; no pred=664)
PROGRAM: NO
EXISTENCE: NO
BOARD_PASS: not_claimed
C_FIX: NONE
graph_late_materialize_00: DEFERRED
```

Gate PASS (listen completed and classed) is file-backed.  
0-byte after the preregistered recapture is **CLASS=SILENT**, not design FAIL, and not a TinyGPT / `pred=664` miss that falsifies the core.  
This is **not** `NATIVE_V1_EXISTENCE_BOARD_PASS`, **not** `NATIVE_V1_MINI_AI_BOARD_PASS`, **not** TinyGPT/`CORE_DONE`, and **not** a close of `graph_late_materialize_00`.

---

## Verdict line

`AUDIT: CLEAN` — no CRITICAL / MAJOR / MINOR that changes the listen-class claim.  
Forbidden PASS routes not taken. Control `W_STALL` / `PHASE=01` were not reused as this unit’s class. 0-byte was not sold as design FAIL.

---

## Independent re-derivation (headline numbers)

### UART hold files (this unit)

| Artifact | Claimed | Independent |
|----------|---------|-------------|
| `uart_hold.txt` | 0 B | **MATCH** — length 0; SHA256 `E3B0C44298FC1C149AFBF4C8996FB92427AE41E4649B934CA495991B7852B855` (empty-file digest); mtime 2026-08-28 11:47:59 |
| `uart_hold_retry.txt` | 0 B | **MATCH** — length 0; same empty SHA; mtime 2026-08-28 11:53:10 |
| Attempt 1 window | 11:37:58–11:47:59+07, 600.234 s | **MATCH** — `listen_stdout.log` `ELAPSED_S: 600.234`; `uart_hold.txt` mtime = claimed end |
| Attempt 2 (recapture) | 11:48:10–11:53:10+07, 300.328 s | **MATCH** — `listen_stdout_retry.log` `ELAPSED_S: 300.328`; `uart_hold_retry.txt` mtime = claimed end |
| `CORE_DONE` in hold | absent | **FACT** — 0 B files contain no lines; both transcripts `CORE_DONE: False` |
| `pred=` / `pred=664` in hold | absent | **FACT** — 0 B files contain no lines; both transcripts `PRED_LINES: NONE` |
| `BOOT` in hold | absent | **FACT** — 0 B; both transcripts `BOOT_SEEN: False` |
| CLASS | `SILENT` | **FACT** (class rule) — 0 useful lines after recapture; no `W_STALL`/`PHASE=`/`ATOM*`/`CORE_DONE`/`pred=` in this window |

Listen vehicle `E2R-UART-HOLD-PRED-00/listen_uart_hold.py` opens COM12 with `dtr=False` `rts=False`, never writes TX, never calls Vivado, stops early only on `pred=664`. Transcripts print `program=NO` both windows.

Dispatch allowed `--seconds 600` (or two ×300 if first is 0-byte). This unit ran 600 s then one 300 s recapture. Compliant.

### CONTROL (prior query; not this class)

| Item | Claimed | Independent |
|------|---------|-------------|
| Prior UART-HOLD 2×180 s | SILENT 0 B (11:05–11:12+07) | **MATCH** prior `AUDIT_E2R_UART_HOLD_PRED_00.md` |
| ATOMIC-SDONE last printed | `ATOM0=0000059C` / `ATOM1=0000059D` / `W_STALL` / `PHASE=01` | **FACT** — prior PROGRAM audit; not received in this hold |
| Bit SHA already on FPGA | `9DC0F8DF…` | **MATCH** on-disk bit; not programmed this gate |

Do **not** re-class this hold from the control tail. Closeout does not.

### PROGRAM = NO (this gate)

| Check | Result |
|-------|--------|
| TPLUS45 bag `program_*.log` / `open_hw_manager` | **absent** |
| `listen_uart_hold.py` JTAG / `program_hw_devices` | **absent** |
| ATOMIC `program_excl.log` mtime | 2026-08-28 **10:51:48** (prior PROGRAM gate only) |
| Bit file mtime | 2026-08-28 **01:55:44** (BUILD; not rewritten at T+45) |
| Bit SHA256 | `9DC0F8DFF7BF068A92ED3E5A1A5B66FF5C56BEB7D6B3FACA7911912D498F951B` — **MATCH** closeout |
| Any `*program*.log` / `vivado*.log` under board `results/A7-NATIVE-GRAPH` newer than 10:51:48 | **absent** |
| REARM tcl | exists from PREP (`program_e2r_uart_hold_rearm_00_excl.tcl` mtime 11:26:15); **not executed** this gate (no journal / no program log) |
| Workspace terminals `program_hw_devices` / `open_hw_manager` | **absent** |
| `BRIDGE.json` `lock.owner` | `grok` (R6 MIG). This listen did not take the lock. |
| `com12_authorized_gate` | still consumed `E2R-ATOMIC-SDONE-PROBE-00`. Listen-only; not a new program authorize. |
| DISPATCH last implementer line | `gate=E2R-UART-HOLD-TPLUS45-00` `agent=a7-vivado-gate` `program=false` `listen_only=true` |

`BRIDGE.board.program_authorized=true` is leftover from the consumed ATOMIC-SDONE authorize. It is **not** evidence a second program ran. No new program artifact exists after 10:51:48.

### Copied BUILD timing (not a listen metric)

WNS 0.372 / TNS 0.000 / WHS 0.013 / THS 0.000 / DSP 19 are **copied** from `E2R-ATOMIC-SDONE-PROBE-00` post-route BUILD. Closeout labels them “not re-run; BUILD provenance only” / “not re-measured.” Independently matched against that BUILD closeout. Not a silicon class input for this listen.

T+45 wall clock: last exclusive program 10:51:48 → attempt-1 open 11:37:58 ≈ 46 min. Closeout’s “~T+45 min @ 12.5 MHz” is **ENGINEERING_INFERENCE** (elapsed from prior program stamp + known `core_clk`), not a new measurement.

---

## Claim grades

| Claim | Grade | Note |
|-------|-------|------|
| PROGRAM=NO this gate | **FACT** | No new program log; bit mtime BUILD; listen script has no JTAG; REARM tcl not run |
| Two COM12 windows 600.234 s + 300.328 s | **FACT** | transcripts + archive mtimes match ends |
| UART_BYTES=0 both windows | **FACT** | two 0 B files; empty SHA |
| CLASS=`SILENT` | **FACT** (class rule) | 0 lines after recapture; not `STILL_STALL` / `CORE_DONE_LATER` / `PRED_LATER` |
| `CORE_DONE` absent this unit | **FACT** | 0 B |
| `pred=664` absent this unit | **FACT** | 0 B |
| 0-byte ≠ design FAIL | **FACT** (dispatch rule) | Recapture still 0 → SILENT; PASS_NARROW |
| 0-byte ≠ TinyGPT / existence falsifier | **FACT** | closeout + STATUS pointer; existence stays OPEN |
| H_CANDIDATE `SILENT` supported (this unit) | **FACT** | 0 B ×2 |
| H_RIVAL `CORE_DONE_LATER` / `PRED_LATER` not supported **in these windows** | **FACT** | 0 B |
| Silicon still stalled / TinyGPT still live | **UNKNOWN** | 0 B does not distinguish stall vs finished-without-UART vs quiet RX |
| Bit `9DC0F8DF…` still on FPGA at 11:37 | **ENGINEERING_INFERENCE** | Last exclusive program 10:51:48; no readback this gate |
| C_FIX=NONE | **FACT** | No RTL path in this bag; listen + closeout only |
| BOARD_PASS / EXISTENCE not claimed | **FACT** | closeout, STATUS pointer, DISPATCH `board_pass=false` `existence=false` |
| `graph_late_materialize_00` not closed | **FACT** | LOOP_STATE stays QUEUED / `deferred_by=EXISTENCE_BEFORE_QUALITY` |
| n=1 listen unit + 1 same-unit recapture | **FACT** | Descriptive; not a replication bag |
| WNS/TNS/WHS/THS/DSP this listen | **copied BUILD** | labelled; not re-measured |

---

## Forbidden PASS routes (searched)

| Route | Result |
|-------|--------|
| Self-declared BOARD_PASS / `NATIVE_V1_*_BOARD_PASS` | **absent** |
| Existence claimed without `pred=664` | **absent** — EXISTENCE not claimed |
| 0-byte sold as design FAIL or as TinyGPT-done / pred-miss falsifier | **absent** — class SILENT; PASS_NARROW; “does not falsify silicon still being stalled” |
| Re-class from ATOMIC-SDONE `W_STALL`/`PHASE=01` | **absent** |
| ATOM reprint treated as stop / new class | **absent** — ATOM lines not in hold |
| Reprogram / `open_hw_manager` / C-FIX / A2 / LiteScope / REARM tcl run | **absent** |
| Golden/expected edited to match | **absent** — empty files are empty |
| Host winner/answer/`pred=` | **absent** |
| Copied BUILD WNS sold as a new listen measurement | **absent** — labelled BUILD / not re-measured |
| H5 / S2 clamp / 01R-02M-LM06 glue | **absent** |
| Frozen LM-06 / 01R / 02M / SGO / F1x overwrite | **absent** — bit mtime still BUILD 01:55:44 |
| `graph_late_materialize_00` promoted | **absent** — stays DEFERRED |
| Grok `BRIDGE.lock` stolen | **absent** — `lock.owner=grok` |

---

## Dispatch vs LOOP_STATE (process)

| Item | Value |
|------|--------|
| `LOOP_STATE.next` / first remaining graph id | `graph_late_materialize_00` QUEUED, `deferred_by=EXISTENCE_BEFORE_QUALITY` |
| DISPATCH_LOG last **implementer** line | `E2R-UART-HOLD-TPLUS45-00` `agent=a7-vivado-gate` `result=PASS_NARROW` (main + board line 238) |
| last implementer `class` / bytes | `SILENT` `uart_bytes=0` `core_done=false` `pred=null` `listen_only=true` `program=false` `c_fix=NONE` `existence=false` `board_pass=false` |
| Side-lane exception | **allowed** — existence listen; not `graph_late_materialize_00`. Do **not** FAIL the auditor rule that last DISPATCH gate must equal first OPEN graph id. |

Last DISPATCH implementer may be this side-lane gate. That does **not** FAIL this audit. `graph_late_materialize_00` stays **DEFERRED**. Do **not** promote this PASS_NARROW to a graph-loop close.

---

## CLASS=SILENT — supported?

**Yes.** Dispatch classes: `SILENT` / `STILL_STALL` / `CORE_DONE_LATER` / `PRED_LATER`.  
Gate PASS = listen completed and classed. Existence only if exact `pred=664`.

This unit: COM12 open 600.234 s then recapture 300.328 s, 0 B after recapture, no `CORE_DONE`, no `pred=`.  
`STILL_STALL` requires `W_STALL` / `PHASE=` / ATOM reprint **in this window** — none received.

n=1 + one same-unit 0-byte recapture. Descriptive. Existence remains **OPEN**.

---

## Existence / BOARD_PASS

| Item | Value |
|------|--------|
| EXISTENCE | **NO** — `pred=664` not in this hold |
| BOARD_PASS | **not_claimed** |
| `NATIVE_V1_MINI_AI_BOARD_PASS` | **not claimed** |
| `NATIVE_V1_EXISTENCE_BOARD_PASS` | **not claimed** |
| C_FIX | **NONE** |
| PROGRAM this gate | **NO** |
| NEXT | existence still OPEN. Do not treat SILENT as design FAIL. Do not treat 0-byte as a TinyGPT falsifier. Do not reprogram without a new `com12_authorized_gate` (REARM still blocked). Do not dispatch `graph_late_materialize_00` from this side-lane. Auditor does not program. |

---

## NOT VERIFIED

- FPGA still holds SHA `9DC0F8DF…` at 11:37 — no JTAG readback this gate. Last exclusive program log is 10:51:48. Inference only.
- Whether COM12 RX was electrically live vs a quiet port after a successful `Serial.open` (script would have exited if open failed; that does not prove the FPGA TX path).
- Closeout’s parenthetical `COM3` / `COM4` listing — no `serial.tools.list_ports` dump in this bag. COM12 open succeeding is the evidenced fact.
- Bytes (if any) on COM12 between prior hold end 11:11:34 and this open 11:37:58 — **UNKNOWN** by construction; closeout does not sell that gap as observed silence.
- Whether silicon is still in `W_STALL`/`PHASE=01` or has moved without UART — 0 B cannot distinguish.
- Task-vs-parent authorship of the listen run beyond DISPATCH_LOG `agent=a7-vivado-gate`.

**Stop:** do not declare existence or BOARD_PASS. Do not upgrade SILENT to design FAIL. Do not falsify TinyGPT / `pred=664` from 0-byte. Do not program. Do not dispatch `graph_late_materialize_00` from this side-lane.
