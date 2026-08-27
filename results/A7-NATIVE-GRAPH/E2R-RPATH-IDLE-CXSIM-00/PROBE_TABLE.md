# E2R-RPATH-IDLE-CXSIM-00 — probe table

Source: `probe_table.csv` (XSim 2026.1, `$finish` at 524 ns).  
Law: `r_path_idle = !r_drain_hold && fifo_cnt==0 && !m_axi_rvalid && tr_cnt==0`.

| t (ns) | phase | r_drain_hold | fifo_cnt | m_axi_rvalid | tr_cnt | r_path_idle | dirty_count |
|--------|-------|--------------|----------|--------------|--------|-------------|-------------|
| 115 | RESET | 0 | 0 | 0 | 0 | **1** | 0 |
| 155 | POST_CLEAR_WAIT | 0 | 0 | 0 | 0 | **1** | 0 |
| 175 | AR_ACCEPTED | 0 | 0 | 0 | 0 | 1 | 0 |
| 255 | R_RETURNED (in-flight, not UNIT) | 0 | 1 | 1 | 1 | 0 | 3 |
| 415 | **PHASE_A_SOA_COMPLETE (UNIT)** | **0** | **0** | **0** | **0** | **1** | **0** |
| 515 | **PHASE_B_METRIC_CLEAR_AFTER** | **0** | **0** | **0** | **0** | **1** | **0** |
| 516 | PHASE_C_CLEAN | 0 | 0 | 0 | 0 | 1 | 0 |
| 517 | PHASE_C_FORCE_DRAIN | 1 | 0 | 0 | 0 | 0 | 1 |
| 519 | PHASE_C_FORCE_FIFO | 0 | 1 | 0 | 0 | 0 | 1 |
| 521 | PHASE_C_FORCE_RVALID | 0 | 0 | 1 | 0 | 0 | 1 |
| 523 | PHASE_C_FORCE_TR | 0 | 0 | 0 | 1 | 0 | 1 |
| 524 | PHASE_C_RESTORE | 0 | 0 | 0 | 0 | 1 | 0 |

Leave-one-dirty (Phase A / B): not run — idle=1, dirty_count=0.  
Phase C law check: 4/4 forced-dirty wires hold idle=0; restore returns idle=1.
