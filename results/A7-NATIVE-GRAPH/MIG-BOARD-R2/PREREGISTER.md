# PREREGISTER — mig_board_r2

**Gate:** `mig_board_r2`  
**Agent:** `a7-ng-memory-arch`  
**Evidence_class:** `BOARD_MIG` (not Native V1 BOARD_PASS)  
**Date:** 2026-08-22

## Scientific frame

| Field | Value |
|-------|-------|
| OBSERVATION | MIG-METRIC-00 XSim per-run deltas trusted; prior BOARD rows quarantined (cumulative counters) |
| UNKNOWN | Do trusted per-run deltas reproduce on silicon, and what does the full burst × outstanding grid say? |
| H_CANDIDATE | 16-cell silicon grid with metric_clear per cell; integrity clean; CONTROL (1,1)/(4,8) match XSim bytes/bursts/beats |
| H_RIVAL | XSim sold as board; cumulative counters; RVALID&&!RREADY as DROP; invent GB/s |
| FALSIFIER | feed/search law change; hand-edit mig.prj; frozen bit overwrite; BOARD_PASS claim |
| UNIT | sweep cell (burst × outstanding), TOTAL=64 per cell |
| CONTROL | `MIG-METRIC-00/CLOSEOUT.md`: (1,1)=1024/64/64; (4,8)=1024/16/64 |
| METRICS | axi_read_{bytes,bursts,beats}; data/rresp/rlast; exp/rcv/cons; rid; r_backpressure; stall_frac |

## Frozen scope

```text
a7ng_ddr_feed_axi_bridge.sv   D07A9742BD61E6D1DAC34F7017B6B817697A2C98CD4A825EFA54F77275F48454
mig.prj                         870FA6EEC23436FA8AD2A8772A80865016807CA37542C0C994E9E1E88152190D
```

## Grid (16 cells, metric_clear between every cell)

| burst | outstanding |
|-------|-------------|
| 1, 4, 8, 16 | 1, 2, 4, 8 |

## UART format

`BOARD_MIG_R2_ROW,b,o,axi_bytes,axi_bursts,axi_beats,data_mm,rresp,rlast,exp,rcv,cons,rid,r_bp,pe_st,pe_bs,cyc`  
Marker: `A7NG_MIG_BOARD_R2_OK`

## Falsifiers

| Falsifier | Expected |
|-----------|----------|
| Invent GB/s | REFUSE — report integers + derived stall_frac only |
| Feed law change | FAIL gate |
| COM12 outside this gate | REFUSE |
| Latch r2_rdb before deltas confirmed | REFUSE |
| AI BOARD_PASS | REFUSE |
