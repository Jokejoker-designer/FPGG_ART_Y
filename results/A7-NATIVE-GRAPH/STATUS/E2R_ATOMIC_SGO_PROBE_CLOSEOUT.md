# E2R-ATOMIC-SGO-PROBE-00 — STATUS seal

**Agent:** `a7-vivado-gate` [76866d70](76866d70-bded-4f08-b56e-4fd25c57b822)  
**Board archive:** `D:/Jetking_sem4/SEM_4/arty-a7-online-lm-board/results/A7-NATIVE-GRAPH/E2R-ATOMIC-SGO-PROBE-00/`  
**C_FIX:** NONE · **BOARD_PASS:** not claimed · **EXISTENCE:** NO (`pred=664` absent)

Gate PASS = ATOM rows decoded. Not existence PASS.

## Bit

SHA256 `832E55E26232B4F2A5D84199EB86AEA1C7EBEEFEF30E51842BC44D8BB16385D2`  
WNS 0.406 ns · TNS 0.000 ns · BRAM36 103  
JTAG `210319BE776EA` · COM12 armed first  
F1x `77116381…` not overwritten. Frozen LM-06 not overwritten.

unsafe_cdc=3 on requested 3-bit `dma_st` UI→core `sync_bits` (FINDING). Class bit is `sgo_sticky` (bit7), not dma_st.

## ATOM (same-trigger FACT)

| | ATOM0 `00001B9C` | ATOM1 `00001B9D` |
|--|--|--|
| dest | 4 | 5 |
| grant | 1 | 1 |
| idle | 0 | 0 |
| sgo_latch | **0** | 0 |
| sgo_sticky | **1** | 1 |
| own_ui | 1 | 1 |
| dma_st | **5 (R)** | 5 (R) |
| mgo | 1 | 1 |

**CLASS = SGO_HIT** (bit7). H_CANDIDATE `SGO_MISS` not supported.

Sequential UART `SGO=0` `DMA_ST=0` `OWN_UI=0` is CONTROL. UART `SGO` prints **latch** (0), not sticky (1).

## Next (not this gate)

`SDONE=0` `W_STALL` `PHASE=01` `pred` absent. SGO unknown **closed**. No C-FIX. No A2. No LiteScope.
