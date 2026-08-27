# E2R-RPATH-IDLE-CXSIM-INT-00 — probe table

Source: `probe_table.csv` (XSim 2026.1, UNIT at 1615 ns).  
Law: `r_path_idle = !r_drain_hold && fifo_cnt==0 && !m_axi_rvalid && tr_cnt==0`.  
TILE_DST: **absent** in this DUT (not faked as 4).

| t (ns) | phase | r_drain_hold | fifo_cnt | m_axi_rvalid | tr_cnt | r_path_idle | dirty | mc | mc_as | beats | del |
|--------|-------|--------------|----------|--------------|--------|-------------|-------|----|-------|-------|-----|
| 235 | RESET | 0 | 0 | 0 | 0 | **1** | 0 | 0 | 0 | 0 | 0 |
| 235 | OWNER_READY | 0 | 0 | 0 | 0 | **1** | 0 | 0 | 0 | 0 | 0 |
| 255 | POST_START_1 (own=OWN_CLEAR) | 0 | 0 | 0 | 0 | 1 | 0 | 0 | 0 | 0 | 0 |
| 265 | METRIC_CLEAR (NBA same-edge; exploratory) | 0 | 0 | 0 | 0 | 1 | 0 | 0 | 0 | 0 | 0 |
| 285 | RUNNING_RISE | 0 | 0 | 0 | 0 | 1 | 0 | 1 | 1 | 0 | 0 |
| 1455 | SOA_DONE | 0 | 0 | 0 | 0 | **1** | 0 | 1 | 1 | 52 | 64 |
| **1615** | **UNIT_SOA_DONE_SETTLE** | **0** | **0** | **0** | **0** | **1** | **0** | **1** | **1** | **52** | **64** |

Leave-one-dirty: not run — UNIT idle=1, dirty_count=0.  
`metric_clear` after start: **1** (H_RIVAL second-clear not observed).
