# AUTHORITY — `mig_board_r2` (board gate on the FROZEN feed path)

**Created:** 2026-08-22 by `a7-ng-orchestrator`
**Status:** `READY_HELD` — dispatch only after `lm06_wm_00` returns (one-implementer law)
**Human decisions recorded:** COM12 authorized for this gate only; full 4x4 grid; wait for `lm06_wm_00`.

## Why this gate exists

`QUARANTINE_MIG_BOARD_PREMETRIC.md` invalidated the earlier silicon rows
(`(1,1) 0.923261`, `(4,8) 0.585366`) because they were captured with **cumulative** counters and a
backpressure-based DROP. This gate re-measures the same path with the repaired `metric_clear`
telemetry so the quarantine can be lifted with real silicon numbers.

## The one unknown

> Do the trusted per-run deltas reproduce **on silicon**, and what does the full
> burst x outstanding grid say?

The 4x4 grid is the **replication axis** of that single unknown — it is deliberately *not* a second
unknown. Measuring one cell would be pseudoreplication; measuring sixteen is the control for it.

## Frozen scope — REBUILD AND MEASURE ONLY

The feed/telemetry path is frozen at the MIG-METRIC-00 revision and must not be re-opened:

```text
a7ng_ddr_feed_axi_bridge.sv   D07A9742BD61E6D1DAC34F7017B6B817697A2C98CD4A825EFA54F77275F48454
a7ng_ddr_feed_pp.sv           (MIG-METRIC-00 revision)
mig.prj                       870FA6EEC23436FA8AD2A8772A80865016807CA37542C0C994E9E1E88152190D
```

Forbidden here: feed law, search law, 01R, HIT_MAX, TermGen, Top-K, relation law, LM-06, 02M,
training, encoder, HNSW, NTDE. If a rebuild appears to require a law change, **FAIL the gate** and
report — do not change the law to make the board run succeed.

## Grid

| axis | values |
|------|--------|
| burst | 1, 4, 8, 16 |
| outstanding | 1, 2, 4, 8 |

16 cells, `metric_clear` between every cell so each row is a **per-run delta**.

**Not included:** graph degree {4, 8, 16} (feedback §9 third axis) — that needs the graph path, not
the feed path. Remains future work.

## CONTROL

`results/A7-NATIVE-GRAPH/MIG-METRIC-00/CLOSEOUT.md` (Evidence_class `MIG_XSIM`):

| cell | bytes | bursts | beats |
|------|------:|-------:|------:|
| (1,1) | 1024 | 64 | 64 |
| (4,8) | 1024 | 16 | 64 |

These two cells are the direct XSim-vs-silicon comparison. A silicon/XSim divergence on them is a
finding to report, **not** a number to quietly prefer.

## Required per cell

Per-run deltas `axi_read_bytes`, `axi_read_bursts`, `axi_read_beats`; integrity
`data_mismatch_count`, `rresp_error_count`, `rlast_error_count`,
`expected|received|consumed_records`; diagnostics `rid_observed`, `r_backpressure_cycles`,
`stall_frac`.

`RVALID && !RREADY` is **R-channel backpressure**, never a DROP. Conservation authority is
record/data equality.

## Hard stops

- **No invented GB/s.** Report measured bytes, beats and cycles. A bandwidth figure must be derived
  in the open from those, with the clock stated, or omitted.
- **AI does not declare BOARD_PASS.** Evidence class is `BOARD_MIG`. Native V1 BOARD_PASS is the
  human's signature.
- `r2_rdb` may be latched **only** once per-run deltas are confirmed on silicon.
- Record the new bitstream SHA. Board evidence binds to that bit, and does not transfer to any later
  RTL revision (Masterplan V2 Correction 4).
- The old quarantined rows stay quarantined. This gate supersedes them; it does not retroactively
  validate them.

## Lifting the quarantine

The quarantine may be lifted only if this gate produces per-run silicon deltas with clean integrity
counters across the grid. Partial success = partial lift, recorded cell by cell.
