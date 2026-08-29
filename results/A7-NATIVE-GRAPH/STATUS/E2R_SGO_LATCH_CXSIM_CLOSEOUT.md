# E2R-SGO-LATCH-CXSIM-00 — STATUS seal

**Agent:** `a7-ng-xsim-verify`  
**Archive:** `D:/Jetking_sem4/SEM_4/arty-a7-online-lm-board/results/A7-NATIVE-GRAPH/E2R-SGO-LATCH-CXSIM-00/`  
**XSIM:** PASS · CLASS=**LATCH_HIT** · C_FIX=NONE  
**Log SHA:** `74433CAE2917FCACDBA48CDEF85A194A79376E45CC195D7213F13B4C737068AB`

At dest=4 grant=1 leftover SET: sticky=1, `latched_sgo_f1u` replica=1, `core_busy_ui`=1.

H_CANDIDATE `LATCH_MISS` **falsified on mux+stub**. Silicon sequential `SGO=0` is **not** GRANT-skew and **not** a latch-window miss on this vehicle. Next binding observer is board atomic SGO (`E2R-ATOMIC-SGO-PROBE-00`).

XSim ≠ board. Existence NO. BOARD_PASS not claimed.
