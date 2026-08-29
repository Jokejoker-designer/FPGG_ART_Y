# AUDIT — E2R-UART-HOLD-PRED-00 (LISTEN-ONLY, CLASS=SILENT)

**Auditor:** `a7-evidence-auditor` (adversarial)  
**Date:** 2026-08-28  
**Gate:** `E2R-UART-HOLD-PRED-00` (existence side-lane; not `LOOP_STATE.next`)  
**Author claim:** LISTEN-ONLY **PASS_NARROW** / CLASS=`SILENT` (`a7-vivado-gate`)  
**MUST_READ_UNBLOCK_H5:** read. Next = ungated DIFF twin (not S2, not glue). This gate is not an encoder closeout; H5 / S2 / 01R-glue routes were not used.

```text
AUDIT: CLEAN
VERDICT: PASS_NARROW
CLASS=SILENT: supported (0 B / 0 lines, both ≥180 s windows)
PROGRAM: NO
EXISTENCE: NO
BOARD_PASS: not_claimed
C_FIX: NONE
PRED_IN_GAP (≈10:52–11:05+07): UNKNOWN (not falsified)
graph_late_materialize_00: DEFERRED
```

Gate PASS (listen completed and classed) is file-backed.  
0-byte after the preregistered recapture is **CLASS=SILENT**, not design FAIL.  
This is **not** `NATIVE_V1_EXISTENCE_BOARD_PASS`, **not** `NATIVE_V1_MINI_AI_BOARD_PASS`, **not** TinyGPT/`CORE_DONE`, and **not** a close of `graph_late_materialize_00`.

---

## Verdict line

`AUDIT: CLEAN` — no CRITICAL / MAJOR / MINOR that changes the listen-class claim.  
Forbidden PASS routes not taken. Control `W_STALL` / `PHASE=01` were not reused as this unit’s class. Gap bytes were not recorded; `pred=664` in that gap remains **UNKNOWN**, not falsified.

---

## Independent re-derivation (headline numbers)

### UART hold files (this unit)

| Artifact | Claimed | Independent |
|----------|---------|-------------|
| `uart_hold.txt` | 0 B | **MATCH** — length 0; SHA256 `E3B0C44298FC1C149AFBF4C8996FB92427AE41E4649B934CA495991B7852B855` (empty-file digest); mtime 2026-08-28 11:11:34 |
| `uart_hold_attempt1.txt` | 0 B | **MATCH** — length 0; mtime 11:08:14 |
| `uart_hold_attempt2.txt` | 0 B | **MATCH** — length 0; mtime 11:11:34 |
| Attempt 1 window | 11:05:14–11:08:14+07, 180.297 s | **MATCH** — `listen_stdout.log` `ELAPSED_S: 180.297`; archive mtime = claimed end |
| Attempt 2 window | 11:08:34–11:11:34+07, 180.219 s | **MATCH** — `ELAPSED_S: 180.219`; `uart_hold.txt` mtime = claimed end |
| `CORE_DONE` in hold | absent | **FACT** — 0 B files contain no lines |
| `pred=` / `pred=664` in hold | absent | **FACT** — 0 B files contain no lines |
| `BOOT` in hold | absent | **FACT** — 0 B; script `BOOT_SEEN: False` both attempts |
| CLASS | `SILENT` | **FACT** (class rule) — 0 useful lines after recapture; no `W_STALL`/`PHASE=`/`ATOM*` in this window |

Listen script `listen_uart_hold.py` opens COM12 with `dtr=False` `rts=False`, never writes TX, never calls Vivado, stops early only on `pred=664`. Transcript `listen_stdout.log` prints `program=NO` both windows.

### CONTROL (prior query; not this class)

| Item | Claimed | Independent |
|------|---------|-------------|
| `E2R-ATOMIC-SDONE-PROBE-00/uart_capture.txt` last lines | `ATOM1=` + `W_STALL` + `PHASE=01` | **MATCH** — tail is `ATOM0=0000059C` / `ATOM1=0000059D` / `W_STALL` / `PHASE=01` |
| Control payload bytes | 593 B | **MATCH** prior PROGRAM audit — on-disk 658 = 593 + 65 CR; mtime 2026-08-28 10:51:49 |
| `CORE_DONE` in control | absent (decode `core_done=0`) | **FACT** — no `CORE_DONE` line; ATOM0 `0000059C` bit9=0 (prior PROGRAM audit) |
| `pred=664` in control | absent | **FACT** — no `pred=` line |

Do **not** re-class this hold from the control tail. Closeout does not.

### PROGRAM = NO (this gate)

