# CLOSEOUT — ddr_wavefront_00 (PINGPONG16 set — RETAINED, UNCITED)

**Gate status contributed by this set:** **NONE.** This set does **not** close `ddr_wavefront_00`.
**Internal verdict of this set:** PASS_NARROW (all 6 runs passed; see tables below)
**Evidence_class:** `MIG_XSIM` (Digilent AXI MIG + `ddr3_model`) — **not BOARD**
**Agent:** `a7-ng-memory-arch`
**Marker:** `A7NG_DDR_WAVEFRONT00_XSIM_PASS` (`xsim_wavefront.log`)
**Artifact:** `results/A7-NATIVE-GRAPH/DDR-WAVEFRONT-00/PINGPONG16/`
**Preregistration:** `PINGPONG16/PREREGISTER.md` (re-materialised — read its provenance header)

> **Authority compliance.** `results/A7-NATIVE-GRAPH/STATUS/AUTHORITY_DDR_WAVEFRONT_ARTIFACTS.md`
> (parent, 2026-08-22) records that two implementer-class runs wrote into `DDR-WAVEFRONT-00/`
> concurrently — an orchestrator duplicate-dispatch error — and rules that the **authoritative**
> set is the one with testbench top `tb_a7ng_ddr_wavefront` / marker
> `A7NG_DDR_WAVEFRONT_XSIM_PASS`, while this set (`tb_a7ng_wavefront_mig`) is
> **RETAINED, UNCITED**.
>
> This closeout complies. No PASS, metric or §14 claim for the gate rests on this set. It is an
> **independent cross-check** only. Accordingly, the `DISPATCH_LOG.jsonl` line appended by this
> session is `result: "CROSS_CHECK_UNCITED"`, **not** a PASS — writing a second PASS line for one
> gate would contradict the ruling and overclaim.
>
> Two disclosures about file collisions, stated rather than hidden:
>
> 1. **This session's `PREREGISTER.md` was overwritten, not the other way round.** Top-level
>    `DDR-WAVEFRONT-00/PREREGISTER.md` now holds the *authoritative* set's text (it references
>    `a7ng_cue_wave_stage`). This session's original preregistration file object is gone; it is
>    re-materialised at `PINGPONG16/PREREGISTER.md`, whose header explains that its pre-run status
>    is independently evidenced by the `PREREG_*` lines at the head of `xsim_wavefront.log` and by
>    the header of `tests/xsim/tb_a7ng_wavefront_mig.sv`, both hashed in `SHA256.txt`.
> 2. Top-level `frozen_sha_verify.txt` was written by this session and is listed as
>    non-authoritative by the ruling. It is left in place (the ruling says RETAINED, not deleted)
>    and is also copied into `PINGPONG16/`. All other files of this set were moved under
>    `PINGPONG16/` and the transient `syncheck/` scratch directory was removed.
>
> **Independent-corroboration note.** Where the two sets overlap they agree:
> `ddr_bytes_per_candidate = 16.0000`, `ddr_bytes_per_query = 1024` at 64 candidates, exact match
> to both MIG-METRIC-00 control cells, `data_mismatch = 0`, conservation closed,
> `buffer_full_stall = 0`, `cache_hit_ratio = 0` by construction, and PE utilisation low and
> non-gating. Two independently written delivery architectures (2×16 records of 16 B here; 16
> banks × 16 entries of 8 B there) reaching the same traffic numbers is corroboration — but per
> the ruling it must not be used to upgrade either verdict, and any contradiction would require a
> fresh single-implementer gate.

---

## Unknown closed

*From correctly measured MIG (MIG-METRIC-00 per-run deltas), can a **bounded** candidate/cue
working set feed 16 physical lanes with **exactly measured** traffic?*

**Yes, with the limits below.** A 512 B bounded ping/pong cue working set (2 banks × 16
records × 16 B, LUTRAM/FF, **BRAM = 0**) delivered every candidate to all 16 physical lanes of
the **existing** scorer and **existing** true global Top-8, with traffic that matches the
audited MIG-METRIC-00 control byte-for-byte, zero candidate loss or duplication, and zero data
mismatch on three independent checks.

## Path measured (given by authority, not invented here)

