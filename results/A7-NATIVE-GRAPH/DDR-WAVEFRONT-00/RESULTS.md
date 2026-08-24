# RESULTS — ddr_wavefront_00 (per-run deltas, 4 traffic patterns)

**Evidence_class:** `MIG_XSIM_WAVEFRONT` (Digilent AXI MIG + `ddr3_model`) — **not BOARD**
**Raw log:** `xsim_ddr_wavefront.log` (`A7NG_DDR_WAVEFRONT_XSIM_PASS`, line 5498)
**Preflight (not gate evidence):** `xsim_preflight_synth_axi.log` (`SYNTH_AXI_PREFLIGHT`)
**UNIT:** one query = 64 candidates. Four distinct traffic patterns → not pseudoreplication.
**Bound declared before measurement:** 16 banks × 16 entries = **256** candidate entries (compact 8 B entry).

## 1. Traffic — per-run deltas vs the MIG-METRIC-00 CONTROL

| P | burst | outstanding | downstream | axi_read_bytes | axi_read_bursts | axi_read_beats | CONTROL (MIG-METRIC-00) | match |
|---|------:|------------:|------------|---------------:|----------------:|---------------:|--------------------------|-------|
| P1 | 1 | 1 | ready | **1024** | **64** | 64 | 1024 B / 64 bursts | **exact** |
| P2 | 4 | 8 | ready | **1024** | **16** | 64 | 1024 B / 16 bursts | **exact** |
| P3 | 4 | 8 | 1-in-8 throttle | **1024** | **16** | 64 | (no control cell) | traffic-neutral under backpressure |
| P4 | 16 | 8 | ready | **1024** | **4** | 64 | (no control cell) | 64 beats / 4 bursts = 16 beats/burst |

Attaching the wavefront changed the DDR traffic by **zero bytes and zero bursts** against the
MIG-METRIC-00 control. Every pattern re-reads exactly the 64 records once: no re-fetch, no
inflation, no cumulative carry-over between patterns.

## 2. Preregistered metrics

| Metric | P1 (1,1) | P2 (4,8) | P3 (4,8,thr) | P4 (16,8) |
|--------|---------:|---------:|-------------:|----------:|
| `ddr_bytes_per_query` | 1024 | 1024 | 1024 | 1024 |
| `ddr_bytes_per_candidate` | 16.0000 | 16.0000 | 16.0000 | 16.0000 |
| `beats_per_query` | 64 | 64 | 64 | 64 |
| `wavefront_fill_cycles` (per wave) | 401.25 | 35.25 | 30.75 | 35.00 |
| `memory_wait_fraction` | 0.997514 | 0.972414 | 0.814570 | 0.972222 |
| `jobs_per_cycle_during_wave` (sustained) | 0.039776 | 0.441379 | 0.423841 | 0.444444 |
| `jobs_per_emit_cycle` (width proof) | **16.0000** | **16.0000** | **16.0000** | **16.0000** |
| `candidate_conservation` | **1** | **1** | **1** | **1** |
| `data_mismatch` | **0** | **0** | **0** | **0** |
| active_cycles | 1609 | 145 | 151 | 144 |
| waves / full waves / partial waves | 4 / 4 / 0 | 4 / 4 / 0 | 4 / 4 / 0 | 4 / 4 / 0 |
| min observed wave width | 16 | 16 | 16 | 16 |

`ddr_bytes_per_candidate = 16.0000` is exactly one NodeRecordV1 per candidate — the record is read
once and reaches a lane once.

## 3. Conservation ledger (all four patterns)

| Equality | P1 | P2 | P3 | P4 |
|----------|---:|---:|---:|---:|
| E1 `in_flight == 0` at end | 1 | 1 | 1 | 1 |
| E2 `received == pp_consumed + pp_resident` | 1 | 1 | 1 | 1 |
| E3 `accepted == dispatched + resident + pruned` | 1 | 1 | 1 | 1 |
| E4 `dispatched == scored` (16 lanes) | 1 | 1 | 1 | 1 |
| E5 `dispatched == received == 64` | 1 | 1 | 1 | 1 |

Raw counters, identical in all four patterns:
`exp_beats=64 rcv_beats=64 in_flight=0 pp_consumed=64 pp_resident=0 accepted=64 dispatched=64
resident=0 pruned=0 scored=64`.

`data_mismatch` is the sum of four independent checks, all zero in all patterns:

| Check | Where | Result |
|-------|-------|--------|
| AXI beat vs golden NodeRecordV1 pack | bridge (inherited from MIG-METRIC-00) | 0 |
| bank-map identity (`emitted node_id[3:0] == bank`) | wave stage | 0 |
| per-bank strictly increasing `node_id` | wave stage | 0 |
| TB golden `node_id` **and** `cue` on **all 16 lanes** at consumption | testbench | 0 |

AXI integrity: `rresp=0 rlast=0 rid_assoc=0 r_backpressure_cycles=0` in all patterns.

