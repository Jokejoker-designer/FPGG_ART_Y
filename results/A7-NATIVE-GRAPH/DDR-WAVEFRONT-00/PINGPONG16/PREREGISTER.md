# PREREGISTER — ddr_wavefront_00 (PINGPONG16 set)

> **Provenance disclosure — read first.** This document was originally written to
> `DDR-WAVEFRONT-00/PREREGISTER.md` **before any simulation run** of this set. A concurrent
> session (the authoritative set, per `STATUS/AUTHORITY_DDR_WAVEFRONT_ARTIFACTS.md`) wrote its
> own `PREREGISTER.md` to the same path at almost the same minute and its content won, so the
> original file object no longer exists on disk. The text below is re-materialised here
> unchanged in substance.
>
> Because a re-materialised file cannot prove its own timestamp, the preregistration of this set
> is independently evidenced by two artifacts that were fixed **before** the run:
>
> - `xsim_wavefront.log` opens with the `PREREG_GATE / PREREG_UNKNOWN / PREREG_H_CANDIDATE /
>   PREREG_H_RIVAL / PREREG_FALSIFIER / PREREG_CONTROL / PREREG_UNIT / PREREG_METRICS /
>   PREREG_NON_GATE / PREREG_LIMIT` lines, emitted by the testbench before the first query run.
> - `tests/xsim/tb_a7ng_wavefront_mig.sv` carries the same frame in its file header, and both the
>   log and the source are hashed in `SHA256.txt`.
>
> This set is **RETAINED, UNCITED** per the parent's authority ruling. It does not close the gate.

| Field | Value |
|-------|-------|
| Gate | `ddr_wavefront_00` |
| Agent | `a7-ng-memory-arch` |
| Authority | `results/A7-NATIVE-GRAPH/STATUS/AUTHORITY_MEMORY_DOCTRINE.md` (LOCKED) |
| Control evidence | `results/A7-NATIVE-GRAPH/MIG-METRIC-00/CLOSEOUT.md` (per-run deltas 1024 B / 64 bursts, 1024 B / 16 bursts, integrity CLEAN) |
| Evidence class | `MIG_XSIM` (Digilent AXI MIG + `ddr3_model`) — **not** BOARD |
| Spec | `BRAM_WORKING_MEMORY_SPEC.md` §3 / §9 / §10 / §11 / §32; `feedback.md` §9 / §10 / §21 |

---

## OBSERVATION

MIG-METRIC-00 established that per-run AXI deltas from the Digilent AXI MIG are trustworthy
(`metric_clear_i` per run; 1024 B / 64 bursts at burst=1, 1024 B / 16 bursts at burst=4;
`data_mismatch = rresp = rlast = 0`; records 64/64/64).

But the consumer measured there was a **round-robin single-record pull**: one 16 B record per
cycle handed to one arbitrated PE. That is the pattern `feedback.md` §7 / §11 explicitly warns
about ("do not connect 16 agents to a single-port memory and call the design parallel").
Nothing on file measures DDR delivery into a **simultaneous 16-lane wave**.

## THE ONE UNKNOWN

From correctly measured MIG, can a **bounded** candidate/cue working set feed 16 physical
lanes with **exactly measured** traffic?

Exactly one unknown. No memory-system redesign. No other gate is opened.

## H_CANDIDATE

A bounded ping/pong cue working set (2 banks × 16 records = 512 B, LUTRAM/FF, BRAM = 0)
sustains 16-lane waves into the **existing** 16-lane scorer and **existing** true global
Top-K with candidates conserved (no loss, no duplication), zero data mismatch at consumption,
and **all** DDR traffic accounted per-run.

## H_RIVAL

The bounded buffer either (a) starves the wave so the delivery path cannot sustain 16-lane
waves, or (b) loses / duplicates candidates, or (c) traffic can only be reported cumulatively
(per-run deltas do not close).

## FALSIFIER (any one fires ⇒ FAIL / not PASS)

| # | Falsifier |
|---|-----------|
| F1 | Invented GB/s or any bandwidth number not derived from counted AXI beats |
| F2 | Cumulative counters sold as per-run (run *n+1* row equals run *n* + run *n+1*) |
| F3 | Candidate loss hidden as "backpressure" (delivered ≠ accepted; any node_id missing or delivered twice) |
| F4 | `data_mismatch ≠ 0` at consumption against the deterministic preloaded pattern |
| F5 | Change to any MUST-NOT-CHANGE law (01R, HIT_MAX, TermGen, Top-K, relation law, LM06, 02M, training, encoder, learning, HNSW, NTDE, frozen bits, `mig.prj`) |
| F6 | COM12 program / any board program / any BOARD_PASS claim |
| F7 | Full-graph scan (HS-13) or host-generated addresses (HS-14) |

## CONTROL

MIG-METRIC-00 per-run delta cells, re-anchored by running the **same** `(burst, outstanding)`
points `(1,1)` and `(4,8)` at `TOTAL = 64`: expected `axi_read_bytes = 1024`, `bursts = 64` and
`16` respectively, `beats = 64`. If the wavefront delivery layer reproduces those control cells
byte-for-byte, the traffic accounting is anchored to already-audited evidence rather than to a
new claim.

Negative control for F2: runs execute back-to-back **without** `rst_n`; only `start_i` clears
per-run telemetry.

## UNIT

**One query run** (seed + candidate list + `(burst, outstanding)` + consumer pattern).
Not a clock cycle. Multiple seeds and multiple traffic/consumer patterns are used; a single long
single-pattern run would be pseudoreplication.

