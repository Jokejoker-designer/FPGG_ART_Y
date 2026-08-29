# E2R-SDONE-CXSIM-00 — STATUS seal

**Agent:** `a7-ng-xsim-verify` [141af702](141af702-88f7-4f09-85d0-29573b1a2bf5)  
**Archive:** `D:/Jetking_sem4/SEM_4/arty-a7-online-lm-board/results/A7-NATIVE-GRAPH/E2R-SDONE-CXSIM-00/`  
**XSIM:** PASS · CLASS=**SDONE_ROSE** · C_FIX=NONE  
**Log SHA:** `DF55ACF49B11E170DFBC6E38E1B302128EB9F6D7433F0D08A4B7A02495118520`

dest=4 grant=1 leftover SET. Completable responder: `s_go` ever=1, `s_done` / `dbg_s_done_sticky`=1 at dest=4.  
H_CANDIDATE `SDONE_NEVER` **falsified on this stub**. Leftover SET does not forbid done when the responder completes.

XSim ≠ board. Silicon ATOM `dma_st=5(R)` at dest=4 is still-in-R. Sequential `SDONE=0` not answered. Existence NO.

Post-`pred=664` (human): strip UART probe rows — not now.
