# E2R-UART-HOLD-PRED-00 — LISTEN-ONLY GO (no program)

**Agent:** `a7-vivado-gate`  
**Workspace:** `D:/Jetking_sem4/SEM_4/arty-a7-online-lm-board`  
**Results:** `results/A7-NATIVE-GRAPH/E2R-UART-HOLD-PRED-00/`  
**Bit already on FPGA:** ATOMIC-SDONE `9DC0F8DF…` (do **not** reprogram)  
**COM12** 115200 listen only. SDONE program authorize is **consumed**.

## Do not

`open_hw_manager` / `program_hw_devices` / rebuild / C-FIX / A2 / LiteScope / Phase 2 / steal Grok / BOARD_PASS / stop at ATOM.

## Scientific frame

- **OBSERVATION:** SDONE_HIT ATOM0=`0000059C` w_stall=1 core_done=0. Capture stopped at ATOM. UART ended `PHASE=01`. Silicon 12.5 MHz TinyGPT may still be live.
- **UNKNOWN:** on the already-programmed bit, if we listen past the ATOM window, does `CORE_DONE` or `pred=664` appear?
- **H_CANDIDATE:** `STILL_STALL` / `SILENT` — query over or stuck; 0 useful lines.
- **H_RIVAL:** `PRED_LATER` (`pred=664`) or `CORE_DONE_LATER`.
- **FALSIFIER:** reprogram; treat ATOM reprint as new class; C-FIX.
- **UNIT:** one listen ≥180s or until `pred=664`.
- **CONTROL:** `uart_capture.txt` ended `ATOM1=` + `PHASE=01`.
- **METRICS:** bytes, `CORE_DONE` present, `pred=` value. Existence = exact `pred=664`.

Class: `SILENT` / `STILL_STALL` (W_STALL/PHASE only) / `CORE_DONE_LATER` / `PRED_LATER`. Gate PASS = listen completed and classed. Existence only if `pred=664`.
