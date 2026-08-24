# CLOSEOUT — ddr_wavefront_00

**Result:** **PASS_NARROW**
**Evidence_class:** `MIG_XSIM_WAVEFRONT` (Digilent AXI MIG + `ddr3_model`) — **not BOARD**
**Agent:** `a7-ng-memory-arch`
**Marker:** `A7NG_DDR_WAVEFRONT_XSIM_PASS`
**Artifact:** `results/A7-NATIVE-GRAPH/DDR-WAVEFRONT-00/RESULTS.md`
**Preregistration:** `PREREGISTER.md` (written before any RTL edit or measurement)

## The one unknown — and the answer

> From correctly measured MIG, can a **bounded** candidate/cue working set feed **16 physical
> lanes** with **exactly measured** traffic?

**Yes, for the narrow question, on four traffic patterns.**

- **Bounded:** declared before measurement as 16 banks × 16 entries = 256 compact-cue entries
  (2 KiB). Measured peak occupancy **22 entries (176 B)**, i.e. 8.6% of the declared bound.
- **16 physical lanes:** `jobs_per_emit_cycle = 16.0000`, 4/4 full waves, `min_wave_width = 16`,
  and the golden `node_id` **and** `cue` were verified independently **on every one of the 16 lanes**
  at consumption. This is 16 candidates leaving the working set in one cycle, not a rename.
- **Exactly measured traffic:** 1024 B / 64 bursts at burst=1 and 1024 B / 16 bursts at burst=4 —
  **byte-for-byte and burst-for-burst identical to the MIG-METRIC-00 control**. Adding the
  wavefront changed DDR traffic by zero. `ddr_bytes_per_candidate = 16.0000` exactly.
- **Conserved:** E1–E5 all hold in 4/4 patterns; `data_mismatch = 0` across four independent checks.

## Hypothesis disposition (precise)

| Hypothesis | Disposition |
|------------|-------------|
| **H_CANDIDATE** | **SUPPORTED** for the narrow claim: a bounded ping/pong compact-cue working set sustains 16-wide candidate waves with conserved records and measured, explainable DDR traffic. |
| **H_RIVAL arm 1** — "traffic only looks healthy because it is cumulative or unconserved" | **FALSIFIED.** Per-run `metric_clear` deltas; every pattern reads exactly 1024 B; E1–E5 exact; `data_mismatch = 0`. |
| **H_RIVAL arm 2** — "the 16-wide wave is really a ≤1 candidate/cycle service renamed" | **FALSIFIED for width, SURVIVES for sustained throughput.** The emit is genuinely 16 candidates in one cycle (F7 clean). But the sustained rate is `jobs_per_cycle_during_wave = 0.4414` (burst=4) and `0.4444` (burst=16) versus the MIG-METRIC-00 one-PE-per-cycle control of `0.4444`. Widening the dispatch did **not** raise sustained candidate throughput, because DDR delivers at most one 16 B beat per `ui_clk`. |

That second row is why this closeout is **PASS_NARROW** and not PASS. The gate proves delivery is
*correct, bounded and exactly measured*; it does **not** prove DDR starvation is solved. Measured
`memory_wait_fraction = 0.9725 / 0.8146 / 0.9722` — the wavefront spends ~81–97% of its active
cycles waiting for memory to complete a wave. `feedback.md` §9's prediction that memory movement,
not LUT arithmetic, is the next bottleneck is now **measured**, not asserted.

## THE NUMBER LM06-WM-00 NEEDS

This is the reason the doctrine put this gate before any LM-06 BRAM cut.

| Quantity | Value | Basis |
|----------|------:|-------|
| **DDR-delivery working set — declared bound** | **3 KiB** | 2 KiB cue banks (16 × 16 × 8 B) + 1 KiB ping/pong (2 × 32 × 16 B) |
| **DDR-delivery working set — measured peak (cue banks)** | **176 B** (22 entries) | worst of 4 patterns (P3, throttled) |
| Cue-bank occupancy, unthrottled | 128 B (16 entries) | P1/P2/P4 |
| In RAMB18 terms (18 Kib = 2.25 KiB/tile) | **≤ 2 tiles** if forced to BRAM; **~0 tiles** as LUTRAM | 3 KiB ÷ 2.25 KiB |
| Recommended sizing to carry into LM06-WM-00 | **4 entries/bank = 64 entries = 512 B** compact | 4× margin over the measured 22-entry peak |
| `ddr_bytes_per_candidate` to budget | **16 B** (worst case, no cache) | measured, 4/4 patterns |
| Candidates per query measured | **64** (4 waves × 16) | this gate's UNIT |

**Consequence for the 260 → ≤135 tile problem:** DDR delivery buffering is **not** the thing
competing with LM-06's ~132 tiles. It fits in well under two RAMB18 tiles, and at the measured
occupancy it fits in LUTRAM. `LM06-WM-00` should therefore budget ≈2 tiles (or 0 with LUTRAM) for
candidate delivery and spend its entire ladder effort on the LM-06 working set itself. Choosing a
96/64/48/32 target blind — which the doctrine warned against — is no longer necessary for the
delivery side.

## Secondary measured findings (reported, not turned into decisions)

- **burst=1 is pathological, and the plateau is already at burst=4.** Active cycles per query:
  1609 (burst=1) → 145 (burst=4) → 144 (burst=16). `swap_count` 64 → 2. `wavefront_fill_cycles`
  401.25 → 35.25 → 35.00 cycles/wave.
  **This does not choose a burst depth for the program.** `mig_sweep_full` (status QUEUED, 4×4 grid)
  remains the authority; this gate contributes 3 of its 16 cells and nothing more.
