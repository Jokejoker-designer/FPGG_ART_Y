# MIG_SWEEP_ROW — Digilent AXI MIG XSim (repair mig_h_rival)

**Evidence_class:** MIG_XSIM (ddr3_model + Digilent `mig_7series_0_mig_sim`) — **not BOARD**, **not HS-02**  
**Date:** 2026-08-22  
**Law id:** `a7ng-mig-rival-v0`  
**Marker:** `A7NG_MIG_RIVAL_XSIM_PASS`  
**Log:** `xsim_mig_rival.log`  
**xelab fix:** `-mt off -O0` (default xelab → `EXCEPTION_ACCESS_VIOLATION`; see `xelab_repair_O0.log`)

## Preregistered cells (UNIT = sweep cell)

| burst | out | stall_frac | recs_per_cyc | pe_stall | pe_busy | cycles | cons | drop | ddr_rd_bytes | ddr_bursts |
|------:|----:|-----------:|-------------:|---------:|--------:|-------:|-----:|-----:|-------------:|-----------:|
| 1 | 1 | 0.958710 | 0.041290 | 1486 | 64 | 1550 | 64 | 0 | 1024 | 64 |
| 4 | 8 | 0.549296 | 0.450704 | 78 | 64 | 142 | 64 | 0 | 2048 | 80 |

TOTAL=64 (reduced vs synthetic 256). N_PE=16. DROP=0 both cells.

## vs CONTROL (synthetic LAT=24)

| Cell | Synthetic stall | MIG XSim stall | Delta (MIG−syn) |
|------|----------------:|---------------:|----------------:|
| (1,1) | 0.961544 | 0.958710 | −0.002834 |
| (4,8) | 0.475410 | 0.549296 | +0.073886 |

Direction of stall cut with burst/outstanding is **supported**. Synthetic best-case underestimates residual stall vs Digilent MIG+ddr3_model at TOTAL=64.

## H_RIVAL

Prior rival ("synthetic LAT=24 is the only stall evidence") is **FALSIFIED** — Digilent AXI MIG_SWEEP_ROW now archived.  
Not BOARD_PASS. Not silicon PE stall.
