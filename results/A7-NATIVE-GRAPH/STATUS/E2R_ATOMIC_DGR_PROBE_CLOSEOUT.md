# E2R-ATOMIC-DGR-PROBE-00 — STATUS seal (main tree)

**Agent:** `a7-vivado-gate` [0b16e00b](0b16e00b-104f-4953-ba7e-d01bf0dc007c)  
**Board archive:** `D:/Jetking_sem4/SEM_4/arty-a7-online-lm-board/results/A7-NATIVE-GRAPH/E2R-ATOMIC-DGR-PROBE-00/`  
**Primary closeout:** that archive `CLOSEOUT.md`  
**C_FIX:** NONE  
**BOARD_PASS:** not claimed  
**EXISTENCE:** NO (`pred=664` absent)  
**LiteScope/ILA:** not used (L3; bit has no analyzer core)

Gate PASS = ATOM rows captured and decoded. Not existence PASS.

## Bit

SHA256 `771163814B6914CECB872839A36BD95ED0249E839038E16C46D48755E66C48EA`  
WNS 0.265 ns · TNS 0.000 ns · BRAM36 103 · unsafe_cdc 0  
JTAG `210319BE776EA` · COM12 armed first

## ATOM (same-cycle FACT)

| | ATOM0 `0000059C` | ATOM1 `0000059D` |
|--|--|--|
| dest | 4 | 5 |
| owner | 1 | 1 |
| grant | **1** | **1** |
| idle | 0 | 0 |
| drain | 0 | 0 |
| fifo_ne | 1 | 1 |
| c_rvalid | 1 | 1 |
| tr_nz | 0 | 0 |
| mgo | 1 | 1 |

**CLASS = SET** (`fifo_ne` + `c_rvalid`). No single idle wire named.

## Sequential UART (CONTROL, not class)

Same capture still prints `TILE_DST=4` then `WDMA_GRANT=0` `RPATH_IDLE=0` `SGO=0` `DMA_ST=0`. That GRANT=0 vs ATOM grant=1 is UART-SKEW. Sequential `SGO=0` is **not** same-cycle FACT.

## Hypothesis (this unit)

| H | Status |
|---|--------|
| H_CANDIDATE dest=4 grant=0 idle=0 | **not supported** (grant=1) |
| H_RIVAL dest=4 idle=1 | **falsified** (idle=0) |

n=1 query. Descriptive. No C-FIX. No A2. No B1 bypass.
