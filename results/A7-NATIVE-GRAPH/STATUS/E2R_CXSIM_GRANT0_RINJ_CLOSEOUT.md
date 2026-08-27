# E2R C-XSIM-GRANT0-RINJ CLOSEOUT — dest=4 with grant=0; idle=1

**Agent:** [a7-ng-xsim-verify](0adb1b5b-8cb0-4af4-80b4-131fcebb2395)  
**Archive:** `D:/Jetking_sem4/SEM_4/arty-a7-online-lm-board/results/A7-NATIVE-GRAPH/E2R-RPATH-IDLE-CXSIM-GRANT0-RINJ-00/`  
**XSIM:** PASS · `VERDICT_CLASS=NONE` · `WIRE=NONE` · `C_FIX=NONE`  
**Log SHA256:** `3F169C1CB461116F5595DD7499F1FE71F6085F26E63E419AADB38DC47151767D`

## Scientific result

| Field | Value |
|-------|-------|
| OBSERVATION | GRANT0 dest starved at `D_DRAIN=3` without R. Silicon UART same-cycle: `TILE_DST=4` `GRANT=0` `OWNER=1` `RPATH_IDLE=0`. |
| UNKNOWN (this bag) | After dest=3, do 8 TB-injected CDC-slave `dma_r_valid` beats make DUT dest=4 with grant held 0? |
| ACTUAL | dest 3→4; `R_INJECTED=8`; `GRANT_STAYED_0=1`; AND `0000`; `idle=1` |
| H_CANDIDATE | **supported** for dest=4 via leftover R without grant |
| H_RIVAL (dest stays 3) | **falsified** on this vehicle |
| EXISTENCE | **not claimed** (`pred=664` absent) |
| BOARD_PASS | **not claimed** |

Grant stayed 0. WDMA stub stayed `W_WAITOWN`. Inject was **CDC-slave tile R**, not shared stub/mux R. At first dest=4, leftover occupancy was already gone (`idle=1`).

## What this does not close

Silicon snapshot is the **triple** `TILE_DST=4 ∧ GRANT=0 ∧ RPATH_IDLE=0`.  
RINJ occupies `4 ∧ 0` with `idle=1`. Silicon leftover `RPATH_IDLE=0` is **not** reproduced.

XSim ≠ board. Stub ≠ MIG. TB inject ≠ silicon leftover R. **No C-FIX.**