## PATH UNDER TEST (given, not invented)

```text
DDR -> sequential/burst compact cue fetch (FPGA-generated addresses, HS-14)
    -> bounded ping buffer A/B (2 x 16 records)
    -> 16-candidate wave (all 16 lanes in ONE cycle)
    -> a7ng_termgen_array  (existing, unchanged, law a7ng-termgen-v0)
    -> a7ng_ng02_core      (existing 16-lane a7ng_scorer_array
                            + existing true global Top-8 a7ng_topk, law a7ng-topk-global-v1
                            + existing a7ng_frontier_buckets)
```

New RTL is the **delivery / working-set layer only**:
`rtl/native_graph/memory/a7ng_cue_wavefront.sv` and
`rtl/native_graph/memory/a7ng_wavefront_mig_top.sv`.
`a7ng_ddr_feed_axi_bridge.sv` is reused **unmodified** (its SHA must MATCH MIG-METRIC-00).

## PREREGISTERED RUN MATRIX

| Run | seed | base_node | candidates | burst | outstanding | consumer pattern | role |
|-----|-----:|----------:|-----------:|------:|------------:|------------------|------|
| Q0 | 0 | 0 | 64 | 1 | 1 | ALWAYS | CONTROL cell (1,1) |
| Q1 | 0 | 0 | 64 | 4 | 8 | ALWAYS | CONTROL cell (4,8) |
| Q2 | 0 | 0 | 64 | 16 | 8 | ALWAYS | long-burst vs 16-record bank |
| Q3 | 1 | 64 | 64 | 4 | 8 | ALWAYS | second seed |
| Q4 | 1 | 64 | 64 | 16 | 8 | SPARSE (ready 1 of 4 cycles) | slow consumer ⇒ bounded-buffer backpressure |
| Q5 | 2 | 128 | 32 | 8 | 4 | BURSTY (8 ready / 24 idle) | third seed + third pattern |

Preload: nodes 0..159, deterministic `NodeRecordV1` pattern, written over the same AXI MIG.

## PREREGISTERED METRICS (file-backed, per-run deltas)

| Metric | Definition |
|--------|------------|
| `ddr_bytes_per_candidate` | `axi_read_bytes / candidates_delivered` |
| `ddr_bytes_per_query` | `axi_read_bytes` for this run only (cleared by `start_i`) |
| `beats_per_query` | `axi_read_beats` for this run only |
| `wavefront_fill_cycles` | accumulated cycles from first beat into an empty bank to that bank FULL; also reported per wave (`/ fill_episodes`) |
| `memory_wait_fraction` | `buffer_empty_stall / cons_ready_cycles` (primary); `buffer_empty_stall / query_cycles` (secondary) |
| `jobs_per_cycle_during_wave` | `candidates_delivered / query_cycles` |
| `candidate_conservation` | `accepted == delivered + queued + pruned + in_flight` every cycle (`conserve_err == 0`) **and** each expected node_id delivered exactly once (TB `seen[]`) **and** `pruned == 0` **and** consumer accepted every wave issued |
| `data_mismatch` | mismatches of the full 128-bit record vs the deterministic preloaded pattern, checked **at consumption** (per lane, per wave), plus the bridge's independent beat-level check |

Ping/pong telemetry also required: `swap_count`, `buffer_empty_stall`, `buffer_full_stall`.

### Preregistered expected values

```text
ddr_bytes_per_candidate  == 16          (exactly one 128-bit AXI beat per NodeRecordV1)
ddr_bytes_per_query      == 16 * candidates      (1024 B for 64; 512 B for 32)
beats_per_query          == candidates
axi_read_bursts          == ceil(candidates / burst)
Q0 == CONTROL(1,1): 1024 B / 64 bursts / 64 beats
Q1 == CONTROL(4,8): 1024 B / 16 bursts / 64 beats
conserve_err == 0, pruned == 0, data_mismatch == 0, rresp == 0, rlast == 0
consumer_loss == 0   (every wave issued is accepted by the existing scorer/Top-K core)
buffer_full_stall > 0 in at least one slow-consumer run (Q4 or Q5)
Top-8 sequence identical for Q0 == Q1 == Q2 and Q3 == Q4  (same seed, different traffic)
```

## EXPLICIT NON-GATE (declared before running)

- **PE utilization ≥ 80 % is NOT a hard gate here.** It is scheduler-local. It is reported as a
  diagnostic number only and is **not** tuned toward. The existing `a7ng_ng02_core` accepts one
  16-candidate batch, then spends ~10 further cycles on score → Top-8 → 8 frontier pushes, so a
  bursty PE duty cycle is the *expected* behaviour of the frozen consumer contract, not a defect
  of the DDR delivery path.
- `cache_hit_ratio` is declared **N/A = 0 by construction** for this path: each candidate cue is
  fetched exactly once by sequential compact fetch; there is no reuse cache in the path under
  test. It will be reported as `0.000 (no reuse cache in path)` and will not be presented as a
  measured cache result.

## KNOWN LIMIT declared in advance

The frozen `a7ng_ng02_core` input contract requires all 16 lane valids
(`input_hs = batch_ready_o && (&lane_valid_i)`). A partial final wave therefore cannot be
accepted without changing the Top-K / flow law, which is forbidden. Candidate counts are
consequently **quantized to WAVE = 16**. This is recorded as a LIMIT, not worked around.

## STOP RULE

After the metric table and CLOSEOUT are written: **STOP**. No other gate is opened, ticked, or
started. No `LOOP_STATE` status flip. Parent + auditors close the gate.
