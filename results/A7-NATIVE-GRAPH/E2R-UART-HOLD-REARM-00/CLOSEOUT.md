# E2R-UART-HOLD-REARM-00 — CLOSEOUT (CLASS STILL_STALL, PROGRAM=YES, no BOARD_PASS)

**Agent:** `a7-vivado-gate`  
**Workspace:** `D:/Jetking_sem4/SEM_4/arty-a7-online-lm-board`  
**Authority:** `STATUS/E2R_UART_HOLD_REARM_DISPATCH.md` + `STATUS/MASTER_PREFLIGHT.md` + human 2026-08-28T11:58+07  
**BRIDGE.lock.owner:** grok (not stolen)  
**com12_authorized_gate:** `E2R-UART-HOLD-REARM-00` (re-read immediately before `open_hw_manager`; leftover `E2R-ATOMIC-SDONE-PROBE-00` authorize **not used**)  
**PROGRAM:** **YES** (one exclusive reprogram of the SDONE probe bit)  
**JTAG:** `210319BE776EA` (single target; PYNQ / second target refused)  
**UART:** COM12 115200 armed **before** program (`capture_uart_rearm.py`; DTR/RTS false; **no ATOM stop**)  
**UART_BYTES:** 593  
**STOP_REASON:** `hold_after_atom` (ATOM1 at 52.265 s; held 300 s more; total 352.406 s; max 600 s not hit)  
**C_FIX:** **NONE**  
**BOARD_PASS:** **not claimed**  
**EXISTENCE:** **not claimed** (`pred=664` absent)

XSim ≠ board. One query. Sequential `SDONE=` / `SGO=` / `WDMA_GRANT=` and banner `W_STALL` / `PHASE=` are CONTROL, not a second class. No LiteScope/ILA. No A2 / C-FIX / rebuild. Did not reprogram SGO / F1x / B-FIX / R6 / frozen LM-06 / 01R / 02M / A0.3. Did not Task `graph_late_materialize_00`.

## Scientific frame

| Field | Value |
|-------|-------|
| OBSERVATION | Prior SDONE_HIT ATOM0=`0000059C`. First capture STOP at ATOM. Later listens SILENT. `hb_next` prints CORE_DONE/PRED after W_STALL/PHASE. |
| UNKNOWN | on one fresh boot with capture that does not stop at ATOM, does CORE_DONE or pred=664 appear? |
| H_CANDIDATE | `STILL_STALL` after ATOM+≥300 s (core hang after SDONE **open**) |
| H_RIVAL | `PRED_LATER` (`pred=664`) — observer/truncation **closed** |
| FALSIFIER | ATOM-stop script; wrong bit; C-FIX; leftover SDONE authorize; 0-byte as design FAIL. **Not used.** |
| UNIT | one reprogram + one continuous capture |
| CONTROL | PREP vehicle (PROGRAM=NO); ATOM0=`0000059C`; T+45 SILENT 0 B; sequential `SDONE=`/`SGO=`/`GRANT=` |
| METRICS | ATOM hex, class, bytes, CORE_DONE, `pred=`. Existence = exact `pred=664` only. |

## CONTROL — PREP facts (this bag, not this unit)

| Item | PREP (`E2R-UART-HOLD-REARM-PREP-00`) |
|------|--------------------------------------|
| CLASS | PREP_READY |
| PROGRAM | NO |
| SHA256 | `9DC0F8DFF7BF068A92ED3E5A1A5B66FF5C56BEB7D6B3FACA7911912D498F951B` |
| Capture vehicle | `capture_uart_rearm.py` (ATOM-stop absent; hold≥300; max≥600) |
| Tcl | `vivado/tcl/program_e2r_uart_hold_rearm_00_excl.tcl` archived, not run |
| Authorize then | leftover `E2R-ATOMIC-SDONE-PROBE-00` — this PROGRAM gate did not use it |

## Bit (re-hashed before program and after; unchanged)

| Item | Value | Provenance |
|------|-------|------------|
| ARTIFACT | `results/A7-NATIVE-GRAPH/E2R-ATOMIC-SDONE-PROBE-00/arty_a7_ng_native_v1_atomic_sdone_probe_00.bit` | existing BUILD |
| SHA256 | `9DC0F8DFF7BF068A92ED3E5A1A5B66FF5C56BEB7D6B3FACA7911912D498F951B` | Python hashlib before + after program |
| Size | 3826011 B | filesystem |
| CONTROL SGO | unchanged (not programmed) | refuse path in tcl |
| CONTROL F1x | unchanged (not programmed) | refuse path in tcl |
| Frozen LM-06 / 01R / 02M / A0.3 | not overwritten | refuse path in tcl |

