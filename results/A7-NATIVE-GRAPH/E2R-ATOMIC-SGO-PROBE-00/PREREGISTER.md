# E2R-ATOMIC-SGO-PROBE-00 — PREREGISTER (before UART)

**Agent:** `a7-vivado-gate`  
**Workspace:** `D:/Jetking_sem4/SEM_4/arty-a7-online-lm-board`  
**Authority:** `STATUS/E2R_ATOMIC_SGO_PROBE_DISPATCH.md`  
**com12_authorized_gate:** `E2R-ATOMIC-SGO-PROBE-00` only  
**JTAG:** `210319BE776EA` · **UART:** COM12 115200  
**XSim ≠ board.** One unknown. **C_FIX=NONE.** **BOARD_PASS not claimed.**

Do **not** reprogram F1x bit `771163814B6914CECB872839A36BD95ED0249E839038E16C46D48755E66C48EA`.

## Scientific frame (frozen before capture)

| Item | Declaration |
|------|-------------|
| OBSERVATION | F1x ATOM dest=4 grant=1 leftover SET. Stub SGO_ROSE + LATCH_HIT. Silicon sequential SGO=0 DMA_ST=0 OWN_UI=0. UART SGO is sticky-latched while core_busy_ui. Not GRANT-skew. |
| UNKNOWN | At first core dest=4 && wdma_owner, packed SGO latch/sticky, OWN_UI, DMA_ST (synced to core)? |
| H_CANDIDATE | SGO_MISS (dest=4 grant=1, SGO bits 0) |
| H_RIVAL | SGO_HIT (dest=4 and latch or sticky =1) |
| FALSIFIER | sequential SGO row as class; force dest; C-FIX; A2; LiteScope; unsynced UI bits |
| UNIT | first dest=4∧owner + next core cycle |
| CONTROL | ATOM0=0000059C; SGO-MUX SGO_ROSE; LATCH_HIT SHA 74433CAE…; sequential SGO=0 |
| METRICS | ATOM hex, class. Gate PASS = rows decoded. Existence = pred=664 only. |

## Pack (32-bit hex, [31:13]=0)

[2:0] dest · [3] owner · [4] grant · [5] idle  
[6] latched_sgo_f1u synced to core · [7] dbg_s_go_sticky synced to core  
[8] wdma_owner_ui synced to core · [11:9] dma_st synced to core · [12] mgo_sticky

## Class (exactly one, first match)

`NO_DST4` · `SGO_HIT` · `OWN_UI0` · `SGO_MISS` · `SET`

Do not use live sequential `SGO=` as the classification row.
