# E2R C-XSIM-GRANT0-RMUX CLOSEOUT — dest stayed 3

**Agent:** [a7-ng-xsim-verify](0c8435fe-141f-4c98-be6d-09538efc6235)  
**Archive:** `D:/Jetking_sem4/SEM_4/arty-a7-online-lm-board/results/A7-NATIVE-GRAPH/E2R-RPATH-IDLE-CXSIM-GRANT0-RMUX-00/`  
**XSIM:** FAIL · `VERDICT_CLASS=FAIL_NO_DESTWAIT_GRANT0` · `WIRE=NONE` · `C_FIX=NONE`  
**Log SHA256:** `0452BDD20F8C6959AB8DB546C00EDA2CFDA0C57381A9B44B9CE03A18714B7CBE`

## Scientific result

| Field | Value |
|-------|-------|
| UNKNOWN | After dest=3, do 8 leftover beats on shared stub R (ungated `cdc_rvalid=rvalid`) make dest=4 with grant=0? |
| ACTUAL | dest **3**; `R_INJECTED=8`; `dma_r_valid` during leftover **0**; `GRANT_STAYED_0=1`; `OWN_UI=0` |
| H_CANDIDATE (mux leftover → dest=4) | **not supported** |
| H_RIVAL (dest stays 3) | **supported** |
| Exploratory (not UNIT) | at dest=3: fifo=4 and `c_rvalid=1` → idle=0 |
| EXISTENCE | **not claimed** |
| BOARD_PASS | **not claimed** |

Mux leftover without grant occupies the same leftover pair the granted MUX bag saw, but dest stays `D_DRAIN=3`. Silicon triple `TILE_DST=4 ∧ GRANT=0 ∧ RPATH_IDLE=0` is **not** on this vehicle.

XSim ≠ board. Stub ≠ MIG. **No C-FIX.**
