# AUDIT — E2R-UART-HOLD-REARM-PREP-00 (PREP_ONLY, CLASS=PREP_READY)

**Auditor:** `a7-evidence-auditor` (adversarial, VERIFY_ONLY)  
**Date:** 2026-08-28T11:32+07  
**Gate:** `E2R-UART-HOLD-REARM-PREP-00` (existence side-lane; not `LOOP_STATE.next`)  
**Author claim:** PREP **PREP_READY** / PROGRAM=NO (`a7-vivado-gate`)  
**MUST_READ_UNBLOCK_H5:** read. Next = ungated DIFF twin (not S2, not glue). This gate is not an encoder closeout; H5 / S2 / 01R-glue routes were not used.

```text
AUDIT: CLEAN
VERDICT: PASS_NARROW
CLASS=PREP_READY: supported (vehicle + SHA + exclusive tcl on disk; PROGRAM=NO)
PROGRAM: NO
EXISTENCE: NO
BOARD_PASS: not_claimed
C_FIX: NONE
graph_late_materialize_00: DEFERRED
```

This is **PREP only**. Gate PASS = hold-past-ATOM capture script on disk + exclusive program tcl archived + bit SHA match + PROGRAM=NO.  
Not a program. Not a COM12 listen. Not `NATIVE_V1_EXISTENCE_BOARD_PASS`. Not `NATIVE_V1_MINI_AI_BOARD_PASS`. Not a close of `graph_late_materialize_00`.

---

## Verdict line

`AUDIT: CLEAN` — no CRITICAL / MAJOR / MINOR that changes the PREP_READY claim.  
Forbidden PASS routes not taken. No `open_hw_manager` / `program_hw_devices` / COM12 listen ran this gate. New capture does not stop on ATOM0+ATOM1. PREP_READY is a file-backed class, not a silicon class.

---

## Independent re-derivation (headline numbers)

### Bit SHA (re-hashed this audit)

| Artifact | Claimed | Independent |
|----------|---------|-------------|
| `E2R-ATOMIC-SDONE-PROBE-00/arty_a7_ng_native_v1_atomic_sdone_probe_00.bit` | `9DC0F8DFF7BF068A92ED3E5A1A5B66FF5C56BEB7D6B3FACA7911912D498F951B` | **MATCH** — PowerShell `Get-FileHash -Algorithm SHA256` 2026-08-28T11:31+07; size 3826011; mtime **2026-08-28 01:55:44** (BUILD; not rewritten this PREP) |

### Capture vehicle

| Check | Claimed | Independent |
|-------|---------|-------------|
| Path | `E2R-UART-HOLD-REARM-00/capture_uart_rearm.py` | **FACT** — exists; 8482 B; mtime 2026-08-28 11:26:07; SHA256 `DAD6316AFD00B7F4D62A2010AF0A9F9841885772F0CC33285A320AC5D77EFD3E` |
| `STOP: ATOM0+ATOM1` | absent | **FACT** — 0 matches |
| `ATOM0+ATOM1` | absent as stop | **FACT** — 0 matches in new script |
| `has0` / `has1` / `if has0 and has1` | absent | **FACT** — 0 matches |
| `--hold-after-atom` default | 300; refuse `<300` | **FACT** — `default=300.0`; `if args.hold_after_atom < 300.0: return 2` |
| `--max-seconds` default | 600; refuse `<600` | **FACT** — `default=600.0`; `if args.max_seconds < 600.0: return 2` |
| Early stop | `pred=664` / `PRED=664` only | **FACT** — first `break` is `_has_pred_664`; remaining breaks are `max_seconds` and `hold_after_atom` (after ATOM1 + floor) |
| ATOM1 note | not a stop | **FACT** — prints `holding Ns more (not a stop)`; does not `break` |
| Open style | COM12 115200; `dtr=False` `rts=False` | **FACT** — same pattern as CONTROL `listen_uart_hold.py` |
| Classes | `PRED_LATER` / `CORE_DONE_LATER` / `STILL_STALL` / `SILENT` / `NO_ATOM` | **FACT** — all five are return strings in `classify()` |
| Executed this gate | NO | **FACT** — no `uart_rearm*.txt`; bag has only py + tcl + CLOSEOUT |

CONTROL `E2R-ATOMIC-SDONE-PROBE-00/capture_uart_atom.py` still contains `has0`/`has1` and `STOP: ATOM0+ATOM1 captured` then `break` (lines 77–81). That stop was **not** copied.

### Exclusive program tcl (archived; not run)

