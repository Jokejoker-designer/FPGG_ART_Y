# E2R C-XSIM-UART-SKEW CLOSEOUT — SKEW

**Agent:** [a7-ng-xsim-verify](b6810269-eafc-4ecd-bfc2-545ff1756ccd)  
**Archive:** `D:/Jetking_sem4/SEM_4/arty-a7-online-lm-board/results/A7-NATIVE-GRAPH/E2R-UART-SKEW-CXSIM-00/`  
**XSIM:** PASS · `VERDICT_CLASS=SKEW` · `C_FIX=NONE`  
**Log SHA256:** `7CD7233066CC804EED9792F958CCFB128395D654669B1D2F9C9D2098D6C09DF5`

TRANS: dest sampled from `4,0,1`, later grant/idle from `4,0,0` → printed `4,0,0` without dest taken from same-cycle `4,0,0`.

Silicon UART text `TILE_DST=4` then `GRANT=0` `RPATH_IDLE=0` is **not** proof of one occupancy. UART-ENC remains FAITHFUL for simultaneous digits. **No C-FIX. No BOARD_PASS.** XSim ≠ board.
