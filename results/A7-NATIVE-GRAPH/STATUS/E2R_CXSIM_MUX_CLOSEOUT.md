# E2R C-XSIM-MUX CLOSEOUT — SET, no C-FIX wire

**Agent:** [a7-ng-xsim-verify](68c480da-8863-496b-b5cc-4b6c9ccf9a79)  
**Archive:** `E2R-RPATH-IDLE-CXSIM-MUX-00/`  
**XSIM:** PASS · `VERDICT_CLASS=SET` · `WIRE=AMBIGUOUS` · `C_FIX=NONE`

Shared stub + CDC + B1 + ungated `cdc_rvalid=rvalid`. Legal `TILE_DST=4`.  
At dest-wait: `fifo_cnt=4` **and** `c_rvalid=1` → idle=0. `GRANT_ROSE=1`.  
At `WDMA_GO` (before shared WDMA R): idle=1 grant=1 all four 0.

H_CANDIDATE **supported** on this mux vehicle. H_RIVAL NONE **falsified** here.  
`SET` does **not** name a C-FIX wire. Silicon `GRANT=0` is **not** reproduced (leftover after grant ≠ leftover that blocked grant).

XSim ≠ board. Stub ≠ MIG. No BOARD_PASS.
