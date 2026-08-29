# AUDIT — E2R-UART-HOLD-LONGBOOT-PREP-00 (PREP_ONLY, CLASS=PREP_READY)

**Auditor:** `a7-evidence-auditor` (adversarial, VERIFY_ONLY)  
**Date:** 2026-08-29T13:50+07  
**Gate:** `E2R-UART-HOLD-LONGBOOT-PREP-00` (existence side-lane; not `LOOP_STATE.next`)  
**Author claim:** PREP **PREP_READY** / PROGRAM=NO (`a7-vivado-gate`, Task `1963bfc7-f04e-4575-9923-702ba0499918`)  
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

Parent must **wait** for human `com12_authorized_gate=E2R-UART-HOLD-LONGBOOT-00`. Do not program from leftover `E2R-UART-HOLD-REARM-00`.

---

## Verdict line

`AUDIT: CLEAN` — no CRITICAL / MAJOR / MINOR that changes the PREP_READY claim.  
Forbidden PASS routes not taken. No `open_hw_manager` / `program_hw_devices` / COM12 listen ran this gate. New capture defaults are 2400/2700 and does not stop on ATOM0+ATOM1. PREP_READY is a file-backed class, not a silicon class.

---

## Independent re-derivation (headline numbers)

### Bit SHA (re-hashed this audit)

| Artifact | Claimed | Independent |
|----------|---------|-------------|
| `E2R-ATOMIC-SDONE-PROBE-00/arty_a7_ng_native_v1_atomic_sdone_probe_00.bit` (board worktree) | `9DC0F8DFF7BF068A92ED3E5A1A5B66FF5C56BEB7D6B3FACA7911912D498F951B` | **MATCH** — PowerShell `Get-FileHash -Algorithm SHA256` 2026-08-29T13:48+07; size 3826011; mtime **2026-08-28 01:55:44** (BUILD; not rewritten this PREP) |

### Capture vehicle

| Check | Claimed | Independent |
|-------|---------|-------------|
| Path | `E2R-UART-HOLD-LONGBOOT-00/capture_uart_longboot.py` (board) | **FACT** — exists; 8571 B; mtime 2026-08-28 15:21:52; SHA256 `3ABE6425BFA65B1ADA4E748977B71B42690A16A86DC9E68D82D28901C3B669F7` |
| `STOP: ATOM0+ATOM1` | absent | **FACT** — 0 matches |
| `has0` / `has1` / `if has0 and has1` | absent | **FACT** — 0 matches |
| `--hold-after-atom` default | 2400; refuse `<2400` | **FACT** — `default=2400.0`; `if args.hold_after_atom < 2400.0: return 2` |
| `--max-seconds` default | 2700; refuse `<2700` | **FACT** — `default=2700.0`; `if args.max_seconds < 2700.0: return 2` |
| Leftover 300/600 as knobs | absent | **FACT** — `default=300` / `default=600` count=0 in new script; those floors remain only on CONTROL `capture_uart_rearm.py` |
| Early stop | `pred=664` / `PRED=664` only | **FACT** — first `break` is `_has_pred_664`; remaining breaks are `max_seconds` and `hold_after_atom` (after ATOM1 + floor) |
| ATOM1 note | not a stop | **FACT** — prints `holding Ns more (not a stop)`; does not `break` |
| Open style | COM12 115200; `dtr=False` `rts=False` | **FACT** — copy of REARM `open_com_no_reset` |
| Classes | `PRED_LATER` / `CORE_DONE_LATER` / `STILL_STALL` / `SILENT` / `NO_ATOM` | **FACT** — all five are return strings in `classify()` |
| Executed this gate | NO | **FACT** — no `uart_longboot.txt`; bag is py + tcl + CLOSEOUT only |

CONTROL `capture_uart_rearm.py` still defaults 300/600. Diff vs LONGBOOT is retitle + floors 2400/2700 + refuse-lower + `CONTROL vehicle is capture_uart_rearm.py` comment. ATOM-stop was already absent in REARM and was not reintroduced.

### Exclusive program tcl (archived; not run)