## 4. Ping/pong + bounded-buffer telemetry (SPEC §10 / §11)

| Metric | P1 | P2 | P3 | P4 |
|--------|---:|---:|---:|---:|
| `swap_count` | 64 | 2 | 2 | 2 |
| `buffer_empty_stall` | 1544 | 80 | 80 | 79 |
| `buffer_full_stall` | 0 | 0 | 0 | 0 |
| `bank_full_stall` | 0 | 0 | 0 | 0 |
| `max_resident` (measured peak) | 16 | 16 | **22** | 16 |
| declared bound | 256 | 256 | 256 | 256 |
| `sink_wait_cycles` | 0 | 0 | **24** | 0 |
| bank conflicts | 0 by construction (one entry per bank per wave) | | | |

`swap_count = 64` at burst=1 (the ping/pong thrashes: the consumer drains a bank as fast as DDR
fills it) versus `2` at burst ≥ 4. `buffer_empty_stall` is the wave stage asking for a record that
the ping/pong does not yet have — 1544 of 1609 cycles at burst=1.

**Backpressure was exercised but never saturated:** the throttled pattern P3 produced 24
`sink_wait_cycles` and pushed peak occupancy from 16 to 22 entries, yet `bank_full_stall` and
`buffer_full_stall` stayed at 0. The bounded buffer was never filled, so "no silent overwrite" is
verified here as **headroom**, not as measured saturation behaviour. See CLOSEOUT LIMIT L2.

## 5. Diagnostics (explicit NON-GATES)

| Diagnostic | P1 | P2 | P3 | P4 |
|-----------|---:|---:|---:|---:|
| `lane_busy_cycles` | 4 | 4 | 4 | 4 |
| lane utilisation | 0.002486 | 0.027586 | 0.026490 | 0.027778 |
| `topk_batches` | 4 | 4 | 4 | 4 |
| Top-1 of final wave (`id` / `score`) | 57 / 165 | 57 / 165 | 57 / 165 | 57 / 165 |
| `cache_hit_ratio` | 0.000000 | 0.000000 | 0.000000 | 0.000000 |

Lane utilisation is reported **only** as a diagnostic: `feedback.md` §5's ≥80% target is
scheduler-local and is not a criterion for this gate. Each wave keeps the 16 lanes busy for exactly
one cycle, so `lane_busy_cycles == waves == 4`.

`cache_hit_ratio = 0` is by construction — no cue cache or hotset exists in this path, so every
candidate is a cold sequential DDR fetch and `16 B/candidate` is a **worst-case upper bound**.

The final wave's true Top-8 winner is **identical (id=57, score=165) across all four traffic
patterns**, i.e. burst depth, outstanding depth and downstream throttling did not perturb the scored
result. Top-K itself was used as an unmodified black box and is not re-verified here (that is
NG-02R's gate).

## 6. Rate — derived, not invented

Reported only as measured-bytes ÷ measured-cycles × measured clock period; `ui_clk` period was
measured in-simulation over 100 edges as **12000.00 ps** (83.33 MHz).

| P | bytes | active_cycles | B/cycle | × (1e6 / 12000.00 ps) | MB/s |
|---|------:|--------------:|--------:|----------------------|-----:|
| P1 | 1024 | 1609 | 0.636420 | — | 53.04 |
| P2 | 1024 | 145 | 7.062069 | — | 588.51 |
| P3 | 1024 | 151 | 6.781457 | — | 565.12 |
| P4 | 1024 | 144 | 7.111111 | — | 592.59 |

**This is an XSim `ui_clk`-derived figure for a 64-record query, not silicon bandwidth and not a
board number.** It is included only because every term in it was measured in this run.

## 7. Falsifier audit

| # | Falsifier | Fired? | Evidence |
|---|-----------|--------|----------|
| F1 | record/data non-conservation | **No** | E1–E5 = 1 in 4/4 patterns; `data_mismatch = 0` on four independent checks |
| F2 | cumulative counters sold as per-run | **No** | every pattern re-reads 1024 B; P2/P3/P4 do not inherit P1's bytes (`metric_clear` on start) |
| F3 | invented GB/s | **No** | §6 shows bytes, cycles and a measured clock period; labelled non-silicon |
| F4 | frozen law change | **No** | `FROZEN_VERIFY.md`: `ddr_feed_pp`, `axi_bridge`, `mig.prj` byte-identical to MIG-METRIC-00 |
| F5 | board claim / COM12 | **No** | simulation only; no programming; no `r2_rdb` latch |
| F6 | PE utilisation declared a pass | **No** | reported as diagnostic; lane util 0.0025–0.028 and the gate still stands on the DDR path |
| F7 | wave narrower than 16 while claimed 16-wide | **No** | `jobs_per_emit_cycle = 16.0000`, 4/4 full waves, `min_wave_width = 16`, per-lane golden data verified |
