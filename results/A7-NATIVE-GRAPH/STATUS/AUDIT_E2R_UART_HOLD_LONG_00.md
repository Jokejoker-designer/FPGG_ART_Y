# AUDIT — E2R-UART-HOLD-LONG-00 (LISTEN-ONLY, CLASS=SILENT)

**Auditor:** `a7-evidence-auditor` (adversarial, VERIFY_ONLY)  
**Date:** 2026-08-28  
**Gate:** `E2R-UART-HOLD-LONG-00` (existence side-lane; not `LOOP_STATE.next`)  
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
WINDOW_SHORT: not supported this window (does NOT falsify finish-in-gap 12:08–12:43)
graph_late_materialize_00: DEFERRED
```

Gate PASS (listen completed and classed) is file-backed.  
0-byte after the preregistered recapture is **CLASS=SILENT**, not design FAIL, and not a TinyGPT / `pred=664` falsifier.  
`WINDOW_SHORT` is **not supported** on this 1800 s + 300 s unit. That does **not** falsify finish-in-gap 12:08–12:43 (REARM end to this listen start; gap unrecorded).  
This is **not** `NATIVE_V1_EXISTENCE_BOARD_PASS`, **not** `NATIVE_V1_MINI_AI_BOARD_PASS`, **not** TinyGPT/`CORE_DONE`, and **not** a close of `graph_late_materialize_00`.

---

## Verdict line

`AUDIT: CLEAN` — no CRITICAL / MAJOR / MINOR that changes the listen-class claim.  
Forbidden PASS routes not taken. Control `W_STALL` / `PHASE=01` were not reused as this unit’s class. 0-byte was not sold as design FAIL. `WINDOW_SHORT` was not sold as a gap falsifier.

---

## Independent re-derivation (headline numbers)

### UART hold files (this unit)

| Artifact | Claimed | Independent |
|----------|---------|-------------|
| `uart_hold.txt` | 0 B | **MATCH** — length 0; SHA256 `E3B0C44298FC1C149AFBF4C8996FB92427AE41E4649B934CA495991B7852B855` (empty-file digest); mtime 2026-08-28 13:13:56 |
| `uart_hold_retry.txt` | 0 B | **MATCH** — length 0; same empty SHA; mtime 2026-08-28 13:31:57 |
| Attempt 1 window | 12:43:55–13:13:56+07, 1800.297 s | **MATCH** — `listen_stdout.log` `ELAPSED_S: 1800.297`; `uart_hold.txt` mtime = claimed end |
| Attempt 2 (recapture) | 13:26:57–13:31:57+07, 300.312 s | **MATCH** — `listen_stdout_retry.log` `ELAPSED_S: 300.312`; `uart_hold_retry.txt` mtime = claimed end |
| `CORE_DONE` in hold | absent | **FACT** — 0 B files contain no lines; both transcripts `CORE_DONE: False` |
| `pred=` / `pred=664` in hold | absent | **FACT** — 0 B files contain no lines; both transcripts `PRED_LINES: NONE` |
| `BOOT` in hold | absent | **FACT** — 0 B; both transcripts `BOOT_SEEN: False` |
| CLASS | `SILENT` | **FACT** (class rule) — 0 useful lines after recapture; no `W_STALL`/`PHASE=`/`ATOM*`/`CORE_DONE`/`pred=` in this window |

Listen vehicle `E2R-UART-HOLD-PRED-00/listen_uart_hold.py` opens COM12 with `dtr=False` `rts=False`, never writes TX, never calls Vivado, stops early only on `pred=664`. Transcripts print `program=NO` both windows.

Dispatch required `--seconds 1800` then one 300 s recapture if 0-byte. This unit ran 1800.297 s then one 300.312 s recapture. Compliant.

Operator interval 13:13:56–13:26:57+07 is the same-unit recapture gap, not a second unknown.

### CONTROL (prior query; not this class)

| Item | Claimed | Independent |
|------|---------|-------------|
| REARM CLASS | `STILL_STALL`, 593 B, end `2026-08-28T12:08:23+07:00` | **MATCH** — `uart_rearm.txt` length 593; mtime 12:08:23; tail `ATOM1=0000059D` / `W_STALL` / `PHASE=01`; no `CORE_DONE`; no `pred=` |
| REARM program session | ~12:03+07 | **MATCH** — `program_excl.log` mtime 2026-08-28 12:03:23 |
| T+45 prior boot | SILENT 0 B | **MATCH** prior `AUDIT_E2R_UART_HOLD_TPLUS45_00.md` (earlier boot; not this unit) |
| Bit SHA already on FPGA | `9DC0F8DF…` | **MATCH** on-disk bit; not programmed this gate |

Do **not** re-class this hold from the REARM tail. Closeout does not.

### PROGRAM = NO (this gate)

| Check | Result |
|-------|--------|
| HOLD-LONG bag `program_*.log` / `open_hw_manager` | **absent** |
| `listen_uart_hold.py` JTAG / `program_hw_devices` | **absent** |
| REARM `program_excl.log` mtime | 2026-08-28 **12:03:23** (prior PROGRAM gate only) |
| ATOMIC `program_excl.log` mtime | 2026-08-28 **10:51:48** (earlier PROGRAM gate) |
| Bit file mtime | 2026-08-28 **01:55:44** (BUILD; not rewritten at LONG) |
| Bit SHA256 | `9DC0F8DFF7BF068A92ED3E5A1A5B66FF5C56BEB7D6B3FACA7911912D498F951B` — **MATCH** closeout |
| Any other `*program*.log` under board `results/A7-NATIVE-GRAPH` newer than REARM 12:03:23 | **absent** (REARM’s own log only) |
| `vivado*.log` / `vivado_pid*.str` newer than REARM end 12:08 | **absent** |
| Workspace terminals `program_hw_devices` / `open_hw_manager` | **absent** |
| `BRIDGE.json` `lock.owner` | `grok` (R6 MIG). This listen did not take the lock. |
| `com12_authorized_gate` | consumed `E2R-UART-HOLD-REARM-00`. Listen-only; REARM program authorize not reused. |
| DISPATCH last implementer line | `gate=E2R-UART-HOLD-LONG-00` `agent=a7-vivado-gate` `program=false` `listen_only=true` |

`BRIDGE.board.program_authorized=true` is leftover from the consumed REARM authorize. It is **not** evidence a second program ran. No new program artifact exists after 12:03:23.

### Gap 12:08–12:43 (unrecorded)

| Bound | Artifact |
|-------|----------|
| REARM capture write | `uart_rearm.txt` mtime **12:08:23+07** |
| LONG attempt 1 open | **12:43:55+07** (`listen_stdout.log`) |

≈35.5 min unrecorded. Closeout caveat matches the files. Bytes in that interval were **not** captured by this unit.

Therefore: `pred=664` (or `CORE_DONE`) **in the gap** is **UNKNOWN**, not falsified.  
`WINDOW_SHORT` “not supported” applies to the 1800 s + 300 s hold windows only. Closeout does **not** claim that this SILENT class falsifies finish-in-gap 12:08–12:43.

### Copied BUILD timing (not a listen metric)

WNS 0.372 / TNS 0.000 / WHS 0.013 / THS 0.000 / DSP 19 are **copied** from `E2R-ATOMIC-SDONE-PROBE-00` post-route BUILD. Closeout labels them “not re-run; BUILD provenance only” / “not re-measured.” Independently matched against that BUILD closeout. Not a silicon class input for this listen.

---

## Claim grades

| Claim | Grade | Note |
|-------|-------|------|
| PROGRAM=NO this gate | **FACT** | No new program log; bit mtime BUILD; listen script has no JTAG; REARM tcl not run |
| Two COM12 windows 1800.297 s + 300.312 s | **FACT** | transcripts + archive mtimes match ends |
| UART_BYTES=0 both windows | **FACT** | two 0 B files; empty SHA |
| CLASS=`SILENT` | **FACT** (class rule) | 0 lines after recapture; not `STILL_STALL` / `CORE_DONE_LATER` / `PRED_LATER` |
| `CORE_DONE` absent this unit | **FACT** | 0 B |
| `pred=664` absent this unit | **FACT** | 0 B |
| 0-byte ≠ design FAIL | **FACT** (dispatch rule) | Recapture still 0 → SILENT; PASS_NARROW |
| 0-byte ≠ TinyGPT / existence falsifier | **FACT** | closeout + STATUS pointer; existence stays OPEN |
| H_CANDIDATE `WINDOW_SHORT` → later pred/CORE_DONE | **not supported** (this window) | no later rows in 1800 s + 300 s |
| H_RIVAL `SILENT` supported (this unit) | **FACT** | 0 B ×2 |
| Finish-in-gap 12:08–12:43 | **UNKNOWN** | gap not recorded; closeout does **not** falsify it |
| Silicon still stalled / TinyGPT still live | **UNKNOWN** | 0 B does not distinguish stall vs finished-without-UART vs quiet RX |
| Bit `9DC0F8DF…` still on FPGA at 12:43 | **ENGINEERING_INFERENCE** | Last exclusive program 12:03:23; no readback this gate |
| “Unstall compute would finish in seconds”; “Refill @ ~1 ms/chunk ≈ 20 min” | **ENGINEERING_INFERENCE** | OBSERVATION context for window length; not a measured listen metric |
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
| 0-byte sold as design FAIL or as TinyGPT-done / pred-miss falsifier | **absent** — class SILENT; PASS_NARROW |
| `WINDOW_SHORT` sold as falsified across the 12:08–12:43 gap | **absent** — “not supported” this window; “does **not** falsify finish-in-gap” |
| Re-class from REARM `W_STALL`/`PHASE=01` | **absent** |
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
| DISPATCH_LOG last **implementer** line | `E2R-UART-HOLD-LONG-00` `agent=a7-vivado-gate` `result=PASS_NARROW` (main + board line 249) |
| last implementer `class` / bytes | `SILENT` `uart_bytes=0` `core_done=false` `pred=null` `listen_only=true` `program=false` `c_fix=NONE` `existence=false` `board_pass=false` |
| Side-lane exception | **allowed** — existence listen; not `graph_late_materialize_00`. Do **not** FAIL the auditor rule that last DISPATCH gate must equal first OPEN graph id. |

Last DISPATCH implementer may be this side-lane gate. That does **not** FAIL this audit. `graph_late_materialize_00` stays **DEFERRED**. Do **not** promote this PASS_NARROW to a graph-loop close.

---

## CLASS=SILENT — supported?

**Yes.** Dispatch classes: `SILENT` / `STILL_STALL` / `CORE_DONE_LATER` / `PRED_LATER`.  
Gate PASS = listen completed and classed. Existence only if exact `pred=664`.

This unit: COM12 open 1800.297 s then recapture 300.312 s, 0 B after recapture, no `CORE_DONE`, no `pred=`.  
`STILL_STALL` requires `W_STALL` / `PHASE=` / ATOM reprint **in this window** — none received.

n=1 + one same-unit 0-byte recapture. Descriptive. Existence remains **OPEN**.

---

## Existence / BOARD_PASS

| Item | Value |
|------|--------|
| EXISTENCE | **NO** — `pred=664` not in this hold (and not recorded in the 12:08–12:43 gap) |
| BOARD_PASS | **not_claimed** |
| `NATIVE_V1_MINI_AI_BOARD_PASS` | **not claimed** |
| `NATIVE_V1_EXISTENCE_BOARD_PASS` | **not claimed** |
| C_FIX | **NONE** |
| PROGRAM this gate | **NO** |
| NEXT | existence still OPEN. Do not treat SILENT as design FAIL. Do not treat 0-byte as a TinyGPT falsifier. Do not treat `WINDOW_SHORT` “not supported” as a falsifier of finish-in-gap 12:08–12:43. Do not reprogram without a new `com12_authorized_gate`. Do not dispatch `graph_late_materialize_00` from this side-lane. Auditor does not program. |

---

## NOT VERIFIED

- FPGA still holds SHA `9DC0F8DF…` at 12:43 — no JTAG readback this gate. Last exclusive program log is 12:03:23. Inference only.
- Whether COM12 RX was electrically live vs a quiet port after a successful `Serial.open` (script would have exited if open failed; that does not prove the FPGA TX path).
- Closeout’s parenthetical `COM3` / `COM4` listing — no `serial.tools.list_ports` dump in this bag. COM12 open succeeding is the evidenced fact.
- “No Vivado process after the listen” — no `vivado_pid*.str` in the results tree after REARM; live process table at 13:13 was not captured.
- Bytes (if any) on COM12 between REARM end 12:08:23 and this open 12:43:55 — **UNKNOWN** by construction; closeout does not sell that gap as observed silence.
- Whether silicon is still in `W_STALL`/`PHASE=01` or finished without UART during the gap — 0 B cannot distinguish.
- Task-vs-parent authorship of the listen run beyond DISPATCH_LOG `agent=a7-vivado-gate`.

**Stop:** do not declare existence or BOARD_PASS. Do not upgrade SILENT to design FAIL. Do not falsify TinyGPT / `pred=664` from 0-byte. Do not falsify finish-in-gap from `WINDOW_SHORT` not-supported. Do not program. Do not dispatch `graph_late_materialize_00` from this side-lane.
