# AUDIT — E2R-UART-HOLD-REARM-00 (PROGRAM, CLASS=STILL_STALL)

**Auditor:** `a7-evidence-auditor` (adversarial, VERIFY_ONLY)  
**Date:** 2026-08-28T12:16+07  
**Gate:** `E2R-UART-HOLD-REARM-00` (existence side-lane; not `LOOP_STATE.next`)  
**Author claim:** PROGRAM **PASS_NARROW** / CLASS=`STILL_STALL` (`a7-vivado-gate`)  
**MUST_READ_UNBLOCK_H5:** read. Next = ungated DIFF twin (not S2, not glue). This gate is not an encoder closeout; H5 / S2 / 01R-glue routes were not used.

```text
AUDIT: CLEAN
VERDICT: PASS_NARROW
CLASS=STILL_STALL: supported (ATOM present ∧ W_STALL/PHASE ∧ hold_after_atom ≥300 s ∧ no CORE_DONE ∧ no pred=664)
PROGRAM: YES
EXISTENCE: NO
BOARD_PASS: not_claimed
C_FIX: NONE
graph_late_materialize_00: DEFERRED
n=1: descriptive this boot only; not TinyGPT hung as silicon law
```

Gate PASS = boot captured and classed.  
This is **not** `NATIVE_V1_EXISTENCE_BOARD_PASS`, **not** `NATIVE_V1_MINI_AI_BOARD_PASS`, **not** a C-FIX, and **not** a close of `graph_late_materialize_00`.  
Observer/truncation at ATOM is **closed** for this one boot (`H_RIVAL` `PRED_LATER` not supported). That is not a TinyGPT hang law.

---

## Verdict line

`AUDIT: CLEAN` — no CRITICAL / MAJOR / MINOR that changes the STILL_STALL PROGRAM claim.  
Forbidden PASS routes not taken. Sequential `SDONE=0` is CONTROL, not the class. 593 B matching the first truncated print burst is **one unknown closed** (hold past ATOM), not a second unknown.

---

## Independent re-derivation (headline numbers)

### UART file (this unit)

| Check | Claimed | Independent |
|-------|---------|-------------|
| Path | `E2R-UART-HOLD-REARM-00/uart_rearm.txt` | **FACT** — exists; 593 B; LF-only; 65 lines; mtime **2026-08-28T12:08:23+07** |
| Last lines | `ATOM0=0000059C` / `ATOM1=0000059D` / `W_STALL` / `PHASE=01` then EOF | **MATCH** — file ends there; no trailing UART |
| `CORE_DONE` | absent | **FACT** — 0 lines |
| `pred=` / `PRED=` | absent | **FACT** — 0 lines; no `pred=664` |
| Sequential `SDONE=` / `SGO=` / `WDMA_GRANT=` | CONTROL | **FACT** — `SDONE=0` `SGO=0` `WDMA_GRANT=0` present; not used as class |

### First truncated capture (593 B consistency — not a second unknown)

| Item | First `E2R-ATOMIC-SDONE-PROBE-00/uart_capture.txt` | This `uart_rearm.txt` |
|------|---------------------------------------------------|------------------------|
| Serial/text payload | 593 B (`UART_BYTES: 593`; on-disk 658 = 593 + 65 CR) | **593 B** LF-only |
| Normalized text | identical 593 chars / 65 lines | **identical** |
| Ends | `ATOM0=0000059C` `ATOM1=0000059D` `W_STALL` `PHASE=01` | **same** |

The first capture already included the `W_STALL`/`PHASE=` banner in the print burst and then **stopped at ATOM**. This file matching that burst after a hold is **expected**. It does not open a second unknown.

### Hold past ATOM (class requirement)

| Check | Claimed | Independent |
|-------|---------|-------------|
| Arm before program | COM12 first | **FACT** — terminal `742431` `started_at=2026-08-28T05:02:31.162Z` = **12:02:31+07**; Vivado session start **12:02:59+07**; exit **12:03:23+07** |
| Script | `--max-seconds 600 --hold-after-atom 300` | **FACT** — terminal command line; DTR/RTS false |
| `ATOM1_SEEN` | 52.265 s; holding 300 s more (not a stop) | **MATCH** — terminal line 77 |
| `STOP_REASON` | `hold_after_atom` | **MATCH** — not `max_seconds`; not ATOM-stop |
| `ELAPSED_S` | 352.406 | **MATCH** — 52.265 + ~300.14; terminal `elapsed_ms=353009`; `ended_at=05:08:24Z` = **12:08:24+07** |
| `UART_BYTES` | 593 | **MATCH** — stdout + on-disk file |
| `CLASS` (script) | `STILL_STALL` | **MATCH** |
| `SEQUENTIAL_NOT_CLASS` | `SDONE=SDONE=0 GRANT=WDMA_GRANT=0 SGO=SGO=0` | **FACT** |
| ATOM-stop | not used | **FACT** — `ATOM1_SEEN … (not a stop)` then 300 s more; CONTROL `capture_uart_atom.py` stop was **not** this vehicle |

