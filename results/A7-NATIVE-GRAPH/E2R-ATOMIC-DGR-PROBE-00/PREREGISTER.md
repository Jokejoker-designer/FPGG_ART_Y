# E2R-ATOMIC-DGR-PROBE-00 — PREREGISTER (before UART)

**Agent:** `a7-vivado-gate`  
**Workspace:** `D:/Jetking_sem4/SEM_4/arty-a7-online-lm-board`  
**Authority:** `STATUS/E2R_ATOMIC_DGR_PROBE_DISPATCH.md` (human DECIDE=F1x)  
**com12_authorized_gate:** `E2R-ATOMIC-DGR-PROBE-00` only  
**JTAG:** `210319BE776EA` · **UART:** COM12 115200  
**XSim ≠ board.** One unknown. **C_FIX=NONE.** **BOARD_PASS not claimed.**

## Scientific frame (frozen before capture)

| Item | Declaration |
|------|-------------|
| OBSERVATION | UART-SKEW **SKEW** — printed `4` then `0` `0` is not same-cycle. Stub has no same-cycle `4,0,0`. |
| UNKNOWN | At first core-clock `dbg_tile_dst==D_WAITDONE(4) && wdma_owner`, what is ATOM0 and ATOM1 (next core cycle)? |
| H_CANDIDATE | ATOM0/1: `dst=4, grant=0, idle=0` (real leftover occupancy). |
| H_RIVAL | ATOM0: `dst=4, idle=1` (prior UART was skew; B1 may still work). |
| FALSIFIER | Serialize live TILE_DST/GRANT/IDLE as classification rows; force dest; C-FIX; A2. |
| UNIT | One query; first dest=4∧owner snapshot + exactly one later core cycle. |
| CONTROL | B-FIX sequential UART; UART-ENC FAITHFUL; UART-SKEW SKEW. |
| METRICS | ATOM hex, decode, class. Gate PASS = rows captured and decoded. Existence PASS remains `pred=664`. |

## Pack (32-bit hex, [31:11]=0)

[2:0] dest · [3] owner · [4] grant · [5] idle · [6] drain · [7] fifo_ne · [8] c_rvalid · [9] tr_nz · [10] mgo_sticky

## Class (exactly one)

`OCC_400` · `SKEW_IDLE1` · `GRANT_STUCK` · `NO_DST4` · `SET`

If OCC_400 and exactly one constituent: name the wire only. Do not apply a fix.
