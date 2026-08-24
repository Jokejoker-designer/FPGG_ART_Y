# closeout — wm00_timing

**result:** PASS_NARROW  
**artifact:** `results/A7-NATIVE-GRAPH/BRAM-WM-00/timing/GATE_wm00_timing.md`  
**marker:** `A7NG_BRAM_WM00_XSIM_PASS` (re-run after systolic Top-8)  
**primary_rtl:** `a7ng_wm00_evidence.sv` SHA256=`A99C6C7324167A49013ED110B03F6735AF195C0CEF94478B90C3E11B747D0740`  
**top_rtl:** `a7ng_wm00_top.sv` SHA256=`0B76BCF9CC289E9EC877F0A8ABE594658A32D8D667AFCF0EEF844C703D932E25`

## UNKNOWN closed

Single change = systolic Top-8 pipeline (dedupe + K shift).  
OOC post-route: **WNS=+0.069 ns**, **TNS=0.000**, constraints met.  
XSim: lossless 8 bags PASS. Frozen bits MATCH. Control WNS=−290.499 archived under `timing/CONTROL_*`.

## Explicit refusals

- No BOARD_PASS  
- No `BRAM_WORKING_MEMORY_ARCH_PASS` (§45)  
- No full-chip / LM-06 SoC 100 MHz claim (OOC WM-only)  
- Did not wipe LM-06 / NG archives  

## NEXT

Orchestrator: flip `wm00_timing` DONE_ENG after auditor; continue LOOP_STATE queue (GOAL still unmet until §14 / human BOARD_PASS).
