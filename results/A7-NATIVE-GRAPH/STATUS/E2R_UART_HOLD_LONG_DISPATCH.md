# E2R-UART-HOLD-LONG-00 — DISPATCH (LISTEN-ONLY, PROGRAM=NO)

**Agent:** `a7-vivado-gate`  
**Workspace:** `D:/Jetking_sem4/SEM_4/arty-a7-online-lm-board`  
**PROGRAM:** **NO** — do not `open_hw_manager`, do not run REARM tcl.  
**Bit:** already programmed ATOMIC-SDONE / REARM `9DC0F8DF…` (~12:03+07).  
**UART:** COM12 115200. Vehicle: `E2R-UART-HOLD-PRED-00/listen_uart_hold.py` (DTR/RTS false; no ATOM stop).  
**R6 lock:** grok. **C_FIX:** NONE.

Authorize `E2R-UART-HOLD-REARM-00` is **consumed** for program. This gate is listen-only.

## Scientific frame

| Field | Value |
|-------|-------|
| OBSERVATION | REARM hold 300 s after ATOM1 → no CORE_DONE. ST_EMB TOK↔POS ≈ 1.18e6 DMA. Unstall compute would finish in seconds. Refill @ ~1 ms/chunk ≈ 20 min. Gap after 12:08 unrecorded. |
| UNKNOWN | on the same programmed boot, if we listen **1800 s** now, does `CORE_DONE` or `pred=664` appear? |
| H_CANDIDATE | `WINDOW_SHORT` → `PRED_LATER` or `CORE_DONE_LATER` |
| H_RIVAL | `SILENT` (still no rows; does **not** falsify finish-in-gap 12:08–now) |
| FALSIFIER | program; DTR reset; 0-byte as design FAIL; ATOM-stop; C-FIX |
| UNIT | one listen window on one already-programmed boot |
| CONTROL | REARM 300 s STILL_STALL; T+45 SILENT (earlier boot) |
| METRICS | bytes, class, CORE_DONE, `pred=`. Existence = exact `pred=664` |

Class: `SILENT` / `STILL_STALL` / `CORE_DONE_LATER` / `PRED_LATER`.  
Gate PASS = listen completed and classed. 0-byte after one recapture (300 s) = SILENT, not design FAIL.

## Do

1. COM12 present. No JTAG.
2. `python .../listen_uart_hold.py --port COM12 --baud 115200 --seconds 1800 --out results/A7-NATIVE-GRAPH/E2R-UART-HOLD-LONG-00/uart_hold.txt --attempt 1`
3. If 0 bytes: one recapture 300 s → `uart_hold_retry.txt`.
4. CLOSEOUT + DISPATCH_LOG both trees. `agent=a7-vivado-gate`, `gate=E2R-UART-HOLD-LONG-00`.

Do not edit `rtl/**`. Do not Task `graph_late_materialize_00`.