| Check | Result |
|-------|--------|
| HOLD dir `program_*.log` / `open_hw_manager` | **absent** |
| `listen_uart_hold.py` JTAG / `program_hw_devices` | **absent** |
| ATOMIC `program_excl.log` mtime | 2026-08-28 **10:51:48** (prior gate only) |
| Bit file mtime | 2026-08-28 **01:55:44** (BUILD; not rewritten at hold) |
| Bit SHA256 | `9DC0F8DFF7BF068A92ED3E5A1A5B66FF5C56BEB7D6B3FACA7911912D498F951B` — **MATCH** closeout; unchanged vs PROGRAM audit |
| Workspace terminals `program_hw_devices` / `open_hw_manager` | **absent** |
| `BRIDGE.json` `lock.owner` | `grok` (R6 MIG). Hold closeout did not take the lock. |
| `BRIDGE.json` `board.note` | ATOMIC-SDONE PROGRAM consumed ~10:51+07; “Do not reprogram until new `com12_authorized_gate`” |
| `com12_authorized_gate` | still `E2R-ATOMIC-SDONE-PROBE-00` (consumed). Hold was listen-only; not a new program authorize. |
| DISPATCH last UART-HOLD line | `program=false` `listen_only=true` |

`BRIDGE.board.program_authorized=true` is leftover from the consumed ATOMIC-SDONE authorize. It is **not** evidence a second program ran. No new program artifact exists after 10:51:48.

### Gap ≈10:52–11:05+07

| Bound | Artifact |
|-------|----------|
| Control capture write | `uart_capture.txt` mtime **10:51:49+07** |
| ATOMIC PROGRAM DISPATCH | `2026-08-28T10:52:00+07:00` CLASS=`SDONE_HIT` |
| Hold attempt 1 open | **11:05:14+07** (`listen_stdout.log`) |

≈13 min unrecorded. Closeout caveat matches the files. Bytes in that interval were **not** captured by this unit.

Therefore: `pred=664` (or `CORE_DONE`) **in the gap** is **UNKNOWN**, not falsified.  
`PRED_LATER` / `CORE_DONE_LATER` “not supported” applies to the two hold windows only.

### Copied BUILD timing (not a listen metric)

WNS 0.372 / TNS 0.000 / WHS 0.013 / THS 0.000 / DSP 19 are **copied** from `E2R-ATOMIC-SDONE-PROBE-00` post-route BUILD. Closeout labels them “not re-measured.” Not a silicon class input for this listen.

---

## Claim grades

| Claim | Grade | Note |
|-------|-------|------|
| PROGRAM=NO this gate | **FACT** | No new program log; bit mtime BUILD; listen script has no JTAG |
| Two COM12 windows ≥180 s | **FACT** | 180.297 s and 180.219 s in `listen_stdout.log`; archive mtimes match ends |
| UART_BYTES=0 both windows | **FACT** | Three 0 B files; empty SHA |
| CLASS=`SILENT` | **FACT** (class rule) | 0 lines after recapture; not `STILL_STALL` (no stall/PHASE in hold) |
| `CORE_DONE` absent this unit | **FACT** | 0 B |
| `pred=664` absent this unit | **FACT** | 0 B |
| 0-byte ≠ design FAIL | **FACT** (dispatch rule) | Recapture still 0 → SILENT; PASS_NARROW |
| Control last lines `ATOM1=` `W_STALL` `PHASE=01` | **FACT** | File tail |
| Control `W_STALL` is not this class | **FACT** | Closeout keeps it as prior query |
| H_CANDIDATE `SILENT` supported (this unit) | **FACT** | 0 B ×2 |
| H_CANDIDATE `STILL_STALL` not supported (this window) | **FACT** | No stall/PHASE lines received |
| H_RIVAL `CORE_DONE_LATER` / `PRED_LATER` not supported **in the hold windows** | **FACT** | 0 B |
| `pred`/`CORE_DONE` in ≈10:52–11:05 gap | **UNKNOWN** | Gap not recorded; not a falsifier |
| Silicon still stalled | **UNKNOWN** | 0 B does not falsify stall; closeout says so |
| Bit `9DC0F8DF…` still on FPGA at hold | **ENGINEERING_INFERENCE** | Last exclusive program 10:51:48; no readback this gate; no second program found |
| C_FIX=NONE | **FACT** | No RTL path in HOLD; script + archive only |
| BOARD_PASS / EXISTENCE not claimed | **FACT** | closeout, METRICS, DISPATCH `board_pass=false` `existence=false` |
| `graph_late_materialize_00` not closed | **FACT** | LOOP_STATE stays QUEUED / `deferred_by=EXISTENCE_BEFORE_QUALITY` |
| n=1 listen unit + 1 same-unit recapture | **FACT** | Descriptive; not a replication bag |

---

## Forbidden PASS routes (searched)