| Check | Claimed | Independent |
|-------|---------|-------------|
| Vivado copy | `vivado/tcl/program_e2r_uart_hold_rearm_00_excl.tcl` | **FACT** — exists; 3116 B; mtime 2026-08-28 11:26:15 |
| Bag copy | `E2R-UART-HOLD-REARM-00/program_e2r_uart_hold_rearm_00_excl.tcl` | **FACT** — byte-identical to vivado copy |
| Tcl SHA256 | `F04BE5C63DCE59EC97C469E9D0CA6F19081DF8FC3EE6E7423B8161BAA27A276C` | **MATCH** — both copies |
| Bit name | only `arty_a7_ng_native_v1_atomic_sdone_probe_00.bit` under `E2R-ATOMIC-SDONE-PROBE-00` | **FACT** — `bit_name` + path-match refuse |
| JTAG | `210319BE776EA`; refuse 2nd target / PYNQ / `1234-TUL` / `xc7z020` | **FACT** |
| Refuse SGO / F1x / B-FIX / R6 / frozen / lm06 | present | **FACT** — refuse list only; not a program path |
| `[\s\S]` | absent both copies | **FACT** — 0 matches |
| Executed this gate | NO | **FACT** — see PROGRAM table |

Source CONTROL `program_e2r_atomic_sdone_probe_00_excl.tcl` SHA256 `6BBF482B…` (different file; retitled/extended). Same SDONE bit + same JTAG.

### PROGRAM = NO (this gate)

| Check | Result |
|-------|--------|
| REARM bag `program_*.log` / `*.jou` / `uart_rearm*` | **absent** |
| Journals / logs under board tree with mtime after 11:21+07 | **absent** |
| ATOMIC `program_excl.log` mtime | 2026-08-28 **10:51:48** (prior PROGRAM gate only) |
| Bit file mtime | 2026-08-28 **01:55:44** (BUILD; not rewritten) |
| Board `rtl/**` mtime after 11:21+07 | **absent** |
| Workspace terminals `program_hw_devices` / `open_hw_manager` / `capture_uart_rearm` this window | **absent** — `728513` is prior ATOM capture (started 10:51+07); `995588` is prior BUILD |
| `BRIDGE.json` `lock.owner` | `grok` (R6 MIG). PREP did not take the lock. |
| `BRIDGE.json` `board.com12_authorized_gate` | still `E2R-ATOMIC-SDONE-PROBE-00` (consumed 10:46/10:51+07) |
| `BRIDGE.json` `board.note` | REARM PREP in flight (PROGRAM=NO); do not program until authorize is `E2R-UART-HOLD-REARM-00` |
| DISPATCH last implementer line | `gate=E2R-UART-HOLD-REARM-PREP-00` `agent=a7-vivado-gate` `result=PREP_READY` `program=false` |

`BRIDGE.board.program_authorized=true` is leftover from the consumed ATOMIC-SDONE authorize. It is **not** evidence a second program ran. No new program artifact exists after 10:51:48.

### Copied BUILD timing (not a PREP metric)

WNS 0.372 ns / TNS 0.000 ns remain BUILD provenance of `E2R-ATOMIC-SDONE-PROBE-00`. Closeout labels them “not re-measured.” Not a silicon class input for this PREP.

---

## Claim grades

| Claim | Grade | Note |
|-------|-------|------|
| PROGRAM=NO this gate | **FACT** | No new journal; bit mtime BUILD; no COM12 capture file; terminals are prior gates |
| New script does not stop on ATOM0+ATOM1 | **FACT** | grep 0; CONTROL still has the stop |
| `hold_after_atom` default ≥300 and refuse lower | **FACT** | 300.0 / `<300` → exit 2 |
| `max-seconds` default ≥600 and refuse lower | **FACT** | 600.0 / `<600` → exit 2 |
| Bit SHA `9DC0F8DF…` | **FACT** | Independent re-hash MATCH |
| Tcl programs only SDONE probe bit + JTAG `210319BE776EA` | **FACT** | path-match + refuse list; `[\s\S]` absent |
| Both tcl copies identical | **FACT** | SHA `F04BE5C6…` |
| CLASS=`PREP_READY` | **FACT** (class rule) | Vehicle + SHA + tcl + PROGRAM=NO; not a UART class |
| C_FIX=NONE | **FACT** | No RTL path this gate |
| BOARD_PASS / EXISTENCE not claimed | **FACT** | bag + pointer closeouts; DISPATCH `existence`/`board_pass` false on this PREP |
| `graph_late_materialize_00` not closed | **FACT** | LOOP_STATE stays QUEUED / `deferred_by=EXISTENCE_BEFORE_QUALITY` |
| Silicon still stalled / pred in gap | **UNKNOWN** | not this unit; PREP did not listen |
| Bit `9DC0F8DF…` still on FPGA now | **ENGINEERING_INFERENCE** | Last exclusive program 10:51:48; no readback this gate |