Tcl: `vivado/tcl/program_e2r_uart_hold_rearm_00_excl.tcl`.  
Log: `program_excl.log` / `program_excl.jou`.  
`HW_TARGETS=localhost:3121/xilinx_tcf/Digilent/210319BE776EA` (one target).  
Marker: `E2R_UART_HOLD_REARM_00_EXCL_PROGRAM_PASS`.  
`program_hw_devices` ran (`End of startup status: HIGH`). Leftover PREP string `PROGRAM not executed this gate` on the success line is **print text only**, not the measurement.

## UART (one boot query; COM12 armed first)

593 bytes. File: `uart_rearm.txt`. Capture start `2026-08-28T12:02:31+07:00`. Program session `12:02:59`–`12:03:23+07`. Capture end `2026-08-28T12:08:23+07:00`. Script banner `program=NO` is leftover PREP text; this gate **did** program.

```text
TILE_DST=4
WDMA_OWN_UI=0
DMA_ST=0
SGO=0
WDMA_OWNER=1
WDMA_GRANT=0
RPATH_IDLE=0
MGO=1
ATOM0=0000059C
ATOM1=0000059D
W_STALL
PHASE=01
```

No further UART bytes after `PHASE=01` for the remaining ≥300 s hold. No `CORE_DONE`. No `pred=`. Sequential `SDONE=0` `SGO=0` `WDMA_GRANT=0` are CONTROL.

## ATOM decode (same pack as SDONE PROGRAM; CONTROL ATOM0=`0000059C`)

| Field | bits | ATOM0 `0000059C` | ATOM1 `0000059D` |
|-------|------|------------------|------------------|
| dest | [2:0] | 4 | 5 |
| owner | [3] | 1 | 1 |
| grant | [4] | 1 | 1 |
| idle | [5] | 0 | 0 |
| sdone_latch (UI→core) | [6] | 0 | 0 |
| sdone_sticky (UI→core) | [7] | 1 | 1 |
| w_stall | [8] | 1 | 1 |
| core_done | [9] | 0 | 0 |
| mgo | [10] | 1 | 1 |
| reserved | [12:11] | 0 | 0 |
| hi | [31:13] | 0 | 0 |

`hi_ok=True` both rows. ATOM0 matches CONTROL `0000059C`.

## Classification (exactly one)

**CLASS = STILL_STALL**

| Class | This query |
|-------|------------|
| PRED_LATER | no (`pred=664` absent) |
| CORE_DONE_LATER | no (`CORE_DONE` absent) |
| STILL_STALL | **yes** (ATOM present; W_STALL/PHASE; hold_after_atom 300 s; no pred / CORE_DONE) |
| NO_ATOM | no (ATOM0+ATOM1 printed) |
| SILENT | no (593 B, not 0-byte) |

0-byte recapture is **not** this result. Capture did **not** stop at ATOM (`ATOM1_SEEN … holding 300s more (not a stop)`).

## Numeric gates (not re-run)

This gate did not synth/impl. Post-route numbers remain BUILD provenance of `E2R-ATOMIC-SDONE-PROBE-00`.

| Metric | Value | Provenance | Gate |
|--------|-------|------------|------|
| WNS | 0.372 ns | post-route BUILD (not re-run) | PASS (≥0) prior bag |
| TNS | 0.000 ns | post-route BUILD (not re-run) | PASS (=0) prior bag |
| DSP | 19 | post-route BUILD SoC (not encoder DSP=0) | reported prior bag |

## Hypothesis status (this unit only)

| Hypothesis | Status |
|------------|--------|
| H_CANDIDATE (`STILL_STALL`) | **supported** — ATOM+≥300 s, no CORE_DONE, no `pred=664` |
| H_RIVAL (`PRED_LATER`) | **not supported** — `pred=664` absent |

n=1 query. Descriptive only. Observer/truncation at ATOM is **closed** for this boot: capture continued and silicon printed nothing further. That does not prove existence.

## Gate

| Item | Value |
|------|-------|
| GATE | E2R-UART-HOLD-REARM-00 |
| CHANGED | PROGRAM + continuous capture + this CLOSEOUT. No RTL rebuild. |
| TESTS | re-hash bit; COM12 arm first; JTAG `210319BE776EA` exclusive program; hold-past-ATOM UART |
| EXPECTED | one class from PRED_LATER / CORE_DONE_LATER / STILL_STALL / NO_ATOM / SILENT; this bit SHA only |
| ACTUAL | CLASS=`STILL_STALL`; ATOM0=`0000059C`; UART 593 B; CORE_DONE=false; `pred=664` absent; PROGRAM=YES |
| PASS\|FAIL | **PASS_NARROW** (boot captured and classed) |
| CLASS | STILL_STALL |
| ATOM0 | 0000059C |
| ATOM1 | 0000059D |
| UART_BYTES | 593 |
| PRED | null |
| C_FIX | NONE |
| BOARD_PASS | not_claimed |
| EXISTENCE | not_claimed (`pred=664` absent) |
| NEXT | `a7-evidence-auditor` on this PROGRAM PASS; existence still OPEN; do not Task `graph_late_materialize_00` |
