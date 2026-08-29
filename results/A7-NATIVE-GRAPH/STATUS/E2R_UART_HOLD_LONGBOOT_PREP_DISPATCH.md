# E2R-UART-HOLD-LONGBOOT-PREP-00 — DISPATCH (PROGRAM=NO)

**Agent:** `a7-vivado-gate`  
**Workspace:** `D:/Jetking_sem4/SEM_4/arty-a7-online-lm-board`  
**PROGRAM:** **NO** — do not `open_hw_manager`, do not `program_hw_devices`, do not open COM12.  
**Rebuild:** **NO**.  
**R6 lock:** grok (do not steal).  
**C_FIX / A2 / LiteScope:** NONE.

Authorize is consumed `E2R-UART-HOLD-REARM-00`. Goal-continue ≠ grant. If tempted to program: **stop**.

REARM 300 s `STILL_STALL` does **not** close a from-boot window of 40 min. LONG listen SILENT was a **late** window on an already-printed UART. This PREP is the vehicle for a later authorized from-boot hold, not that listen.

## Scientific frame

| Field | Value |
|-------|-------|
| OBSERVATION | CORE_PRED: UART can print 54/55 after 51/52. OSC_2ND: 2048 EMB TOK↔POS sets. FWD_HEAVY: 4.3e6 other `waddr` but rg_switches=2048 (not 4.3e6 misses). ~20 min DMA is ENGINEERING_INFERENCE. |
| UNKNOWN | Can we freeze a ≥2400 s after-ATOM1 capture vehicle + exclusive same-bit program path without programming? |
| H_CANDIDATE | `PREP_READY`: never stop on ATOM; hold ≥2400 s after ATOM1 or until `pred=664`; max ≥2700 s; SHA match; tcl = SDONE bit only |
| H_RIVAL | `PREP_FAIL`: ATOM stop remains; 300 s leftover; wrong bit; program attempted |
| FALSIFIER | Any program this turn; C-FIX; `graph_late_materialize_00` |
| UNIT | one capture script + one exclusive tcl + SHA verify |
| CONTROL | `capture_uart_rearm.py` hold 300 / max 600 |
| METRICS | no ATOM-stop; `hold_after_atom_s>=2400`; `max_s>=2700`; bit SHA `9DC0F8DF…`; PROGRAM=NO |

## Write (board worktree only)

1. `results/A7-NATIVE-GRAPH/E2R-UART-HOLD-LONGBOOT-00/capture_uart_longboot.py`  
   Copy REARM capture. **One change:** defaults `hold_after_atom>=2400`, `max_seconds>=2700`. Never stop on ATOM. Stop early only on `pred=664`. Same DTR/RTS false. Same classes.
2. Archive exclusive program tcl (**do not run**): copy `vivado/tcl/program_e2r_uart_hold_rearm_00_excl.tcl` (or SDONE excl) retitled for this bag. Same bit SHA only. Refuse SGO/F1x/B-FIX/R6/frozen/lm06/PYNQ. No `[\s\S]`. Omit `e2r_la_pmod_ja.xdc`.
3. CLOSEOUT + STATUS pointer. PROGRAM=NO.

Marker `E2R_UART_HOLD_LONGBOOT_PREP_00_READY` if PREP_READY. Existence not claimed.
