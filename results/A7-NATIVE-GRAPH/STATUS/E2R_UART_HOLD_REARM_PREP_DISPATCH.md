# E2R-UART-HOLD-REARM-PREP-00 — DISPATCH (PROGRAM=NO)

**Agent:** `a7-vivado-gate`  
**Workspace:** `D:/Jetking_sem4/SEM_4/arty-a7-online-lm-board`  
**PROGRAM:** **NO** — do not `open_hw_manager`, do not `program_hw_devices`, do not touch COM12 TX/DTR reset.  
**Rebuild:** **NO**.  
**R6 lock:** grok (do not steal).  
**C_FIX / A2 / LiteScope:** NONE.

COM12 is physically listed. Authorize is still consumed `E2R-ATOMIC-SDONE-PROBE-00`. Goal-continue ≠ grant. If tempted to program: **stop**.

## Scientific frame

| Field | Value |
|-------|-------|
| OBSERVATION | First boot capture used `capture_uart_atom.py` which **STOP**s at ATOM0+ATOM1. File still shows `W_STALL`/`PHASE=01` after ATOM (print continued). `hb_next` places CORE_DONE/PRED after those rows. Later listen SILENT 0 B. Same bit SHA `9DC0F8DF…`. |
| UNKNOWN | Can we freeze a hold-past-ATOM capture vehicle and archive the exclusive program path for that same bit, without programming? |
| H_CANDIDATE | `PREP_READY`: script never stops on ATOM; holds ≥300 s after ATOM1 **or** until `pred=664`; SHA match; program tcl points only at SDONE bit. |
| H_RIVAL | `PREP_FAIL`: ATOM stop remains; wrong bit path; program attempted. |
| FALSIFIER | Any program this turn; C-FIX; leftover XSim bag; `graph_late_materialize_00`. |
| UNIT | one capture script + one exclusive program tcl + one SHA verify |
| CONTROL | `capture_uart_atom.py` ATOM stop; `listen_uart_hold.py` 180 s listen-only no program |
| METRICS | no ATOM-stop; `hold_after_atom_s>=300`; `max_s>=600`; bit SHA exact; PROGRAM=NO |

Gate PASS = vehicle on disk + SHA match + PROGRAM=NO.  
Existence is **not** this gate. Existence stays UART `pred=664` on a later authorized REARM.

## Write (board worktree only)

1. `results/A7-NATIVE-GRAPH/E2R-UART-HOLD-REARM-00/capture_uart_rearm.py`
   - COM12 115200. Open with DTR/RTS false (same as listen-only).
   - **Never** stop because ATOM0/ATOM1 appeared.
   - After ATOM1 seen: continue ≥300 s more, unless `pred=664` / `PRED=664`.
   - Absolute max ≥600 s from start (or `--max-seconds`).
   - Stop early **only** on `pred=664`.
   - Classify: `PRED_LATER` / `CORE_DONE_LATER` / `STILL_STALL` / `SILENT` / `NO_ATOM` (if never saw ATOM and window ended).
   - Print ATOM decode if present (same pack as SDONE). Sequential `SDONE=`/`SGO=`/`GRANT=` are CONTROL, not class.
   - `C_FIX: NONE`, `BOARD_PASS: not_claimed`, `EXISTENCE: not_claimed` unless exact `pred=664`.
2. Archive exclusive program tcl (copy + retitle, **do not run**):
   - Source: `vivado/tcl/program_e2r_atomic_sdone_probe_00_excl.tcl`
   - Dest: `vivado/tcl/program_e2r_uart_hold_rearm_00_excl.tcl` **and** bag copy under `E2R-UART-HOLD-REARM-00/`
   - Must program **only** `E2R-ATOMIC-SDONE-PROBE-00/arty_a7_ng_native_v1_atomic_sdone_probe_00.bit`
   - Refuse SGO/F1x/B-FIX/R6/frozen/lm06/second target/PYNQ. JTAG must be `210319BE776EA`.
   - No `[\s\S]` in Tcl.
3. Re-hash the bit. Must be `9DC0F8DFF7BF068A92ED3E5A1A5B66FF5C56BEB7D6B3FACA7911912D498F951B`.
4. CLOSEOUT under the bag: PREP only. PROGRAM=NO. No existence claim.

Do **not** edit `rtl/**`. Do **not** overwrite frozen LM-06 / 01R / 02M / A0.3. Do **not** strip UART probes.

## After PREP

Wait. Next program is **`E2R-UART-HOLD-REARM-00`** only after `com12_authorized_gate` is exactly that id.
