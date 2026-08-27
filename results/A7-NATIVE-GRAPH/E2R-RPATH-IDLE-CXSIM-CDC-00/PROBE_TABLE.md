# E2R-RPATH-IDLE-CXSIM-CDC-00 — probe table

Source: `probe_table.csv` (XSim 2026.1, UNIT at 8680 ns).  
Law: `r_path_idle = !r_drain_hold && fifo_cnt==0 && !m_axi_rvalid && tr_cnt==0`.  
CDC `m_axi_rvalid` is `m_rvalid_r`. CDC quiet = `m_rvalid_r=0 && m_r_hold=0 && r_empty=1 && m_r_pend=0 && s_ar_hold=0 && ar_m_st=IDLE`.  
`$time` stored as ps (timescale 1 ns / 1 ps); table below in ns.

| t (ns) | phase | drain | fifo | rvalid | tr | idle | dirty | m_rvalid_r | m_r_hold | r_empty | pend | arhold | armst | cdc_q | cons |
|--------|-------|-------|------|--------|----|------|-------|------------|----------|---------|------|--------|-------|-------|------|
| 3955 | RESET | 0 | 0 | 0 | 0 | **1** | 0 | 0 | 0 | **1** | 0 | 0 | 0 | **1** | 0 |
| 4200 | POST_CLEAR | 0 | 0 | 0 | 0 | **1** | 0 | 0 | 0 | 1 | 0 | 0 | 0 | **1** | 0 |
| 4360 | AR_ACCEPTED (same-edge NBA; exploratory) | 0 | 0 | 0 | 0 | 1 | 0 | 0 | 0 | 1 | 0 | 0 | 0 | 1 | 0 |
| 6120 | R_CONSUMED | 0 | 0 | 0 | 0 | 1 | 0 | 0 | 0 | 1 | 0 | 0 | 0 | 1 | 4 |
| **8680** | **UNIT_CDC_SOA_SETTLE** | **0** | **0** | **0** | **0** | **1** | **0** | **0** | **0** | **1** | **0** | **0** | **0** | **1** | **4** |
| 8681 | PHASE_C_CLEAN | 0 | 0 | 0 | 0 | 1 | 0 | 0 | 0 | 1 | 0 | 0 | 0 | 1 | 4 |
| 8682 | PHASE_C_FORCE_MRVALID_R | 0 | 0 | 1 | 0 | **0** | 1 | **1** | 0 | 1 | 0 | 0 | 0 | 0 | 4 |
| 8683 | PHASE_C_RESTORE | 0 | 0 | 0 | 0 | 1 | 0 | 0 | 0 | 1 | 0 | 0 | 0 | 1 | 4 |

Leave-one-dirty: not run — UNIT idle=1, dirty_count=0, CDC quiet.  
Phase C: forced `m_rvalid_r=1` holds idle=0 (CDC rvalid is in the idle law). That is CONTROL, not a leftover after complete.