Capture stdout was not copied into the REARM bag (prior listen gates archived `listen_stdout.log`). Numbers above are recovered from Cursor terminal `742431` and file mtimes. They match CLOSEOUT.

### ATOM decode (independent; not the closeout table)

`0x0000059C` bits `{2,3,4,7,8,10}`  
→ dest=4, owner=1, grant=1, idle=0, sdone_latch=0, **sdone_sticky=1**, **w_stall=1**, **core_done=0**, mgo=1, reserved=0, hi=0.

`0x0000059D` = ATOM0 + 1 → dest=5, other fields unchanged. `hi_ok=True` both.

Matches `uart_rearm.txt`, terminal `ATOM0_DECODE` / `ATOM1_DECODE`, and CONTROL ATOM0 from the prior SDONE PROGRAM.

### Bit SHA / JTAG / authorize / PROGRAM

| Artifact | Claimed | Independent |
|----------|---------|-------------|
| `arty_a7_ng_native_v1_atomic_sdone_probe_00.bit` | `9DC0F8DFF7BF068A92ED3E5A1A5B66FF5C56BEB7D6B3FACA7911912D498F951B` | **MATCH** — Python hashlib 2026-08-28T12:16+07; size 3826011; mtime **2026-08-28 01:55:44** (BUILD; not rewritten at this program) |
| JTAG | `210319BE776EA` | **MATCH** — `program_excl.log` `HW_TARGETS=localhost:3121/xilinx_tcf/Digilent/210319BE776EA` (one target) |
| `program_hw_devices` | this bit | **FACT** — `End of startup status: HIGH`; tcl sets `PROGRAM.FILE` to the SDONE path; refuses SGO/F1x/B-FIX/R6/frozen/`*lm06*` |
| Marker | `E2R_UART_HOLD_REARM_00_EXCL_PROGRAM_PASS` | **FACT** — log names this bit path only |
| Leftover tcl `puts` `PROGRAM not executed this gate` | print text only | **FACT** — leftover PREP string after `program_hw_devices`; **not** evidence program was skipped |
| Capture banner `program=NO` / `PROGRAM: NO` | leftover PREP | **FACT** — hardcoded in `capture_uart_rearm.py`; CLOSEOUT does not treat it as PROGRAM=NO |
| `BRIDGE.json` `com12_authorized_gate` | `E2R-UART-HOLD-REARM-00` | **MATCH** — board BRIDGE `authorized_at=2026-08-28T11:58:00+07`; BRIDGE mtime **12:00:23+07**; program **12:02:59+07**. Leftover `E2R-ATOMIC-SDONE-PROBE-00` authorize **not** the live id |
| Soft debug / LiteScope | none | **FACT** — `Labtools 27-1434` no supported soft debug core |

Tcl does not itself parse BRIDGE. Operator re-read is claimed; live BRIDGE id + timestamp order are consistent with that claim. No BRIDGE snapshot file was written at `open_hw_manager`.

### Copied BUILD timing (not this unit)

WNS 0.372 ns / TNS 0.000 ns / DSP 19 remain BUILD provenance of `E2R-ATOMIC-SDONE-PROBE-00`. Closeout labels them “not re-run.” Not a silicon class input.

---

## CLASS=STILL_STALL — supported?

Dispatch rule (this gate): ATOM present **and** `W_STALL`/`PHASE` **and** hold past ATOM **and** no `CORE_DONE` / `pred=664`.

| Predicate | This query |
|-----------|------------|
| ATOM present | **yes** — ATOM0=`0000059C` ATOM1=`0000059D` |
| `W_STALL` / `PHASE=` | **yes** — `W_STALL` `PHASE=01` |
| Hold past ATOM | **yes** — `hold_after_atom` 300 s after ATOM1; total 352.406 s |
| No `CORE_DONE` | **yes** |
| No `pred=664` | **yes** |
| Sequential `SDONE=0` as class | **no** — CONTROL; `SEQUENTIAL_NOT_CLASS` |

**Supported** for this boot.

Not sold as:

- `PRED_LATER` / `CORE_DONE_LATER` / `NO_ATOM` / `SILENT`
- sequential `SDONE=0` class
- existence
- TinyGPT hung as silicon law (n=1; “Descriptive only”; “does not prove existence”)

`H_CANDIDATE` (`STILL_STALL` after ATOM+≥300 s) is **supported** on this unit.  
`H_RIVAL` (`PRED_LATER`) is **not supported**. Observer/truncation at ATOM is **closed** for this boot: capture continued and UART printed nothing after `PHASE=01`.

n=1. Do not promote this to a TinyGPT / core-hang law.

---

## Claim grades