```text
DDR (Digilent AXI MIG)
  -> a7ng_ddr_feed_axi_bridge   REUSED UNCHANGED (SHA MATCH vs MIG-METRIC-00)
  -> a7ng_cue_wavefront         NEW: bounded ping/pong, 2 x 16 records
  -> 16-candidate wave (all 16 records in ONE cycle)
  -> a7ng_termgen_array         EXISTING, law a7ng-termgen-v0 (SHA MATCH)
  -> a7ng_ng02_core             EXISTING 16-lane a7ng_scorer_array
                                + EXISTING true global Top-8 a7ng_topk (a7ng-topk-global-v1)
                                + EXISTING a7ng_frontier_buckets            (all SHA MATCH)
```

## Measured metric table — per-run deltas, 6 runs / 3 seeds / 3 consumer patterns

UNIT = one query run. Runs execute **back-to-back without `rst_n`**; only `start_i` clears
telemetry, so a cumulative counter would be visible immediately as a doubling.

| Run | seed | base | cand | burst | out | consumer | `ddr_bytes_per_query` | `beats_per_query` | bursts | `ddr_bytes_per_candidate` |
|-----|-----:|-----:|-----:|------:|----:|----------|----------------------:|------------------:|-------:|-------------------------:|
| Q0 | 0 | 0 | 64 | 1 | 1 | ALWAYS | **1024** | **64** | **64** | **16.0000** |
| Q1 | 0 | 0 | 64 | 4 | 8 | ALWAYS | **1024** | **64** | **16** | **16.0000** |
| Q2 | 0 | 0 | 64 | 16 | 8 | ALWAYS | 1024 | 64 | 4 | 16.0000 |
| Q3 | 1 | 64 | 64 | 4 | 8 | ALWAYS | 1024 | 64 | 16 | 16.0000 |
| Q4 | 1 | 64 | 64 | 16 | 8 | SPARSE (1 of 4) | 1024 | 64 | 4 | 16.0000 |
| Q5 | 2 | 128 | 32 | 8 | 4 | BURSTY (8 of 32) | **512** | **32** | 4 | **16.0000** |

**CONTROL anchor.** Q0 reproduces MIG-METRIC-00 cell (1,1) = 1024 B / 64 bursts / 64 beats, and
Q1 reproduces cell (4,8) = 1024 B / 16 bursts / 64 beats — **exactly**. Attaching the bounded
wave delivery layer plus the full 16-lane scorer and Top-K changed the DDR traffic by zero
bytes and zero bursts against already-audited evidence. Q5's 512 B / 32 beats shows the metric
tracks candidate count rather than being a constant.

| Run | `wavefront_fill_cycles` | fill / wave | `memory_wait_fraction` | (of all cycles) | `jobs_per_cycle_during_wave` | `swap_count` | `buffer_empty_stall` | `buffer_full_stall` | cycles |
|-----|------------------------:|------------:|-----------------------:|----------------:|-----------------------------:|-------------:|---------------------:|--------------------:|-------:|
| Q0 | 1510 | **377.50** | 0.997449 | 0.973242 | **0.039826** | 4 | 1564 | **0** | 1607 |
| Q1 | 64 | **16.00** | 0.932203 | 0.561224 | **0.653061** | 4 | 55 | **0** | 98 |
| Q2 | 66 | 16.50 | 0.934426 | 0.570000 | 0.640000 | 4 | 57 | 0 | 100 |
| Q3 | 64 | 16.00 | 0.932203 | 0.561224 | 0.653061 | 4 | 55 | 0 | 98 |
| Q4 | 64 | 16.00 | 0.764706 | 0.125000 | 0.615385 | 4 | 13 | 0 | 104 |
| Q5 | 32 | 16.00 | 0.800000 | 0.103896 | 0.415584 | 2 | 8 | 0 | 77 |

`memory_wait_fraction` = `buffer_empty_stall / cons_ready_cycles` (preregistered primary);
the parenthesised column is `buffer_empty_stall / query_cycles` (preregistered secondary).
`swap_count` equals the wave count in every run: exactly one ping/pong handoff per wave.

### `candidate_conservation` and `data_mismatch`

