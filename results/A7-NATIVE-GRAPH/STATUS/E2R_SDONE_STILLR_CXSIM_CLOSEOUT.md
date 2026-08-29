# E2R-SDONE-STILLR-CXSIM-00 — STATUS seal

**Agent:** `a7-ng-xsim-verify` [05dcf3b1](05dcf3b1-d448-4d33-bd43-28319a97dea4)  
**Archive:** `D:/Jetking_sem4/SEM_4/arty-a7-online-lm-board/results/A7-NATIVE-GRAPH/E2R-SDONE-STILLR-CXSIM-00/`  
**XSIM:** PASS · CLASS=**SNAP_DONE0** · C_FIX=NONE  
**Log SHA:** `4F71A710F5899FBA1E45AD53C7FED59274CF0018073D8861FB395A6DFA7CABD7`

First dest=4 while in-R/busy: `dbg_s_done_sticky=0`. After later complete: sticky=1.  
H_CANDIDATE **supported** on this vehicle. Silicon dest=4 `dma_st=5` + sequential `SDONE=0` is **compatible** with still-in-R, not proven. ROSE bag (done before dest=4) is a different occupancy.

XSim ≠ board. Existence NO. Next silicon bind: `E2R-ATOMIC-SDONE-PROBE-00` (needs COM12). UART strip after `pred=664` only.
