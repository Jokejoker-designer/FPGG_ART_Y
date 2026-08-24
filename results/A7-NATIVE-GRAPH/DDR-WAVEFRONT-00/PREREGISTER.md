# PREREGISTER — ddr_wavefront_00

**Gate:** `ddr_wavefront_00`
**Agent:** `a7-ng-memory-arch`
**Archive:** `results/A7-NATIVE-GRAPH/DDR-WAVEFRONT-00/`
**Evidence_class:** `MIG_XSIM_WAVEFRONT` (Digilent AXI MIG + `ddr3_model`) — **not BOARD**
**Written:** before any RTL edit, any simulation, any number.

## Session law acknowledged

- ONE unknown. `lm06_wm_00`, the BRAM ladder, `bram_owner_00`, `mig_sweep_full`, full integration **not opened**.
- No COM12 program. No `r2_rdb` latch. Simulation-class evidence only.
- No self-chaining to the next queue item. Ends with **STOP**.
- Frozen/forbidden and **not touched**: 01R law, HIT_MAX, TermGen law, Top-K law, relation law,
  LM-06, 02M, training/learning law, encoder, HNSW, NTDE, frozen bitstreams, `mig.prj`.
- The 16-lane scorer (`a7ng_scorer_array`), TermGen (`a7ng_termgen_array`) and true Top-K
  (`a7ng_topk`, law `a7ng-topk-global-v1`) are instantiated **unmodified, as black boxes**.

## OBSERVATION

1. `MIG-METRIC-00` (PASS, `MIG_XSIM`) established trustworthy **per-run delta** AXI telemetry via
   `metric_clear_i`: burst=1 → 1024 B / 64 bursts; burst=4 → 1024 B / 16 bursts; integrity clean;
   records 64/64/64.
2. In that same design `a7ng_ddr_feed_mig_top` grants **at most one PE per cycle** and `pe_data` is a
   single 128-bit service — measured `recs_per_cyc = 0.444`. That is `feedback.md` §5 exactly: a
   16-lane fabric fed by a one-job-per-cycle dispatcher.
3. `feedback.md` §9 predicts DDR, not LUT arithmetic, becomes the bottleneck once the scheduler is
   widened, and prescribes burst + ping/pong + multiple outstanding **before** adding PEs.
4. `BRAM_WORKING_MEMORY_SPEC.md` §11: 16 agents on one single-port memory is not parallel; required
   strategy is bank interleave + broadcast of read-only query context, with conflicts **measured**.
5. SPEC §32: a 16 B candidate record gives 256 candidates = 4 KiB, so a bounded 256-candidate class
   working set is affordable; the expensive things are candidate/frontier/prefetch buffers.

## THE ONE UNKNOWN

From correctly measured MIG, can a **bounded** candidate/cue working set feed **16 physical lanes**
with **exactly measured** traffic?

## Hypotheses

| Field | Statement |
|-------|-----------|
| **H_CANDIDATE** | A bounded ping/pong compact-cue working set (declared entry count, explicit ready/valid backpressure, no silent overwrite) sustains 16-wide candidate waves with conserved records and measured, explainable DDR traffic. |
| **H_RIVAL** | The wavefront only *appears* healthy because traffic is cumulative / unconserved, or the "16-wide wave" is really a ≤1 candidate/cycle service renamed. |

## FALSIFIER (any one fires ⇒ FAIL or PASS_NARROW, never PASS)

| # | Falsifier |
|---|-----------|
| F1 | Record or data non-conservation (`accepted != completed + queued + pruned + in_flight`, or any silent loss / silent overwrite). |
| F2 | Cumulative counters sold as per-run deltas (second and later patterns must not inherit pattern-1 bytes). |
| F3 | Inventing GB/s, or any bandwidth number not derived from measured bytes **and** measured cycles with the derivation shown. |
| F4 | Changing any frozen law (01R / HIT_MAX / TermGen / Top-K / relation / LM-06 / 02M / training / encoder), `mig.prj`, or a frozen bitstream. |
| F5 | Claiming board evidence, silicon bandwidth, BOARD_PASS, or programming COM12. |
| F6 | Declaring PE/lane utilization a pass criterion (it is an explicit non-gate here). |
| F7 | Emitting fewer than 16 candidates in a wave cycle while calling it a 16-wide wave (i.e. `jobs_per_emit_cycle < 16` for a full wave). |

## CONTROL

`MIG-METRIC-00` per-run deltas, re-measured in this gate with the wavefront attached:

| Control cell | expected bytes | expected bursts | expected beats |
|--------------|---------------:|----------------:|---------------:|
| burst=1, out=1 | 1024 | 64 | 64 |
| burst=4, out=8 | 1024 | 16 | 64 |

If the wavefront stage inflates or deflates these bytes/bursts, the delivery path is not
traffic-neutral and H_CANDIDATE is falsified on F2/F1.

Second CONTROL (negative): the one-PE-per-cycle service of `MIG-METRIC-00` measured
`recs_per_cyc = 0.444` — any claim of 16-wide service must beat that *per emit cycle* by construction
(16 records in one cycle), not by renaming.

## UNIT

