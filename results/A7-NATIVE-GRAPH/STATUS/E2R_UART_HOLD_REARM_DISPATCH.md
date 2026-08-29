# E2R-UART-HOLD-REARM-00 — DISPATCH (PROGRAM + continuous capture)

**Agent:** `a7-vivado-gate`  
**Workspace:** `D:/Jetking_sem4/SEM_4/arty-a7-online-lm-board`  
**Human authorize:** 2026-08-28T11:58+07 — one reprogram + continuous capture.  
**`com12_authorized_gate`:** **`E2R-UART-HOLD-REARM-00`** (this id only).  
**Bit:** `E2R-ATOMIC-SDONE-PROBE-00/arty_a7_ng_native_v1_atomic_sdone_probe_00.bit`  
**SHA256:** `9DC0F8DFF7BF068A92ED3E5A1A5B66FF5C56BEB7D6B3FACA7911912D498F951B`  
**JTAG:** `210319BE776EA` only. Refuse second target / PYNQ.  
**Rebuild:** **NO**. **C_FIX / A2 / LiteScope:** NONE. **R6 lock:** grok.

Re-read `BRIDGE.json` immediately before `open_hw_manager`. STOP if `com12_authorized_gate` is not exactly this id.

## Scientific frame

| Field | Value |
|-------|-------|
| OBSERVATION | SDONE_HIT ATOM0=`0000059C`. First capture STOP at ATOM. Later listens SILENT. `hb_next` prints CORE_DONE/PRED after W_STALL/PHASE. |
| UNKNOWN | on one fresh boot with capture that does **not** stop at ATOM, does `CORE_DONE` or `pred=664` appear? |
| H_CANDIDATE | `STILL_STALL` after ATOM+≥300 s (core hang after SDONE **open**) |
| H_RIVAL | `PRED_LATER` (`pred=664`) — observer/truncation **closed** |
| FALSIFIER | ATOM-stop script; wrong bit; C-FIX; leftover SDONE authorize; 0-byte as design FAIL |
| UNIT | one reprogram + one continuous capture |
| CONTROL | ATOM0=`0000059C`; T+45 SILENT 0 B |
| METRICS | ATOM hex, class, bytes, CORE_DONE, `pred=`. Existence = exact `pred=664` only |

## Order (hard)

1. Re-hash bit. Must match SHA above.
2. Confirm COM12 present.
3. **Arm COM12 first** with `results/A7-NATIVE-GRAPH/E2R-UART-HOLD-REARM-00/capture_uart_rearm.py` (`--max-seconds 600 --hold-after-atom 300`). Never stop on ATOM.
4. Then run `vivado/tcl/program_e2r_uart_hold_rearm_00_excl.tcl` (same SDONE bit only).
5. Hold until `pred=664` **or** ≥300 s after ATOM1 **or** 600 s max.
6. CLOSEOUT under the REARM bag. Class exactly one: `PRED_LATER` / `CORE_DONE_LATER` / `STILL_STALL` / `NO_ATOM` / `SILENT`.
7. Sequential `SDONE=`/`SGO=`/`GRANT=` are CONTROL. Do not overwrite SGO/F1x/frozen bits.
8. Append DISPATCH_LOG both trees. `agent=a7-vivado-gate`, `gate=E2R-UART-HOLD-REARM-00`.

Gate PASS = boot captured and classed. Existence only if UART `pred=664`. Do not claim BOARD_PASS.