PREP_READY is **not** an overclaim. It is the dispatch class for “files on disk, no program.”

---

## Forbidden PASS routes (searched)

| Route | Result |
|-------|--------|
| Self-declared BOARD_PASS / `NATIVE_V1_*_BOARD_PASS` | **absent** |
| Existence claimed without `pred=664` | **absent** — EXISTENCE not claimed; `pred=664` not measured |
| Program / `open_hw_manager` / `hw_program` / COM12 listen this gate | **absent** |
| ATOM stop left in new capture | **absent** |
| Golden/expected edited to match | **absent** — no UART this unit |
| C-FIX / A2 / LiteScope / UART strip | **absent** |
| Host winner/answer/`pred=` | **absent** |
| H5 / S2 clamp / 01R-02M-LM06 glue | **absent** |
| Frozen LM-06 / 01R / 02M overwrite | **absent** — bit mtime still BUILD 01:55:44 |
| Wrong-bit tcl (SGO / F1x / B-FIX / R6 / lm06) | **absent** — refuse list; bit path SDONE only |
| `[\s\S]` in tcl | **absent** |
| `graph_late_materialize_00` promoted | **absent** — stays DEFERRED |
| Grok `BRIDGE.lock` stolen | **absent** — `lock.owner=grok` |

---

## Dispatch vs LOOP_STATE (process)

| Item | Value |
|------|--------|
| `LOOP_STATE.next` / first remaining graph id | `graph_late_materialize_00` QUEUED, `deferred_by=EXISTENCE_BEFORE_QUALITY` |
| DISPATCH_LOG last implementer `gate` | `E2R-UART-HOLD-REARM-PREP-00` |
| last implementer `agent` | `a7-vivado-gate` (matches `E2R_UART_HOLD_REARM_PREP_DISPATCH.md`; existence side-lane exception) |
| last implementer `result` | `PREP_READY` `program=false` SHA `9DC0F8DF…` |
| last `note` | existence side-lane; not `graph_late_materialize_00`; PROGRAM=NO |

Last DISPATCH may be this side-lane gate. That does **not** FAIL this audit. Prior UART-HOLD / SDONE audits used `PASS_NARROW` on the same exception. `graph_late_materialize_00` stays **DEFERRED**. Do **not** promote this PASS_NARROW to a graph-loop close.

---

## CLASS=PREP_READY — supported?

**Yes.** Dispatch: gate PASS = vehicle on disk + SHA match + PROGRAM=NO. Existence is not this gate.

This unit: capture script without ATOM-stop; floors 300/600 with refuse-lower; exclusive tcl points only at SDONE bit `9DC0F8DF…`; JTAG `210319BE776EA`; no `[\s\S]`; no program; no COM12 open.

n=1 PREP bag. Descriptive. Existence remains **OPEN**.

---

## Existence / BOARD_PASS

| Item | Value |
|------|--------|
| EXISTENCE | **NO** — `pred=664` not measured this gate |
| BOARD_PASS | **not_claimed** |
| `NATIVE_V1_MINI_AI_BOARD_PASS` | **not claimed** |
| `NATIVE_V1_EXISTENCE_BOARD_PASS` | **not claimed** |
| C_FIX | **NONE** |
| PROGRAM this gate | **NO** |
| NEXT | wait. Program only as `E2R-UART-HOLD-REARM-00` after `com12_authorized_gate` is exactly that id. Do not run the archived tcl on leftover SDONE authorize. Do not dispatch `graph_late_materialize_00` from this side-lane. |

---

## NOT VERIFIED

- FPGA still holds SHA `9DC0F8DF…` at 11:32 — no JTAG readback this gate. Last exclusive program log is 10:51:48. Inference only.
- Task-vs-parent authorship of `capture_uart_rearm.py` / the two tcl copies beyond DISPATCH_LOG `agent=a7-vivado-gate`.
- Live classification (`PRED_LATER` / `STILL_STALL` / …) — script was not executed; class strings exist, behavior on a real UART stream is the next gate.
- Archived tcl success `puts` still says `PROGRAM not executed this gate` after `program_hw_devices`. Harmless for this PREP (tcl was not run). Later REARM journal must not treat that banner as proof program was skipped.

**Stop:** do not program. Do not declare existence or BOARD_PASS. Do not dispatch `graph_late_materialize_00` from this side-lane.