- **Delivery timing does not perturb the scored result.** The final wave's true Top-8 winner is
  identical (`id=57, score=165`) across all four patterns, including the throttled one.
- **`swap_count`, `buffer_empty_stall`, `buffer_full_stall`** are now instrumented per SPEC §10 for
  the wavefront path (previously absent).

## LIMITs (explicit)

| # | LIMIT |
|---|-------|
| **L1** | Simulation-class only. `MIG_XSIM_WAVEFRONT` ≠ board. No synthesis, no post-route utilisation, no timing/WNS claim, no LUTRAM/BRAM cost measured for `a7ng_cue_wave_stage`. The 3 KiB figure is an architectural declaration plus measured occupancy, **not** a post-route report. |
| **L2** | **Bounded-ness verified as headroom, not as saturation.** `bank_full_stall = 0` and `buffer_full_stall = 0` in all four patterns: the buffer never filled, so the refuse-instead-of-overwrite path was never taken at runtime. "No silent overwrite" rests on the explicit `in_ready_o` handshake and code inspection, plus a `max_resident > bound` assertion that never triggered. A pattern that actually saturates the working set is still owed. |
| **L3** | Sustained candidate throughput is DDR-bound and **unchanged** versus the one-per-cycle service (0.4414 vs 0.4444 control). This gate does not deliver a 16× throughput win and must not be cited as one. |
| **L4** | No cue cache / hotset in this path, so `cache_hit_ratio = 0` by construction and `16 B/candidate` is a worst-case upper bound, not a cached steady state. |
| **L5** | `TOTAL = 64` candidates/query and 128 preloaded nodes (MIG sim wall-clock), matching the MIG-METRIC-00 control. Sequential node order only; no random/pointer-chasing access pattern, no relation/edge traffic, no writeback traffic. |
| **L6** | Ping/pong **peak** occupancy was not instrumented (only its instantaneous `occ_active`/`occ_fill` and end-of-run residency, both 0). Its 1 KiB contribution to the 3 KiB figure is the declared bound, not a measured peak. |
| **L7** | The 32-bit NodeRecordV1 cue is widened to the 64-bit TermGen cue bus by replication (`{cue, cue}`). That is a wiring choice of this gate, declared in the RTL; the TermGen law itself is untouched. Scores here are therefore not a semantic retrieval claim. |
| **L8** | The synthetic preflight (`xsim_preflight_synth_axi.log`) is **not** gate evidence. `a7ng_axi_mem_model` was measured to return a duplicated/lagged beat for any burst > 1, so the preflight is burst=1 only. All burst-depth evidence comes from the real Digilent AXI MIG. |
| **L9** | Top-K and the scorer were run as unmodified black boxes and are **not** re-verified here. `topk_batches = 4` and the Top-1 invariance are delivery observations, not a Top-K correctness result. |

## Session law compliance

| Requirement | Status |
|-------------|--------|
| One unknown | Yes — delivery only. `lm06_wm_00`, BRAM ladder, `bram_owner_00`, `mig_sweep_full`, full integration **not opened** |
| No COM12 program | Yes — no programming of any kind |
| No `r2_rdb` latch | Yes |
| Simulation-class evidence | Yes — `MIG_XSIM_WAVEFRONT` |
| No self-chaining | Yes — ends with STOP |
| Frozen law untouched | Yes — `FROZEN_VERIFY.md`; `ddr_feed_pp`, `axi_bridge` and `mig.prj` byte-identical to MIG-METRIC-00 |
| Existing 16-lane scorer + true Top-K reused as black boxes | Yes — instantiated unmodified |
| PE utilisation not used as a gate | Yes — diagnostic only (0.0025–0.028) |
| ≥2 traffic patterns | Yes — 4 |
| AI does not declare BOARD_PASS | Yes — no board claim anywhere |

## CHANGED

| Path | Role |
|------|------|
| `rtl/native_graph/memory/a7ng_cue_wave_stage.sv` | **NEW** — bounded 16-bank compact-cue working set + 16-wide wave emit + telemetry |
| `rtl/native_graph/memory/a7ng_ddr_wavefront_top.sv` | **NEW** — DDR → burst fetch → ping A/B → wave → existing 16 lanes → existing Top-8 |
| `tests/xsim/tb_a7ng_ddr_wavefront.sv` | **NEW** — MIG gate TB: 4 patterns, conservation ledger, per-lane golden scoreboard |
| `tests/xsim/tb_a7ng_ddr_wavefront_pre.sv` | **NEW** — synthetic preflight (not gate evidence) |
| `tests/xsim/run_a7ng_ddr_wavefront.tcl` | **NEW** — xvlog/xelab(`-mt off -O0`)/xsim runner, archives to this directory |
| `results/A7-NATIVE-GRAPH/DDR-WAVEFRONT-00/**` | PREREGISTER, RESULTS, CLOSEOUT, FROZEN_VERIFY, SHA256, raw logs |
| `docs/native_graph/RESOURCE_BUDGET.md` | measured `ddr_wavefront_00` rows |

**NOT changed:** `a7ng_ddr_feed_pp.sv`, `a7ng_ddr_feed_axi_bridge.sv`, `mig.prj` (all SHA-MATCH to
MIG-METRIC-00); 01R law; HIT_MAX; TermGen; Top-K; relation law; LM-06; 02M; training/learning;
encoder; HNSW; NTDE; frozen bitstreams.

## NEXT

**STOP.** Parent/auditor closeout only. `lm06_wm_00` stays BLOCKED until the parent re-opens it with
the working-set number above. `mig_sweep_full` stays QUEUED. No COM12. No board latch.
