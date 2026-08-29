# E2R-TILE-AFTER-SDONE-CXSIM-00 — STATUS seal

**Agent:** `a7-ng-xsim-verify`  
**Archive:** `D:/Jetking_sem4/SEM_4/arty-a7-online-lm-board/results/A7-NATIVE-GRAPH/E2R-TILE-AFTER-SDONE-CXSIM-00/`  
**XSIM:** PASS · CLASS=**CHUNK_ACK** · C_FIX=NONE · PROGRAM=NO  
**Log SHA:** `F660793B12EB2749C6E4F4C41F8136C322D017311E240F07D6A7ED98D375B034`

dest 4→5, then `bst=5` (`B_WAITACK`) at watch=5. `stall_after=1` (not stuck).  
H_CANDIDATE `ACK_STUCK` **falsified on this tile+stub**. dest=5 does not keep `bst` in `B_REQ` when done pulses and busy drops.

XSim ≠ board. UART first-seen `TILE_BST=4` compatible (snap at first dest=5 still `B_REQ`). Existence NO. BOARD_PASS not claimed.
