# AUDIT — E2R-ATOMIC-SDONE-PROBE-00 (PROGRAM, CLASS=SDONE_HIT)

**Auditor:** `a7-evidence-auditor` (adversarial)  
**Date:** 2026-08-28  
**Gate:** `E2R-ATOMIC-SDONE-PROBE-00` (existence side-lane; not `LOOP_STATE.next`)  
**Author claim:** PROGRAM **PASS** / CLASS=`SDONE_HIT` (`a7-vivado-gate`)  
**MUST_READ_UNBLOCK_H5:** read. Next = ungated DIFF twin (not S2, not glue). This gate is not an encoder closeout; H5 / S2 / 01R-glue routes were not used.

```text
AUDIT: CLEAN
VERDICT: PASS_NARROW
CLASS=SDONE_HIT: supported (ATOM0 dest=4 ∧ bit7=1)
EXISTENCE: NO
BOARD_PASS: not_claimed
C_FIX: NONE
```

Gate PASS (ATOM rows captured and decoded) is file-backed.  
This is **not** `NATIVE_V1_EXISTENCE_BOARD_PASS`, **not** `NATIVE_V1_MINI_AI_BOARD_PASS`, **not** TinyGPT/core done, and **not** a close of `graph_late_materialize_00`.

---

## Verdict line

`AUDIT: CLEAN` — no CRITICAL / MAJOR / MINOR that changes the PROGRAM decode claim.  
Forbidden PASS routes not taken. Sequential `SDONE=0` is not the class. Same hex as F1x DGR ATOM is coincidence-check only (wrong-bit **not** supported).

---

## Independent re-derivation (headline numbers)

### Bit SHA / JTAG / COM12 arm

| Artifact | Claimed | Independent |
|----------|---------|-------------|
| `arty_a7_ng_native_v1_atomic_sdone_probe_00.bit` | `9DC0F8DFF7BF068A92ED3E5A1A5B66FF5C56BEB7D6B3FACA7911912D498F951B` | **MATCH** (Get-FileHash SHA256; 3826011 B; mtime 2026-08-28 01:55:44 — BUILD, not rewritten at program) |
| `BIT_SHA256.txt` | same | **MATCH** |
| JTAG | `210319BE776EA` | **MATCH** — `program_excl.log` `HW_TARGETS=localhost:3121/xilinx_tcf/Digilent/210319BE776EA` (one target; PYNQ/second refused by tcl) |
| Program marker | `E2R_ATOMIC_SDONE_PROBE_00_EXCL_PROGRAM_PASS` | **FACT** — log line names this bit path only |
| `program_hw_devices` | this bit | **FACT** — `vivado/tcl/program_e2r_atomic_sdone_probe_00_excl.tcl` sets `PROGRAM.FILE` to the SDONE path; refuses SGO/F1x/B-FIX/R6/frozen/`*lm06*` |
| COM12 armed before program | claimed | **FACT** — terminal `728513` `started_at=2026-08-28T03:51:05.623Z` = **10:51:05+07**; Vivado session start **10:51:25+07**; exit **10:51:48+07**; UART file write **10:51:49+07**. Arm precedes program by ~20 s. Title: `Arm COM12 UART ATOM capture`. |
| UART payload bytes | 593 | **MATCH** — script `UART_BYTES: 593` (serial `buf`); on-disk file 658 = 593 + 65 CR (`LF=65`) |
| `BRIDGE.json` `com12_authorized_gate` | this id | **MATCH** — `E2R-ATOMIC-SDONE-PROBE-00`; `program_authorized=true`; human plugged 10:46+07 |
| Soft debug / LiteScope | none | **FACT** — `Labtools 27-1434` no supported soft debug core; BUILD `BSCANE2=0` (prior BUILD audit) |

### ATOM pack (preregistered SDONE bits, `[31:13]=0`, `[12:11]=0`)

Independent decode of UART hex (not the closeout table):

`0x0000059C` bits `{2,3,4,7,8,10}`  
→ dest=4, owner=1, grant=1, idle=0, **sdone_latch=0**, **sdone_sticky=1**, **w_stall=1**, **core_done=0**, mgo=1, reserved=0, hi=0.

`0x0000059D` = ATOM0 + 1 → dest=5, all other fields unchanged.

Matches `uart_capture.txt` `ATOM0=0000059C` / `ATOM1=0000059D`, live COM12 decode in terminal `728513` (`CLASS: SDONE_HIT`), and board `CLOSEOUT.md`.

Rule (dispatch + capture script, ATOM0 UNIT, first match):  
`CLASS=SDONE_HIT` **iff** dest=4 and (bit6 \| bit7)=1.

