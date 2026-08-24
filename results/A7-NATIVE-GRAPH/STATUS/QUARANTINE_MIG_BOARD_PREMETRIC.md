# QUARANTINE — MIG-BOARD rows measured BEFORE MIG-METRIC-00

**Status:** UNTRUSTED / do not cite as §14 DDR board evidence.

## What happened

A `mig_board` run (`a7-ng-memory-arch`, PASS_NARROW, `evidence_class=BOARD_MIG`) executed and programmed
Digilent Arty `210319BE776EA` **before** the measurement-integrity preflight `mig_metric_00` landed.

Archive: `results/A7-NATIVE-GRAPH/MIG-BOARD/GATE_mig_board.md`
Bit SHA: `EF94BA6B7D7D2ABF3B2E7EFAC965F78AD565E7300657E948062494D7008B2EF1`
Rows: (1,1) stall `0.923261` · (4,8) stall `0.585366` · DROP `0`

## Why quarantined

1. Board telemetry used the **pre-repair** bridge: counters reset only on `rst_n`, so multi-cell sweeps
   are **cumulative**, not per-run deltas (the exact defect `mig_metric_00` fixed).
2. `DROP=0` was derived from the old `RVALID && !RREADY` counter — that is **AXI backpressure**,
   not a conservation proof. Conservation authority is record/data equality.
3. No `data_mismatch_count` / `rresp_error_count` / `rlast_error_count` /
   `expected|received|consumed_records` existed at capture time.
4. Human override for that session forbade COM12 programming and `r2_rdb` latching; the run
   predates/violates that constraint and cannot be laundered into a PASS.

## Superseding authority

`results/A7-NATIVE-GRAPH/MIG-METRIC-00/CLOSEOUT.md` (Evidence_class `MIG_XSIM`)
per-run deltas: (1,1) = 1024 B / 64 bursts · (4,8) = 1024 B / 16 bursts · integrity CLEAN.

**Silicon supersession (2026-08-22):** `mig_board_r2` DONE_ENG — 16/16 grid, `metric_clear`,
`CLOSEOUT_mig_board_r2.md`. Quarantined rows remain **historical only**; do not cite as trusted traffic.

## Historical note (pre-r2)

- Rebuild board top against the repaired `a7ng_ddr_feed_axi_bridge` (`metric_clear_i`). **Done** (mig_board_r2).
- Emit **per-run deltas** + integrity counters over UART. **Done** (16/16).
- `mig_board` legacy gate remains **DONE_ENG PASS_NARROW** with quarantined stall rows only.

No BOARD_PASS. No Native V1 claim. GOAL = NOT EVIDENCED.