| Check | Claimed | Independent |
|-------|---------|-------------|
| Vivado copy | `vivado/tcl/program_e2r_uart_hold_longboot_00_excl.tcl` (board) | **FACT** — exists; 3188 B; mtime 2026-08-28 15:22:03 |
| Bag copy | `E2R-UART-HOLD-LONGBOOT-00/program_e2r_uart_hold_longboot_00_excl.tcl` | **FACT** — byte-identical to vivado copy; mtime 2026-08-29 13:43:45 |
| Tcl SHA256 | `A825187D7D4AE42D068DF6198F8EDE2A227AF601CF447465194A2B569B029E5F` | **MATCH** — both copies |
| Bit name | only `arty_a7_ng_native_v1_atomic_sdone_probe_00.bit` under `E2R-ATOMIC-SDONE-PROBE-00` | **FACT** — `bit_name` + path-match refuse |
| JTAG | `210319BE776EA`; refuse 2nd target / PYNQ / `1234-TUL` / `xc7z020` | **FACT** |
| Refuse SGO / F1x / B-FIX / R6 / frozen / lm06 | present | **FACT** — refuse list only; not a program path |
| `[\s\S]` | absent both copies | **FACT** — 0 matches |
| `e2r_la_pmod_ja.xdc` | omitted | **FACT** — comment-only; `read_xdc`=0; `source ` =0 |
| Executed this gate | NO | **FACT** — see PROGRAM table |

### PROGRAM = NO (this gate)

| Check | Result |
|-------|--------|
| LONGBOOT bag `program_*.log` / `*.jou` / `uart_longboot*` | **absent** |
| Any `program_*.log` / `*.jou` under board `results/A7-NATIVE-GRAPH` after REARM 12:03:23 | **absent** — newest is REARM `program_excl.log` 2026-08-28 **12:03:23** |
| Bit file mtime | 2026-08-28 **01:55:44** (BUILD; not rewritten) |
| Board `rtl/**` mtime after 2026-08-28 15:00 (PREP vehicle window) | **absent** |
| Workspace terminals `program_hw_devices` / `open_hw_manager` / `capture_uart_longboot` this window | **absent** — COM12 terminals are prior ATOM / REARM / LONG listen (Aug 28 10:51–13:31) |
| `BRIDGE.json` `lock.owner` | `grok` (R6 MIG). PREP did not take the lock. |
| `BRIDGE.json` `board.com12_authorized_gate` | still leftover consumed `E2R-UART-HOLD-REARM-00` — **not used** |
| DISPATCH last implementer line | `gate=E2R-UART-HOLD-LONGBOOT-PREP-00` `agent=a7-vivado-gate` `result=PASS_NARROW` `class=PREP_READY` `program=false` |

`BRIDGE.board.program_authorized=true` is leftover from the consumed REARM authorize. It is **not** evidence a second program ran. No new program artifact exists after 12:03:23.

Board `rtl/board/arty_a7_ng_native_v1_ab_soc_top.sv` is dirty vs HEAD (mtime **2026-08-28 00:57:21**, prior E2R ladder). That mtime is before this PREP vehicle (15:21) and is **not** this gate’s RTL edit. Implementer Task wrote bag + tcl + CLOSEOUT only.

### Copied BUILD timing (not a PREP metric)

WNS 0.372 ns / TNS 0.000 ns / DSP 19 remain BUILD provenance of `E2R-ATOMIC-SDONE-PROBE-00`. Closeout labels them “not re-run.” Not a silicon class input for this PREP.

---

## Claim grades

| Claim | Grade | Note |
|-------|-------|------|
| PROGRAM=NO this gate | **FACT** | No new journal; bit mtime BUILD; no COM12 capture file; terminals are prior gates |
| COM12 not opened this gate | **FACT** | no `uart_longboot.txt`; no longboot listen terminal |
| New script does not stop on ATOM0+ATOM1 | **FACT** | grep 0 |
| `hold_after_atom` default ≥2400 and refuse lower | **FACT** | 2400.0 / `<2400` → exit 2 |
| `max-seconds` default ≥2700 and refuse lower | **FACT** | 2700.0 / `<2700` → exit 2 |
| Hold defaults still 300/600 | **FALSE** (attacked; not present) | 300/600 remain CONTROL-only |
| Bit SHA `9DC0F8DF…` | **FACT** | Independent re-hash MATCH |
| Tcl programs only SDONE probe bit + JTAG `210319BE776EA` | **FACT** | path-match + refuse list; `[\s\S]` absent |
| Both tcl copies identical | **FACT** | SHA `A825187D…` |
| CLASS=`PREP_READY` | **FACT** (class rule) | Vehicle + SHA + tcl + PROGRAM=NO; not a UART class |
| C_FIX=NONE | **FACT** | No RTL path this gate |
| BOARD_PASS / EXISTENCE not claimed | **FACT** | bag + pointer closeouts; DISPATCH `existence`/`board_pass` false |
| `graph_late_materialize_00` not closed | **FACT** | LOOP_STATE stays QUEUED / `deferred_by=EXISTENCE_BEFORE_QUALITY` |
| Silicon still stalled / pred from boot | **UNKNOWN** | not this unit; PREP did not listen |
| Bit `9DC0F8DF…` still on FPGA now | **ENGINEERING_INFERENCE** | Last exclusive program REARM 12:03:23; no readback this gate |