ATOM0 dest=4, bit7=1 → **SDONE_HIT**.  
ATOM1 dest=5 is the next-core-cycle companion row, not the class UNIT.  
`WSTALL` does not win: HIT matches first; bit8=1 is decode only.  
`SDONE_MISS` does not apply (sticky=1).

Sequential `SDONE=0` **must not** be class — it is present (`uart_capture.txt` line `SDONE=0`) and was excluded (`SEQUENTIAL_NOT_CLASS SDONE=SDONE=0`). Banner `W_STALL` / `PHASE=01` are CONTROL.

### Coincidence check — same hex as F1x DGR, not SGO

| Control | ATOM0 | Bit SHA | Grade |
|---------|-------|---------|-------|
| This program | `0000059C` | `9DC0F8DF…498F951B` | **FACT** |
| F1x DGR | `0000059C` (same hex, **different pack**) | `77116381…E66C48EA` | hex coincidence only |
| ATOMIC-SGO CONTROL | `00001B9C` (**different hex**) | `832E55E2…B16385D2` | **not this capture** |

Wrong-bit (programmed leftover SGO `832E55E2…` or F1x `77116381…`) is **not supported**:

- Program log `PROGRAM.FILE` / PASS marker is the SDONE path only.
- On-disk SGO bit SHA **unchanged** `832E55E2…` (mtime 2026-08-27 23:45:23).
- On-disk F1x bit SHA **unchanged** `77116381…` (mtime 2026-08-27 19:59:09).
- Exclusive tcl refuses those paths.
- This UART ATOM0 ≠ SGO `00001B9C`.
- Same `0000059C` as F1x is the overlapping bit positions `{2,3,4,7,8,10}` under a **new** pack map (DGR fifo_ne/c_rvalid vs SDONE sticky/w_stall). Not evidence the F1x SHA was written.
- Armed capture sat silent ~20 s, then printed a full `BOOT`…`ATOM1` stream after `program_hw_devices` — consistent with reconfig of this bit, not an idle leftover FPGA reprint without program.

Do **not** treat hex coincidence as wrong-bit.

### Timing (post-route BUILD; not re-run at program)

`report_timing_summary.rpt` Design Timing Summary line 141: WNS **0.372** TNS **0.000** WHS **0.013** THS **0.000**.  
Matches closeout. Provenance remains BUILD Physopt postRoute (prior BUILD audit `AUDIT_E2R_ATOMIC_SDONE_PROBE_00.md`). Not a silicon class input.

### `pred=664` / existence / C_FIX / A2

| Check | Result |
|-------|--------|
| `pred=664` / any `pred=` / `664` in `uart_capture.txt` | **absent** |
| Terminal `PRED_664` | `False` |
| EXISTENCE | **NO** |
| BOARD_PASS / `NATIVE_V1_*_BOARD_PASS` | **not claimed** (closeout, script, DISPATCH `board_pass=false`) |
| C_FIX | **NONE** — `SOURCE_SHA256.txt`; `a7ng_wdma_cdc.sv` SHA `FE13D1BB…BF92D7` unchanged |
| A2 / LiteScope / ILA | **absent** |
| TinyGPT / core done sold as PASS | **absent** — ATOM0 `core_done=0`; closeout keeps bit9 as decode |
| Rebuild at program | **absent** — bit mtime still BUILD 01:55:44 |

`e2r_metrics.txt` / `SOURCE_SHA256.txt` still say `PROGRAM=NO` — leftover **BUILD** stamps, not the program record. Closeout + DISPATCH_LOG + `program_excl.log` are the program authority. Not a class void.

---

## Claim grades

| Claim | Grade | Note |
|-------|-------|------|
| ATOM0=`0000059C` dest=4 owner=1 grant=1 idle=0 latch=0 sticky=1 w_stall=1 core_done=0 mgo=1 | **FACT** | Re-derived from UART hex + SDONE pack |
| ATOM1=`0000059D` dest=5 (next core cycle) | **FACT** | dest+1; sticky stays 1 |
| CLASS=`SDONE_HIT` (bit7) | **FACT** (class rule) | dest=4 and bit7=1. First match. Sequential `SDONE=0` excluded |
| Sequential `SDONE=0` is print-path CONTROL, not class | **FACT** | Present; not used |
| ATOM0 `core_done=0` `w_stall=1` | **FACT** (decode) | Not a second PASS; not TinyGPT done; `WSTALL` does not override HIT |
| H_CANDIDATE `SDONE_MISS` | **not supported** | sticky=1 |
| H_RIVAL `SDONE_HIT` | **supported** (this unit) | dest=4 ∧ synced sticky=1. Means sticky was already 1 at first dest=4∧owner, **not** that `s_done` rose on that exact cycle |
| Same hex as F1x DGR | **coincidence-check only** | Pack reinterpretation; SGO CONTROL was `00001B9C` |
| C_FIX=NONE / no A2 / no LiteScope | **FACT** | SOURCE SHA; hw_server no soft debug core |
| pred=664 absent → EXISTENCE=NO | **FACT** | This capture; script stops at ATOM0+ATOM1 |
| n=1 descriptive | **FACT** | One boot query |
| BOARD_PASS not claimed | **FACT** | closeout, terminal, DISPATCH |
| Frozen LM-06 / 01R / 02M / SGO / F1x not overwritten | **FACT** | SHA + mtime |
| Gate PASS = rows decoded | **FACT** | Not existence |