| Route | Result |
|-------|--------|
| Self-declared BOARD_PASS / `NATIVE_V1_*_BOARD_PASS` | **absent** |
| Existence claimed without `pred=664` | **absent** — EXISTENCE not claimed |
| 0-byte sold as design FAIL or as TinyGPT-done | **absent** — class SILENT; PASS_NARROW |
| Re-class from ATOMIC-SDONE `W_STALL`/`PHASE=01` | **absent** |
| ATOM reprint treated as stop / new class | **absent** — ATOM lines not in hold |
| Reprogram / `open_hw_manager` / C-FIX / A2 / LiteScope | **absent** |
| Golden/expected edited to match | **absent** — empty files are empty |
| Host winner/answer/`pred=` | **absent** |
| Gap silence sold as observed | **absent** — caveat present |
| `PRED_LATER` sold as falsified across the gap | **absent** — “this unit only” |
| H5 / S2 clamp / 01R-02M-LM06 glue | **absent** |
| Frozen LM-06 / 01R / 02M / SGO / F1x overwrite | **absent** — bit mtime still BUILD 01:55:44 |
| `graph_late_materialize_00` promoted | **absent** — stays DEFERRED |
| Grok `BRIDGE.lock` stolen | **absent** — `lock.owner=grok` |

---

## Dispatch vs LOOP_STATE (process)

| Item | Value |
|------|--------|
| `LOOP_STATE.next` / first remaining graph id | `graph_late_materialize_00` QUEUED, `deferred_by=EXISTENCE_BEFORE_QUALITY` |
| DISPATCH_LOG last `gate` | `E2R-UART-HOLD-PRED-00` (line 232; last UART-HOLD **PASS_NARROW** line) |
| last `agent` | `a7-vivado-gate` (matches dispatch `E2R_UART_HOLD_PRED_DISPATCH.md` and pipeline `character_id` for board/Vivado) |
| last `result` | `PASS_NARROW` `class=SILENT` `uart_bytes=0` `core_done=false` `pred=null` `listen_only=true` `program=false` `c_fix=NONE` `existence=false` `board_pass=false` |
| last `note` | existence side-lane; not `graph_late_materialize_00`; 0-byte recapture still 0; no BOARD_PASS |

Last DISPATCH may be this side-lane gate. That does **not** FAIL this audit. `graph_late_materialize_00` stays **DEFERRED**. Do **not** promote this PASS_NARROW to a graph-loop close.

---

## CLASS=SILENT — supported?

**Yes.** Dispatch classes: `SILENT` / `STILL_STALL` / `CORE_DONE_LATER` / `PRED_LATER`.  
Gate PASS = listen completed and classed. Existence only if exact `pred=664`.

This unit: two ≥180 s COM12 opens, 0 B after recapture, no `CORE_DONE`, no `pred=`.  
`STILL_STALL` requires `W_STALL` / `PHASE=` / ATOM reprint **in this window** — none received.  
Control tail remains the prior query’s last printed state.

n=1 + one same-unit 0-byte recapture. Descriptive. Existence remains **OPEN**.

---

## Existence / BOARD_PASS

| Item | Value |
|------|--------|
| EXISTENCE | **NO** — `pred=664` not in this hold (and not recorded in the gap) |
| BOARD_PASS | **not_claimed** |
| `NATIVE_V1_MINI_AI_BOARD_PASS` | **not claimed** |
| `NATIVE_V1_EXISTENCE_BOARD_PASS` | **not claimed** |
| C_FIX | **NONE** |
| PROGRAM this gate | **NO** |
| NEXT | existence still OPEN. Do not treat SILENT as design FAIL. Do not treat the gap as a negative `pred=664` result. Do not reprogram without a new `com12_authorized_gate`. Do not dispatch `graph_late_materialize_00` from this side-lane. |

---

## NOT VERIFIED

- FPGA still holds SHA `9DC0F8DF…` at 11:05 — no JTAG readback this gate. Last exclusive program log is 10:51:48. Inference only.
- Whether COM12 RX was electrically live vs a quiet port after a successful `Serial.open` (script would have exited if open failed; that does not prove the FPGA TX path).
- Bytes (if any) on COM12 between 10:51:49 and 11:05:14 — **UNKNOWN** by construction.
- Whether silicon is still in `W_STALL`/`PHASE=01` or has moved without UART — 0 B cannot distinguish.
- Task-vs-parent authorship of `listen_uart_hold.py` beyond DISPATCH_LOG `agent=a7-vivado-gate`.

**Stop:** do not declare existence or BOARD_PASS. Do not upgrade SILENT to design FAIL. Do not falsify `pred=664` from the unrecorded gap. Do not dispatch `graph_late_materialize_00` from this side-lane.