| Claim | Grade | Note |
|-------|-------|------|
| PROGRAM=YES this gate | **FACT** | `program_hw_devices`; End of startup HIGH; exclusive JTAG; leftover PREP `puts` is print text |
| `com12_authorized_gate=E2R-UART-HOLD-REARM-00` used | **FACT** (live BRIDGE + time order) | 11:58 authorize; 12:00 BRIDGE write; 12:02:59 program. No leftover SDONE id |
| Same bit SHA `9DC0F8DF…` | **FACT** | Independent re-hash MATCH; mtime still BUILD 01:55:44 |
| CLASS=`STILL_STALL` | **FACT** (class rule) | ATOM + stall banner + hold + no CORE_DONE/pred |
| Sequential `SDONE=0` is not the class | **FACT** | present and excluded |
| 593 B = first truncated burst | **FACT** | text-identical; CRLF vs LF only on the first file |
| Observer/truncation closed this boot | **FACT** | hold 300 s; 0 extra UART bytes |
| TinyGPT / core proven hung as law | **not claimed** | n=1 descriptive; existence OPEN |
| C_FIX=NONE | **FACT** | No RTL this gate; bit mtime BUILD |
| BOARD_PASS / EXISTENCE not claimed | **FACT** | bag + STATUS pointer + DISPATCH `existence`/`board_pass` false |
| `graph_late_materialize_00` not closed | **FACT** | LOOP_STATE stays QUEUED / `deferred_by=EXISTENCE_BEFORE_QUALITY` |
| FPGA still holds `9DC0F8DF…` now | **ENGINEERING_INFERENCE** | Last exclusive program 12:03:23; no readback this audit |

---

## Forbidden PASS routes (searched)

| Route | Result |
|-------|--------|
| Self-declared BOARD_PASS / `NATIVE_V1_*_BOARD_PASS` | **absent** |
| Existence claimed without `pred=664` | **absent** — EXISTENCE not claimed; `pred=664` absent |
| Sequential `SDONE=0` sold as STILL_STALL | **absent** |
| TinyGPT hung as silicon law beyond n=1 | **absent** |
| ATOM-stop script used as this capture | **absent** |
| Wrong bit / leftover SDONE authorize | **not supported** — authorize id this gate; SHA `9DC0F8DF…`; SGO/F1x refused by tcl |
| Golden/expected edited to match | **absent** — UART is a print; class is presence/absence |
| C-FIX / A2 / LiteScope / UART strip | **absent** |
| Host winner/answer/`pred=` | **absent** |
| 593 B match treated as a second unknown | **absent** — same print burst; hold is the unknown |
| H5 / S2 clamp / 01R-02M-LM06 glue | **absent** |
| Frozen LM-06 / 01R / 02M overwrite | **absent** — this bit mtime still BUILD 01:55:44 |
| `graph_late_materialize_00` promoted | **absent** — stays DEFERRED |
| Grok `BRIDGE.lock` stolen | **absent** — `lock.owner=grok` |

---

## Dispatch vs LOOP_STATE (process)

| Item | Value |
|------|--------|
| `LOOP_STATE.next` / first remaining graph id | `graph_late_materialize_00` QUEUED, `deferred_by=EXISTENCE_BEFORE_QUALITY` |
| DISPATCH_LOG last implementer `gate` | `E2R-UART-HOLD-REARM-00` |
| last implementer `agent` | `a7-vivado-gate` (matches `E2R_UART_HOLD_REARM_DISPATCH.md`; existence side-lane exception) |
| last implementer `result` | `PASS_NARROW` `class=STILL_STALL` `program=true` SHA `9DC0F8DF…` |
| last implementer `note` | existence side-lane; not `graph_late_materialize_00`; one reprogram + continuous capture; no ATOM stop |

Last DISPATCH implementer may be this side-lane gate. That does **not** FAIL this audit. `graph_late_materialize_00` stays **DEFERRED**. Do **not** promote this PASS_NARROW to a graph-loop close.

---

## Existence / BOARD_PASS

| Item | Value |
|------|--------|
| EXISTENCE | **NO** — `pred=664` absent |
| BOARD_PASS | **not_claimed** |
| `NATIVE_V1_MINI_AI_BOARD_PASS` | **not claimed** |
| `NATIVE_V1_EXISTENCE_BOARD_PASS` | **not claimed** |
| C_FIX | **NONE** |
| PROGRAM this gate | **YES** |
| Observer/truncation | **closed this boot** — not a design FAIL; not existence |
| NEXT | existence still OPEN. Core hang after SDONE-open remains the open unknown on this n=1 boot. Do not invent a C-FIX from this class. Do not reprogram without a new `com12_authorized_gate`. Do not dispatch `graph_late_materialize_00` from this side-lane. Auditor does not program. |

---

## NOT VERIFIED

- FPGA readback of SHA `9DC0F8DF…` after 12:03:23 — inference from exclusive program log only.
- BRIDGE snapshot at the exact `open_hw_manager` instant — live file after 11:58 is this gate id; tcl does not parse BRIDGE.
- Capture stdout not archived in the REARM bag; independently recovered from terminal `742431` (numbers match CLOSEOUT).
- Task-vs-parent authorship of CLOSEOUT beyond DISPATCH_LOG `agent=a7-vivado-gate`.
- Replication beyond n=1.

**Stop:** do not program. Do not declare existence or BOARD_PASS. Do not treat STILL_STALL as TinyGPT-hung law. Do not dispatch `graph_late_materialize_00` from this side-lane.
