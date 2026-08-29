# E2R-UART-HOLD-TPLUS45-00 — DISPATCH (LISTEN-ONLY, PROGRAM=NO)

**Agent:** `a7-vivado-gate`  
**Workspace:** `D:/Jetking_sem4/SEM_4/arty-a7-online-lm-board`  
**PROGRAM:** **NO** — do not `open_hw_manager`, do not program, do not run REARM tcl.  
**Bit:** already programmed ATOMIC-SDONE `9DC0F8DF…` (~10:51+07). Do not verify by reprogramming.  
**UART:** COM12 115200. Vehicle: `E2R-UART-HOLD-PRED-00/listen_uart_hold.py` (DTR/RTS false; no ATOM stop; stop early only on `pred=664`).  
**R6 lock:** grok. **C_FIX:** NONE.

Authorize is still consumed `E2R-ATOMIC-SDONE-PROBE-00`. This gate is listen-only. If tempted to program REARM: **stop**.

## Scientific frame

| Field | Value |
|-------|-------|
| OBSERVATION | SDONE_HIT ~10:51. ATOM capture truncated. Listen 11:05–11:12 SILENT 0 B. `hb_next` emits CORE_DONE/PRED after W_STALL/PHASE if flags rise. TinyGPT @ 12.5 MHz may still be live at T+45. |
| UNKNOWN | without reprogram, does COM12 now show `CORE_DONE` or `pred=664`? |
| H_CANDIDATE | `SILENT` (no new rows in this window) |
| H_RIVAL | `PRED_LATER` or `CORE_DONE_LATER` |
| FALSIFIER | 0-byte as design FAIL; program; DTR reset; ATOM-stop capture; C-FIX |
| UNIT | one listen window, one already-programmed boot |
| CONTROL | UART-HOLD 2×180 s SILENT; same bit SHA |
| METRICS | bytes, class, CORE_DONE, `pred=` value. Existence = exact `pred=664` only |

Class: `SILENT` / `STILL_STALL` / `CORE_DONE_LATER` / `PRED_LATER`.  
Gate PASS = listen completed and classed. Existence only if `pred=664`. 0-byte = recapture once, then SILENT, not design FAIL.

## Do

1. Confirm COM12 present. Do not open JTAG.
2. One window `--seconds 600` (or two ×300 if the first is 0-byte — recapture once).  
   Out: `results/A7-NATIVE-GRAPH/E2R-UART-HOLD-TPLUS45-00/uart_hold.txt`
3. Do **not** use `capture_uart_atom.py`. Prefer `listen_uart_hold.py` (0-byte → SILENT, not NO_ATOM).
4. CLOSEOUT: class, bytes, start/end +07, PROGRAM=NO, no BOARD_PASS.
5. Append DISPATCH_LOG on **both** trees. `agent=a7-vivado-gate`, `gate=E2R-UART-HOLD-TPLUS45-00`.

Do not edit `rtl/**`. Do not steal grok lock. Do not Task `graph_late_materialize_00`.