| Run | accepted | completed | queued | pruned | in_flight | `conserve_err` | exactly-once | `data_mismatch` (3 checks) | rresp | rlast | rid_assoc | consumer_loss |
|-----|---------:|----------:|-------:|-------:|----------:|---------------:|--------------|---------------------------:|------:|------:|----------:|--------------:|
| Q0 | 64 | 64 | 0 | 0 | 0 | **0** | **PASS** | **0 / 0 / 0** | 0 | 0 | 0 | **0** |
| Q1 | 64 | 64 | 0 | 0 | 0 | 0 | PASS | 0 / 0 / 0 | 0 | 0 | 0 | 0 |
| Q2 | 64 | 64 | 0 | 0 | 0 | 0 | PASS | 0 / 0 / 0 | 0 | 0 | 0 | 0 |
| Q3 | 64 | 64 | 0 | 0 | 0 | 0 | PASS | 0 / 0 / 0 | 0 | 0 | 0 | 0 |
| Q4 | 64 | 64 | 0 | 0 | 0 | 0 | PASS | 0 / 0 / 0 | 0 | 0 | 0 | 0 |
| Q5 | 32 | 32 | 0 | 0 | 0 | 0 | PASS | 0 / 0 / 0 | 0 | 0 | 0 | 0 |

`candidate_conservation` is four independent statements, all of which had to hold:

1. `accepted == completed + queued + pruned + in_flight` checked **every cycle** in RTL → `conserve_err = 0`.
2. Every expected `node_id` delivered **exactly once** — a testbench `seen[]` census that catches
   loss *and* duplication independently of any RTL counter. `pruned = 0` structurally: the
   delivery layer has no prune path.
3. `consumer_loss = 0`, `batches_accepted == waves`, `topk_batches == waves`. This is the check
   that a wave cannot be quietly discarded at the frozen `a7ng_ng02_core` input.
4. `tb_delivered == candidates` and `tb_seq_err = 0` (delivered `node_id` sequence monotone).

`data_mismatch` is three **independently written** comparisons against the deterministic
preloaded pattern, all zero:

| Check | Where | Result |
|-------|-------|--------|
| full 128-bit record vs pattern, per lane, **at consumption** | `a7ng_cue_wavefront.pat_node` | 0 |
| AXI beat vs pattern, at the beat | reused `a7ng_ddr_feed_axi_bridge` (MIG-METRIC-00 law) | 0 |
| full 128-bit record + id sequence, per lane | testbench `pack_node` | 0 |

The RTL and testbench pattern functions are deliberately **separate implementations**, so a
shared packing bug cannot mask a delivery fault.

### Candidate-conservation cross-check by result invariance

Same seed, different traffic shape ⇒ identical Top-8 stream. If the delivery layer had
reordered, dropped or duplicated a single candidate, the true global Top-8 would move.

```text
WF_INVARIANCE_PASS Q0==Q1  top8_sequence_identical waves=4   (burst 1,out 1  vs burst 4,out 8)
WF_INVARIANCE_PASS Q0==Q2  top8_sequence_identical waves=4   (burst 1,out 1  vs burst 16,out 8)
WF_INVARIANCE_PASS Q3==Q4  top8_sequence_identical waves=4   (ALWAYS vs SPARSE consumer)
```