---

## Forbidden PASS routes (searched)

| Route | Result |
|-------|--------|
| Self-declared BOARD_PASS / `NATIVE_V1_*_BOARD_PASS` | **absent** |
| Sequential `SDONE=` sold as class | **absent** — ATOM rows only |
| Existence claimed without `pred=664` | **absent** — EXISTENCE not claimed |
| C-FIX / A2 / force dest / LiteScope | **absent** |
| XSim occupancy sold as board ATOM | **absent** — UART hex is the class source |
| Golden/expected edited to match | **absent** — FPGA printed hex; host only decodes |
| Host winner/answer/pred | **absent** — no pred |
| Claim expanded to TinyGPT / core done | **absent** — `core_done=0` kept as decode |
| H5 / S2 clamp / 01R-02M-LM06 glue | **absent** |
| SGO `832E55E2…` / F1x `77116381…` / frozen LM-06 overwrite | **absent** |
| Wrong-bit from hex coincidence | **not supported** — see coincidence check |
| `graph_late_materialize_00` promoted | **absent** — stays DEFERRED |

---

## Dispatch vs LOOP_STATE (process)

| Item | Value |
|------|--------|
| `LOOP_STATE.next` / first OPEN | `graph_late_materialize_00` QUEUED, `deferred_by=EXISTENCE_BEFORE_QUALITY` |
| DISPATCH_LOG last `gate` | `E2R-ATOMIC-SDONE-PROBE-00` (line 229; last ATOMIC-SDONE **PROGRAM** line) |
| last `agent` | `a7-vivado-gate` (matches pipeline `character_id`) |
| last `result` | `PASS_NARROW` `class=SDONE_HIT` `atom0=0000059C` `program=true` `existence=false` `board_pass=false` `jtag=210319BE776EA` |
| last `note` | existence side-lane; not `graph_late_materialize_00`; sequential `SDONE=0` is print-path; `pred=664` absent |

Last DISPATCH may be this side-lane gate. That does **not** FAIL this audit. `graph_late_materialize_00` stays **DEFERRED**. Do **not** promote this PASS to a graph-loop close.

---

## CLASS=SDONE_HIT — supported?

**Yes.** Preregistered rule: dest=4 and (bit6 or bit7)=1.  
ATOM0 dest=4, bit7=`sdone_sticky` synced=1.  
Sequential `SDONE=0` is print-path, not occupancy.

`core_done=0` and `w_stall=1` are decode of the same word. They do **not** create a WSTALL class, a TinyGPT-done claim, or an existence claim.

n=1. Descriptive. Existence remains **OPEN** until UART `pred=664`.

---

## Existence / BOARD_PASS

| Item | Value |
|------|--------|
| EXISTENCE | **NO** — `pred=664` not in this capture |
| BOARD_PASS | **not_claimed** |
| `NATIVE_V1_MINI_AI_BOARD_PASS` | **not claimed** |
| `NATIVE_V1_EXISTENCE_BOARD_PASS` | **not claimed** |
| C_FIX | **NONE** |
| NEXT | existence still OPEN. Do not reprogram SGO `832E55E2…` or F1x `77116381…`. Do not open A2 / LiteScope / C-FIX from this class. |

---

## NOT VERIFIED

- Named CDC leftover No-ASYNC_REG endpoints on `clk_pll_i→core_clk` (BUILD `report_cdc.rpt` is summary-only). Not a program-class input; prior BUILD audit graded `Unsafe=0` on that pair.
- Whether sticky=1 means `s_done` rose on the dest=4∧owner cycle, or was already set from an earlier window. Class rule is level (bit6\|bit7), not an edge. Closeout does not claim the edge.
- Live JTAG uniqueness beyond the single `HW_TARGETS` string in this log (no second cable attached in the log).
- Task-vs-parent authorship of the program tcl beyond DISPATCH_LOG `agent=a7-vivado-gate` and the sourced board-tree tcl path.

**Stop:** do not declare existence or BOARD_PASS. Do not expand `SDONE_HIT` to TinyGPT done. Do not treat `0000059C` hex coincidence with F1x as wrong-bit. Do not dispatch `graph_late_materialize_00` from this side-lane.