PREP_READY is **not** an overclaim. It is the dispatch class for “files on disk, no program.”

---

## Forbidden PASS routes (searched)

| Route | Result |
|-------|--------|
| Self-declared BOARD_PASS / `NATIVE_V1_*_BOARD_PASS` | **absent** |
| Existence claimed without `pred=664` | **absent** — EXISTENCE not claimed; `pred=664` not measured |
| Program / `open_hw_manager` / `hw_program` / COM12 listen this gate | **absent** |
| ATOM stop left in new capture | **absent** |
| Hold defaults leftover 300/600 as the only knobs | **absent** |
| Wrong bit path (SGO / F1x / B-FIX / R6 / lm06 / frozen) | **absent** — refuse list; bit path SDONE only; SHA MATCH |
| RTL edit this gate | **absent** — no board `rtl/**` mtime after 15:00; Task wrote bag/tcl/CLOSEOUT |
| Golden/expected edited to match | **absent** — no UART this unit |
| C-FIX / A2 / LiteScope / UART strip | **absent** |
| Host winner/answer/`pred=` | **absent** |
| H5 / S2 clamp / 01R-02M-LM06 glue | **absent** |
| Frozen LM-06 / 01R / 02M overwrite | **absent** — bit mtime still BUILD 01:55:44 |
| `[\s\S]` in tcl | **absent** |
| `graph_late_materialize_00` promoted | **absent** — stays DEFERRED |
| Grok `BRIDGE.lock` stolen | **absent** — `lock.owner=grok` |

---

## Dispatch vs LOOP_STATE (process)

| Item | Value |
|------|--------|
| `LOOP_STATE.next` / first remaining graph id | `graph_late_materialize_00` QUEUED, `deferred_by=EXISTENCE_BEFORE_QUALITY` |
| DISPATCH_LOG last implementer `gate` | `E2R-UART-HOLD-LONGBOOT-PREP-00` |
| last implementer `agent` | `a7-vivado-gate` (matches `E2R_UART_HOLD_LONGBOOT_PREP_DISPATCH.md`; Task `1963bfc7-f04e-4575-9923-702ba0499918`) |
| last implementer `result` | `PASS_NARROW` `class=PREP_READY` `program=false` |
| last `note` | existence side-lane; not `graph_late_materialize_00`; PROGRAM=NO |

Last DISPATCH may be this side-lane gate. That does **not** FAIL this audit. Prior UART-HOLD PREP audits used `PASS_NARROW` on the same exception. `graph_late_materialize_00` stays **DEFERRED**. Do **not** promote this PASS_NARROW to a graph-loop close.

---

## CLASS=PREP_READY — supported?

**Yes.** Dispatch: gate PASS = vehicle on disk + SHA match + PROGRAM=NO. Existence is not this gate.

This unit: capture script without ATOM-stop; floors 2400/2700 with refuse-lower; exclusive tcl points only at SDONE bit `9DC0F8DF…`; JTAG `210319BE776EA`; no `[\s\S]`; no program; no COM12 open.

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
| NEXT | **wait** until human sets `com12_authorized_gate=E2R-UART-HOLD-LONGBOOT-00`. Then program+capture as that gate only. Do not program from this PREP. Do not use leftover REARM authorize. Do not dispatch `graph_late_materialize_00` from this side-lane. |

---

## NOT VERIFIED

- FPGA still holds SHA `9DC0F8DF…` at 13:50 — no JTAG readback this gate. Last exclusive program log is REARM 12:03:23. Inference only.
- Live classification (`PRED_LATER` / `STILL_STALL` / …) — script was not executed; class strings exist, behavior on a real UART stream is the next gate.
- Archived tcl success `puts` still says `PROGRAM not executed this gate` after `program_hw_devices`. Harmless for this PREP (tcl was not run). Later LONGBOOT journal must not treat that banner as proof program was skipped.
- If ATOM1 arrives after 300 s, default `max_s=2700` will cut the after-ATOM1 hold short of 2400 s. That is the same slack pattern as CONTROL 300/600. Not a PREP_READY falsifier; it is a later-listen window limit.

**Stop:** do not program. Do not declare existence or BOARD_PASS. Do not dispatch `graph_late_materialize_00` from this side-lane. Parent waits for human `com12_authorized_gate=E2R-UART-HOLD-LONGBOOT-00`.