Top-K itself was used as an unmodified black box; it is not re-verified here (that is NG-02R's gate).

## Which hypothesis survived

| Hypothesis | Verdict | Basis |
|------------|---------|-------|
| **H_CANDIDATE** | **SUPPORTED** (with the LIMITs below) | bounded 512 B working set delivered 6/6 runs; traffic identical to CONTROL; conservation 4/4 statements; `data_mismatch = 0` on 3 independent checks; Top-8 invariant across traffic shapes |
| **H_RIVAL** — buffer starves the wave | **FALSIFIED as stated** | the buffer never withheld a wave the consumer could take; `buffer_full_stall = 0`; the measured limiter is the 128-bit AXI beat rate, not the buffer (see finding F below) |
| **H_RIVAL** — loses/duplicates candidates | **FALSIFIED** | exactly-once census PASS in 6/6; `consumer_loss = 0`; `conserve_err = 0` |
| **H_RIVAL** — traffic only reportable cumulatively | **FALSIFIED** | Q1 reads 1024 B, not Q0+Q1 = 2048 B, with no `rst_n` between runs |

## Falsifier audit

| # | Falsifier | Fired? | Evidence |
|---|-----------|--------|----------|
| F1 | invented GB/s | **No** | no bandwidth figure is stated anywhere in this closeout; only counted beats, bytes, bursts and cycles |
| F2 | cumulative counters sold as per-run | **No** | 6 back-to-back runs without reset; each reports its own 1024 B / 512 B |
| F3 | candidate loss hidden as "backpressure" | **No** | exactly-once census + `consumer_loss = 0` + `conserve_err = 0`; `buffer_full_stall` is reported separately and is 0 |
| F4 | `data_mismatch ≠ 0` at consumption | **No** | 0 on three independent checks in 6/6 runs |
| F5 | MUST-NOT-CHANGE law changed | **No** | `frozen_sha_verify.txt`: 18/18 MATCH, incl. `a7ng_topk.sv`, `a7ng_ng02_core.sv`, `a7ng_termgen_lane/array.sv`, `a7ng_scorer_lane/array.sv`, `a7ng_frontier_buckets.sv`, `a7ng_pkg.sv`, `a7ng_mem_schema_v1.sv`, `a7ng_ddr_feed_axi_bridge/pp/mig_top.sv`, `mig.prj`, and the frozen `lm06 / eam01r / eam02m / eam03e_a03` bitstreams |
| F6 | COM12 / board program / BOARD_PASS | **No** | simulation only; `COM12=NOT_PROGRAMMED`; `board_r2_rdb_latch=NOT_TOUCHED`; no BOARD claim |
| F7 | full-graph scan (HS-13) / host addresses (HS-14) | **No** | exactly `total_recs` records fetched per query (`beats == candidates`); every address generated in `a7ng_cue_wavefront` from `base_node_i` |

## Findings

**A — 16 B per candidate is the floor at this data width, not a tuning result.**
`ddr_bytes_per_candidate = 16.0000` in 6/6 runs. A `NodeRecordV1` is 16 B and one AXI beat on
the 128-bit MIG port is 16 B, so a candidate cannot cost less than one beat. Compacting the cue
record below 16 B buys nothing until several candidates share a beat.

**B — burst depth is the single decisive delivery parameter.**
`wavefront_fill_cycles` per wave collapses from **377.5** (burst = 1) to **16.0** (burst ≥ 4), a
23.6× reduction, and `jobs_per_cycle_during_wave` rises from **0.0398** to **0.653**, 16.4×.
Going from burst 4 to burst 16 changes almost nothing (16.0 → 16.5 fill cycles). The knee is at
burst ≈ 4 on this port.

**C — effective outstanding depth is capped by the bound, not by `outstanding_i`.**
AR admission requires `room16 >= this_burst`, so `queued + in_flight <= 2 × WAVE = 32` records.
At burst = 16 that permits at most 2 outstanding bursts however large `outstanding_i` is set.
Q2 and Q4 requested 8 and effectively used 2. This is a real coupling for the next gate: raising
outstanding depth requires raising the bound.

**D — flow control lands on AR, not on R.**
`buffer_full_stall = 0` and `r_backpressure_cycles = 0` in 6/6 runs, including both slow-consumer
patterns. The bounded buffer regulates by **not requesting** records it cannot hold, so the read
data channel never has to stall. This **falsifies a preregistered secondary expectation**
(`buffer_full_stall > 0` in at least one slow-consumer run) — reported as measured, see LIMIT L2.

**E — one ping/pong handoff per wave; two banks is exactly enough and no more.**
`swap_count == waves` in 6/6. A bank fills in 16 cycles and drains in 1, so with 2 banks the
consumer sees at most one wave of prefetch depth.

**F — the measured limiter is the 128-bit AXI beat rate, not the working set.**
Fill takes 16 cycles per 16-record wave at burst ≥ 4, i.e. **1 candidate/cycle**, while the wave
consumes 16 candidates in 1 cycle. Sustained delivery therefore saturates near
`jobs_per_cycle ≈ 0.65` against a hard ceiling of 1.0 set by one 16 B beat per candidate.
**Sustaining 16 lanes every cycle would need 16 beats/cycle**, which this port cannot provide at
any burst depth or buffer size. Deeper banking cannot fix it. The available levers are a wider
path, several candidates per beat, or cue reuse — a measured input for `lm06_wm_00` and the
BRAM/DDR split, not a recommendation invented here.

**G — pre-flight finding in a neighbouring file (not this gate's evidence).**
`rtl/native_graph/memory/a7ng_axi_mem_model.sv` is single-beat-only: on `ARLEN > 0` it repeats
the first beat and never asserts `RLAST` together with a valid beat. It is correct for its own
single-beat NG-03 use (`NG_SHARD_FETCH_B` = one beat per miss) and was **left byte-identical**
(SHA MATCH). The pre-flight smoke bench therefore carries its own AXI-compliant slave. Recorded
for whoever next reuses that model with bursts.

## Denominator disclosure (raised by `a7-ng-xsim-verify`)

The verifier noted that this set reports `jobs_per_cycle_during_wave` = 0.615–0.653 while the
authoritative set reports 0.441 for the same 64 records. Both are candidates ÷ cycles; the
**cycle window differs**, and this set's window is the narrower one:

```text
this set : cycles_o counts only while the wavefront is running — from start_i until the last
           wave has been drained and in_flight/queued are zero.   Q1: 64 / 98  = 0.653
other set: 145 "active_cycles" for the same 64 records — a wider window.
```

This set's denominator is exactly what its `PREREGISTER.md` declared
(`candidates_delivered / query_cycles`), so no number here is restated or reinterpreted after the
fact. The two figures are **not** a contradiction about DDR traffic — traffic is byte-identical in
both sets — they are two window conventions for the same throughput. Per the parent's ruling the
tension is not resolved here, and the numbers of this set are not offered as a replacement. If a
single throughput convention is needed downstream, it should be fixed by the parent in one place
(most defensibly: cycles from `start_i` to the cycle the last candidate reaches a lane) rather
than by preferring whichever value looks better.

## Diagnostics — explicit NON-GATES

| Run | `pe_utilization_diagnostic` | `cache_hit_ratio` | frontier pushes | frontier overflow |
|-----|----------------------------:|------------------:|----------------:|------------------:|
| Q0 | 0.0050 | 0.000 | 32 | 0 |
| Q1 | 0.0816 | 0.000 | 32 | 0 |
| Q2 | 0.0800 | 0.000 | 32 | 0 |
| Q3 | 0.0816 | 0.000 | 32 | 0 |
| Q4 | 0.0769 | 0.000 | 32 | 0 |
| Q5 | 0.0519 | 0.000 | 16 | 0 |

PE utilization is **not** a criterion for this gate and was **not** tuned toward. Formula:
`batches_accepted × 2 / query_cycles`, because the frozen `a7ng_scorer_array` occupies its 16
lanes for exactly 2 cycles per accepted batch while `a7ng_ng02_core` spends the remaining ~10
cycles on Top-8 and 8 frontier pushes. The low number is a property of the frozen consumer
contract, not of the DDR delivery path, which is why the doctrine makes this scheduler-local.

`cache_hit_ratio = 0.000` is **N/A by construction**, declared before running: every candidate
is fetched exactly once by sequential compact fetch and there is no reuse cache in this path.
It is not presented as a measured cache result, and it means 16 B/candidate is a worst case.

## LIMITs (declared, not worked around)

**L1 — candidate counts quantized to WAVE = 16.** Preregistered. The frozen `a7ng_ng02_core`
input contract is `batch_ready_o && (&lane_valid_i)`; a partial final wave cannot be accepted
without changing the Top-K / flow law, which is forbidden. All runs used multiples of 16
(64, 64, 64, 64, 64, 32). Partial-wave delivery is **untested**.

**L2 — bounded-buffer overflow behaviour is unexercised.** `buffer_full_stall = 0` everywhere,
so "no silent overwrite when full" rests on the AR admission invariant
(`queued + in_flight <= 2 × WAVE`) plus zero measured loss — **not** on a saturation experiment.
Under compliant AXI the R-stall path is structurally unreachable, which is why the preregistered
expectation did not hold. This is the main reason this set's internal verdict is **PASS_NARROW**
rather than PASS. The authoritative set records the same limitation independently as its L2.

**L6 — this set cannot close the gate.** Non-authoritative by parent ruling (see the header).
Its numbers are usable as a cross-check and as engineering input, not as gate evidence.

**L3 — MIG_XSIM, not silicon.** Digilent AXI MIG + `ddr3_model`. No board number, no refresh /
thermal / calibration variation, no COM12. Not HS-02, not HS-22, not §14, not `NATIVE_V1`.

**L4 — scope.** Candidate lists are contiguous `node_id` ranges over 160 preloaded records. The
locality-aware topic-shard layout of `feedback.md` §10 and any hotset/cache are **not** in this
path. Delivery only: no learning, no persist, no LM-06, no answer path.

**L5 — 64 candidates per query, 3 seeds, 3 consumer patterns.** Enough to escape single-pattern
pseudoreplication; not a scale claim. No 800k, no 20/40-fact curriculum.

## CHANGED

| Path | Role |
|------|------|
| `rtl/native_graph/memory/a7ng_cue_wavefront.sv` | NEW — bounded ping/pong cue working set, FPGA address generation, per-run telemetry, at-consumption verification |
| `rtl/native_graph/memory/a7ng_wavefront_mig_top.sv` | NEW — wires the reused bridge, the new wavefront, and the existing TermGen + 16-lane scorer + true Top-8 + frontier |
| `tests/xsim/tb_a7ng_wavefront_mig.sv` | NEW — MIG evidence bench: preload, 6 runs, independent scoreboard, invariance compare |
| `tests/xsim/tb_a7ng_wavefront_smoke.sv` | NEW — pre-flight smoke bench (NOT gate evidence) with its own AXI-compliant slave |
| `tests/xsim/run_a7ng_wavefront_mig.tcl` | NEW — runner, archives under `DDR-WAVEFRONT-00/` |
| `results/A7-NATIVE-GRAPH/DDR-WAVEFRONT-00/PINGPONG16/**` | logs, metric rows, SHA, PREREGISTER, this closeout |

**NOT changed:** `mig.prj` (Digilent AXI MIG, no hand-edit); 01R law; HIT_MAX; TermGen; Top-K;
relation law; LM-06 (arithmetic / weights / bitstream); 02M; training law; encoder; learning law;
HNSW; NTDE; frozen bitstreams; `a7ng_ddr_feed_pp.sv`; `a7ng_ddr_feed_mig_top.sv`;
`a7ng_axi_mem_model.sv`. `LOOP_STATE.json` status **not** flipped by this agent.

## TESTS

| ID | Result |
|----|--------|
| `xvlog` (new RTL + existing law files + MIG) | PASS (`xvlog_wavefront.log`) |
| `xelab -mt off -O0` | PASS (`xelab_wavefront.log`) |
| `xsim -runall` | PASS — `A7NG_DDR_WAVEFRONT00_XSIM_PASS` (`xsim_wavefront.log`) |
| Q0–Q5 traffic exactness (bytes / beats / bursts / bytes-per-candidate) | PASS 6/6 |
| Q0 / Q1 vs MIG-METRIC-00 CONTROL cells | PASS — exact |
| Candidate conservation (identity + exactly-once + consumer accept) | PASS 6/6 |
| `data_mismatch` on 3 independent checks | PASS 6/6 (all 0) |
| Top-8 invariance across traffic shapes | PASS 3/3 |
| Frozen / reused-law SHA | PASS 18/18 MATCH |
| Pre-flight smoke (non-evidence) | PASS (`preflight_smoke.log`) |
| `buffer_full_stall > 0` (preregistered secondary expectation) | **NOT OBSERVED** — see finding D / LIMIT L2 |
| COM12 program / BOARD_PASS / `r2_rdb` latch | REFUSED |

### Shell exit code disclosure

The PowerShell job that launched Vivado reported `exit_code = 4294967295` (-1). This is **not** a
simulation result. The job piped stdout through `Tee-Object -FilePath .../run_console.txt`, and the
concurrent authoritative session held that path open, so Tee-Object failed with
`FileOpenFailure`/`IOException` at pipeline open and poisoned the pipeline's exit status.

The run itself completed: 564465 ms wall, clean `xvlog` and `xelab`, and `xsim_wavefront.log`
carries all six `RUN_PASS` rows, the three `WF_INVARIANCE_PASS` lines, the terminal `WF_SUMMARY`
block, and `A7NG_DDR_WAVEFRONT00_XSIM_PASS`. `METRIC_ROWS.txt` is timestamped at the run's end
instant, which is only reachable after `xsim` returns to the TCL. The lost console transcript is
replaced in this directory by `run_console.txt`, which states plainly that it is a note and not a
capture. No metric in the table above is sourced from the console.

## NEXT

**STOP.** Metric table and closeout are on disk. No other gate opened, ticked or started; no
`LOOP_STATE` status flipped; `lm06_wm_00` remains BLOCKED. No COM12, no board program, no
`r2_rdb` latch.

Two items are for the parent, not for this agent:

1. Close `ddr_wavefront_00` from the **authoritative** set per
   `STATUS/AUTHORITY_DDR_WAVEFRONT_ARTIFACTS.md`. This set is a cross-check only.
2. The authoritative set's `PREREGISTER.md` at top level is intact, but note that the two
   sessions raced on that exact filename; if the parent wants a clean audit trail, the
   authoritative preregistration should be re-hashed into its own `SHA256.txt` (it is currently
   listed in the authority table but not present in that file's hash list).
