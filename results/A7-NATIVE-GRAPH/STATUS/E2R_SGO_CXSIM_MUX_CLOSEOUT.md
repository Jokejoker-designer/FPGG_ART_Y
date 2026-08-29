# E2R-SGO-CXSIM-MUX-00 — STATUS seal

**Agent:** `a7-ng-xsim-verify` [76bb5b50](76bb5b50-de16-4275-9f9d-da93165f9e91)  
**Archive:** `D:/Jetking_sem4/SEM_4/arty-a7-online-lm-board/results/A7-NATIVE-GRAPH/E2R-SGO-CXSIM-MUX-00/`  
**XSIM:** PASS · CLASS=**SGO_ROSE** · C_FIX=NONE  
**Log SHA:** `68B3280522FAEB1FBA67E89E96C17BC608AB0D7337B8752216420F09ADA3E189`

## FACT (this vehicle, n=1)

First dest=4: grant=1 idle=0 fifo=4 c_rvalid=1.  
`dbg_s_go_sticky`=1 at dest=4 and at end. `s_go` ever=1. Live `s_go` at snap=0 (pulse gone).  
`cmd_st=2` `cmd_rd_sticky=1` `m_go_sticky=1`.

H_CANDIDATE `SGO_NEVER` **falsified on mux+stub**.  
XSim ≠ board. Stub ≠ MIG.

## Do not treat as GRANT-skew

SoC UART `SGO` is `dbg_s_go_sticky` **latched while `core_busy_ui`**, not the live pulse.  
If silicon sticky rose and stayed 1, the printed `SGO` row should be 1.  
Silicon sequential `SGO=0` is therefore **not** explained by “pulse already consumed.”  
`SGO_ROSE` here does **not** prove silicon `s_go` rose. It shows the stub vehicle can issue `s_go` on ATOM-like leftover.

## Still blocked

EXISTENCE=NO (`pred=664` absent). No COM12 for a new bit. No C-FIX. No A2. No LiteScope.