**One query** (= one run of TOTAL=64 candidates over one traffic pattern). Never the clock cycle.
`>= 2` distinct traffic patterns are reported so a single pattern is not pseudoreplication.
Cycle counts appear only as denominators inside a query, never as the unit of replication.

## Preregistered METRICS (all per-run deltas; `metric_clear` semantics reused)

| Metric | Definition (fixed now, before measurement) |
|--------|--------------------------------------------|
| `ddr_bytes_per_candidate` | `axi_read_bytes / candidates_dispatched` |
| `ddr_bytes_per_query` | `axi_read_bytes` for the run (per-run delta) |
| `beats_per_query` | `axi_read_beats` for the run (per-run delta) |
| `wavefront_fill_cycles` | `fill_cycles_accum / waves`, where `fill_cycles_accum` = active cycles in which the 16-wide wave was incomplete |
| `memory_wait_fraction` | `mem_wait_cycles / active_cycles`, same numerator as above, different normalisation (stated explicitly, not two fake counters) |
| `jobs_per_cycle_during_wave` | `candidates_dispatched / active_cycles` (sustained), reported **together with** `jobs_per_emit_cycle = candidates_dispatched / emit_cycles` (width proof) |
| `candidate_conservation` | 1 only if **all** of E1..E5 below hold exactly |
| `data_mismatch` | RTL structural mismatch (bank map, per-bank id order) **plus** TB golden `node_id` + cue check on all 16 lanes at consumption, plus the AXI-beat golden check inherited from MIG-METRIC-00 |

### Conservation equalities (E1..E5)

```text
E1  in_flight_beats == expected_records - received_records == 0 at run end
E2  received_records == pp_consumed + pp_resident                (ping/pong stage)
E3  accepted == dispatched + resident + pruned                   (wave stage; pruned == 0 by construction)
E4  dispatched == scored                                          (16-lane scorer completions)
E5  dispatched == TOTAL == received_records                       (query closure)
```

`RVALID && !RREADY` is **backpressure**, counted as `r_backpressure_cycles`, and is **not** a drop.
Conservation authority is record/data equality only.

### Ping/pong telemetry (SPEC §10) — also preregistered

`swap_count`, `buffer_empty_stall`, `buffer_full_stall`, plus `bank_full_stall` (wave stage refuses a
write because a bank is full — proof of backpressure instead of silent overwrite) and
`max_resident` (measured peak working-set occupancy, the number `LM06-WM-00` needs).

## Architecture under test (prescribed; no memory-system redesign)

```text
DDR (Digilent AXI MIG, official mig.prj)
  -> sequential/burst compact cue fetch      [a7ng_ddr_feed_axi_bridge, unchanged]
  -> ping buffer A / B                        [a7ng_ddr_feed_pp, unchanged]
  -> bounded 16-bank compact-cue working set  [a7ng_cue_wave_stage, NEW]
  -> 16-candidate wave (one entry per bank, one cycle)
  -> existing 16-lane TermGen + scorer        [a7ng_termgen_array, a7ng_scorer_array, unchanged]
  -> existing true Top-8                      [a7ng_topk, unchanged]
```

**Bounded means, declared now:** `N_LANES = 16` banks x `ENTRIES_PER_BANK = 16` = **256 candidate
entries**, compact entry = `{node_id[31:0], cue[31:0]}` = 8 B → 2 KiB working set (SPEC §32 class),
fed by a 2 x 32 x 16 B = 1 KiB ping/pong. No unbounded growth. No silent overwrite: `in_ready_o`
deasserts and the fetch stalls. Bank map is deterministic: `bank = node_id[3:0]` (SPEC §11).

## Traffic patterns (preregistered, run in this order)

| # | burst | outstanding | downstream | purpose |
|---|------:|------------:|------------|---------|
| P1 | 1 | 1 | always ready | CONTROL row 1 (1024 B / 64 bursts) |
| P2 | 4 | 8 | always ready | CONTROL row 2 (1024 B / 16 bursts) |
| P3 | 4 | 8 | throttled 1-in-8 | backpressure: bytes must **not** change; no loss; bank_full_stall > 0 expected |
| P4 | 16 | 8 | always ready | distinct burst depth (1024 B / 4 bursts) — anti-pseudoreplication |

## Declared non-gates

- Lane/PE utilisation **is not a gate** here. `feedback.md` §5's `>= 80%` is a scheduler-local
  engineering target; it is reported as a diagnostic number only. Bursty lane work with a healthy,
  conserved, exactly measured DDR path satisfies this gate.
- No `GB/s` will be printed unless derived from measured bytes and measured `ui_clk` cycles with the
  arithmetic shown inline. If it cannot be derived honestly it is omitted.

## Known LIMITs declared in advance

- No cue cache / hotset is instantiated in this path, so `cache_hit_ratio` is expected to be **0** by
  construction: every candidate is a cold sequential DDR fetch. `ddr_bytes_per_candidate` measured
  here is therefore an **upper bound** (worst case), not a cached-steady-state number.
- Simulation-class only: no synthesis, no post-route LUTRAM/BRAM cost, no timing claim, no board.
- `TOTAL = 64` candidates/query (MIG sim wall-clock), same as the MIG-METRIC-00 control.
