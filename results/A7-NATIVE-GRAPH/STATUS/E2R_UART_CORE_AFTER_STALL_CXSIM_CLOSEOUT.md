# E2R-UART-CORE-AFTER-STALL-CXSIM-00 — STATUS seal

**Agent:** `a7-ng-xsim-verify`  
**Archive:** `D:/Jetking_sem4/SEM_4/arty-a7-online-lm-board/results/A7-NATIVE-GRAPH/E2R-UART-CORE-AFTER-STALL-CXSIM-00/`  
**XSIM:** PASS · CLASS=**CORE_PRED** · C_FIX=NONE · PROGRAM=NO  
**Log SHA:** `7F327F091D1889866087B0C4FE2BECB7CA57E1876A1B57BB6B9770BE7D77C86A`

sel_after_C=**54** sel_after_D=**55**. After mask 51/52, late `core_done` then `pred_ready` selected 54 then 55 on the copied `hb_next`.  
H_CANDIDATE `PRINT_DEAD` **falsified on this replica**. H_RIVAL `CORE_PRED` supported.

XSim ≠ board. Silicon REARM ended `W_STALL`/`PHASE=01` without `CORE_DONE` — this bag does not claim that print happened. Existence NO. BOARD_PASS not claimed. No UART RTL fix authorized.
