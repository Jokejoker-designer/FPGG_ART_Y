# MIG-METRIC-00 — measurement integrity preflight

**Gate:** `mig_metric_00`  
**Archive:** `results/A7-NATIVE-GRAPH/MIG-METRIC-00/`  
**Evidence_class:** `MIG_XSIM` only  
**Session override:** `DO_NOT_STOP` suspended — **STOP after CLOSEOUT**; do **not** auto-start `mig_board`.

## Hard constraints (human)

- Do **not** program COM12.
- Do **not** latch `r2_rdb` on board until per-run deltas exist.
- Do **not** modify: 01R, 02M, LM06 arithmetic law, encoder, TermGen, Top-K, learning, HNSW, NTDE.

## Observations (to reproduce)

1. `a7ng_ddr_feed_axi_bridge` telemetry resets only on `rst_n`.
2. TB runs `run_cell(1,1)` then `run_cell(4,8)` without bridge reset → second row cumulative.
3. Cumulative second row: 2048 B / 80 bursts; **per-cell delta** = 1024 B / 16 bursts.
4. `a7ng_ddr_feed_mig_top` grants at most one PE/cycle; single internal pe service.
5. `pe_data` is not a 16-lane output.
6. TB does not validate NodeRecord content.
7. `m_axi_rresp` not checked.
8. RID exposed but ignored by `ddr_feed_pp`.
9. `DROP` on `RVALID&&!RREADY` is AXI backpressure, not lost data.

## Required metrics

**Per-run delta:** `axi_read_bytes`, `axi_read_bursts`, `axi_read_beats`  
**Integrity:** `data_mismatch_count`, `rresp_error_count`, `rlast_error_count`, `expected_records`, `received_records`, `consumed_records`  
**Diagnostic:** `rid_observed`, `rid_order_error` (if contract asserted), `r_backpressure_cycles`

## N=64 expectations

| Cell | expected bytes | expected bursts |
|------|----------------:|----------------:|
| burst=1 | 1024 | 64 |
| burst=4 | 1024 | 16 |

Preload NodeRecordV1 with deterministic `node_id`; verify at consumption.

Authority for conservation: **record/data equality**, not `RVALID&&!RREADY` DROP.
