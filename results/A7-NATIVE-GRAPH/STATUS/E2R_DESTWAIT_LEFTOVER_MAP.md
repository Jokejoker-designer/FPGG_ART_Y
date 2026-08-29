# Dest-wait leftover map — after ATOMIC-SGO

## Law (unchanged)

`r_path_idle = !r_drain_hold && fifo_cnt==0 && !m_axi_rvalid && tr_cnt==0`  
B1: grant rises only when `wdma_owner && r_path_idle`; then holds while owner=1.

## FACT (board ATOM)

| Trigger dest=4∧owner | F1x DGR | ATOMIC-SGO |
|----------------------|---------|------------|
| grant | 1 | 1 |
| idle | 0 | 0 |
| leftover | fifo_ne + c_rvalid | (same occupancy class) |
| sgo_sticky | — | **1** |
| sgo_latch | — | 0 |
| own_ui | — | 1 |
| dma_st | — | 5 (R), reported; 3 unsafe CDC |

Sequential `GRANT=0` `SGO=0` `DMA_ST=0` `OWN_UI=0` is print/latch CONTROL.

## Open

`SDONE=0` `W_STALL` `PHASE=01` `pred` absent. C-FIX not licensed.
