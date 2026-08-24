# MIG_METRIC_ROW — per-run deltas + integrity (mig_metric_00)

**Evidence_class:** MIG_XSIM — **not BOARD**  
**Date:** 2026-08-22  
**Marker:** `A7NG_MIG_METRIC_XSIM_PASS`  
**Log:** `xsim_mig_metric.log`  
**xelab:** `-mt off -O0`

## Preregistered cells (UNIT = sweep cell, TOTAL=64)

| burst | out | stall_frac | recs_per_cyc | axi_read_bytes | axi_read_bursts | axi_read_beats | data_mm | rresp_err | rlast_err | exp | rcv | cons | rid_err | r_backpressure |
|------:|----:|-----------:|-------------:|---------------:|----------------:|---------------:|--------:|----------:|----------:|----:|----:|-----:|--------:|---------------:|
| 1 | 1 | 0.960445 | 0.039555 | **1024** | **64** | **64** | 0 | 0 | 0 | 64 | 64 | 64 | 0 | 0 |
| 4 | 8 | 0.555556 | 0.444444 | **1024** | **16** | **64** | 0 | 0 | 0 | 64 | 64 | 64 | 0 | 0 |

Conservation authority = record/data equality (not RVALID&&!RREADY).  
`pp_backpressure_ticks` legacy counter may still tick; reported as backpressure, **not** lost-data DROP.

## vs CONTROL (MIG-RIVAL cumulative)

| Cell | MIG-RIVAL ddr_rd_bytes / bursts | MIG-METRIC per-run bytes / bursts |
|------|--------------------------------:|----------------------------------:|
| (1,1) | 1024 / 64 | 1024 / 64 |
| (4,8) | **2048 / 80** (cumulative) | **1024 / 16** (delta) |

H_RIVAL (sell cumulative as per-cell) **FALSIFIED**.
