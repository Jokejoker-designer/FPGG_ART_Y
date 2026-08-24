# CONFORMANCE — MIG-METRIC-00 vs `feedback.md` + `BRAM_WORKING_MEMORY_SPEC.md`

**Purpose:** record, requirement-by-requirement, what the `mig_metric_00` MIG_XSIM evidence does and
does **not** satisfy in the two authority docs. Reference note only — **no gate opened, no queue tick**.

**Authority read:** `feedback.md` (2026-08-21), `BRAM_WORKING_MEMORY_SPEC.md` (`A7-NATIVE-BRAM-WM-SPEC-v1`)
**Evidence read:** `results/A7-NATIVE-GRAPH/MIG-METRIC-00/{MIG_METRIC_ROW.md,CLOSEOUT.md,xsim_mig_metric.log}`
**RTL read:** `rtl/native_graph/memory/{a7ng_ddr_feed_axi_bridge.sv,a7ng_ddr_feed_mig_top.sv,a7ng_ddr_feed_pp.sv}`

---

## 1. `feedback.md` §9 — "DDR is likely to starve the PE array"

Required development order: reduce candidates → locality → burst DDR → double buffer →
multiple outstanding reads → **measure PE utilization** → only then increase PE count.

| §9 required measurement | Status | Evidence |
|---|---|---|
| burst sweep 1 / 4 / 8 / 16 | **PARTIAL** — only burst 1 and 4 exercised | `MIG_METRIC_ROW.md` two rows |
| outstanding sweep 1 / 2 / 4 / 8 | **PARTIAL** — only out=1 and out=8 | same |
| graph degree 4 / 8 / 16 | **MISSING** — degree not a swept axis | no rows |
| effective GB/s | **DELIBERATELY ABSENT** | falsifier "invent GB/s" fired-check = No; XSim behavioral MIG cannot source real DDR timing |
| DDR bytes/query | **PRESENT** — `axi_read_bytes` per run | 1024 B both cells |
| cache hit rate | **MISSING** — no cache in the ddr_feed path | no counter in bridge/top/pp |
| PE stall cycles | **PRESENT** — `pe_stall_o` | `a7ng_ddr_feed_mig_top.sv:24` |
| PE utilization | **PRESENT** — `pe_busy_o` / `cycles_o`; `stall_frac` 0.960445 → 0.555556 | `MIG_METRIC_ROW.md` |
| latency/query | **MISSING as a named metric** — only `cycles_o` and `recs_per_cyc` proxy | same |

**Reading:** §9's *ordering* discipline is honored (burst + double buffer + multi-outstanding measured
before any PE-count increase), and the `stall_frac` drop 0.96 → 0.56 is the first trustworthy
per-run evidence that multi-outstanding burst actually relieves starvation. §9's *sweep breadth* is not
yet satisfied: two of sixteen (burst × outstanding) cells, zero degree axis.

**§5 "average physical lane utilization >= 80%"** is **NOT met and not claimed**: best measured cell
is `1 − 0.555556 = 0.444444` records/cycle service. Note the reconciliation with locked authority —
`STATUS/AUTHORITY_MEMORY_DOCTRINE.md` rules that 80% PE utilization is **not a hard gate for the DDR
path** because it is scheduler-local, and a DDR path may be healthy while PEs work in bursts.
feedback §5 itself calls it "not a scientific law, but a useful engineering gate". Treat it as an open
*scheduler* objective, not a memory-path blocker.

---

## 2. `feedback.md` §12 — memory record schemas must be frozen

| Requirement | Status |
|---|---|
| one authoritative `NodeRecordV1` | **HONORED in this gate** — TB preloads NodeRecordV1 and the PE consume path checks `node_id` against `expect_nid_o` |
| exact byte size / offsets / alignment / version | **PARTIAL** — 16 B stride is consistent across TB and bridge (64 recs × 16 B = 1024 B, self-consistent with measured bytes), but this gate did not produce a schema document |
| no independent magic strides in RTL/Python/frontend/TB | **UNVERIFIED at repo scope** — this gate only proves the RTL↔TB pair agree |
| golden serialize/deserialize tests | **MISSING** |

`data_mismatch_count = 0` and `pe_data_mismatch_count` checking give the first *content* integrity
proof on this path; previously only byte counts were checked. This is the concrete §12 progress.

---

## 3. `feedback.md` §21 — low-cost PERFMON

Of the §21 counter list, the ddr_feed MIG path now provides: `cycles_total` (`cycles_o`),
`ddr_req`/`ddr_rsp` (bursts/beats), `ddr_read_bytes`, `ddr_stall_cycles` (`empty_stall`/`full_stall`/`pe_stall`).

Still absent on this path: `lane_busy[16]` per-lane (only aggregate `pe_busy_o`), `candidates_in/out`,
`topk_batches`, `frontier_push/pop/full`, `queue_occupancy_accum`, `scheduler_grants/idle/starve`
(only `pe_grant_count_o`), `cache_hit/miss`, `prune_count`, `stale_drop`.
Several of these exist elsewhere (`rtl/native_graph/perfmon/a7ng_perfmon.sv`,
`a7ng_wm00_top.sv`, `a7ng_multi_agent_share.sv`) but are **not** wired into the MIG feed path.

---

## 4. `BRAM_WORKING_MEMORY_SPEC.md` §10 — ping-pong telemetry

| SPEC §10 counter | Status | Note |
|---|---|---|
| `ping_busy_cycles` | **PROXY ONLY** — `occ_active_o` is occupancy, not a cycle accumulator |
| `pong_fill_cycles` | **PROXY ONLY** — `occ_fill_o`, same limitation |
| `swap_count` | **MISSING** — `do_swap` is a wire in `a7ng_ddr_feed_pp.sv:113` with no counter output |
| `buffer_empty_stall` | **PRESENT** — `empty_stall_o` |
| `buffer_full_stall` | **PRESENT** — `full_stall_o` |

`swap_count` is the cheapest remaining addition and is the direct witness for SPEC §10's
"overlap DDR traffic with compute" claim. Recommend it before any board latch.

---

## 5. SPEC §27 / §11 — working-memory + banking counters

`bank_conflict_count`, `conflict_stall_cycles`, `cache_hit/miss`, `learning_updates`,
`dirty_writebacks`, `ddr_writes`, `ddr_write_bytes`, and per-lane `lane_busy[i]`/`lane_stall[i]`
are **not present** in the ddr_feed MIG path. `mig_metric_00` is read-only feed; there is no write path,
so `ddr_writes` is legitimately N/A for this gate, but the rest remain open for WM integration.

---

## 6. SPEC §45 — `BRAM_WORKING_MEMORY_ARCH_PASS`

| # | Requirement | mig_metric_00 contribution |
|---|---|---|
| 1 | exact Top-K semantics | **N/A** — closed separately at NG-02R-TOPK |
| 2 | no silent data loss | **ADVANCED** — this is the gate's core result: `expected = received = consumed = 64` on both cells; the old `RVALID && !RREADY` "DROP" is correctly demoted to `r_backpressure_cycles` |
| 3 | query/path scoped state | **N/A** this gate |
| 4 | persistent knowledge in DDR | **N/A** this gate |
| 5 | working-memory buffers bounded | **PARTIAL** — `BANK_DEPTH=32` bounded, occupancy reported |
| 6 | multi-lane access demonstrated | **NOT DEMONSTRATED** — `a7ng_ddr_feed_mig_top` grants ≤1 PE/cycle and `pe_data` is a single 128-bit service, not 16 lanes |
| 7 | DDR/BRAM traffic measured | **ADVANCED** — per-run deltas now trustworthy |
| 8 | post-route timing PASS | **N/A** this gate (MIG_XSIM only) |
| 9 | BRAM ownership documented | **PARTIAL** (corrected 2026-08-22) — `results/A7-NATIVE-GRAPH/INTEGRATE/BRAM_OWNERSHIP_POST_ROUTE.md` **does exist** and carries the SPEC §28 required columns for LM-06 (`u_w` 64 / `u_a` 66 / `u_snap` 2), encoder, graph hotset, episode/index banks, MIG buffers and debug. It is scoped to the `integrate_fit` 130-tile cut and omits **router** and **integration FIFOs**. Earlier "does not exist" in this note was factually wrong. |
| 10 | no Native AI boundary violation | **PASS** — HLB CLEAN, no host grad/winner/address/answer |

---

## 7. Net reading

`mig_metric_00` is a genuine advance on exactly one axis both docs care about: **measurement
trustworthiness**. It converts SPEC §45.2 (no silent data loss) from a byte-count assertion into a
record-equality proof, and it removes the cumulative-counter defect that would have made every
downstream burst/outstanding decision (feedback §9: "do not choose burst depth by intuition")
unfalsifiable.

It does **not** advance: lane utilization ≥80% (feedback §5), 16-lane concurrency (SPEC §45.6),
schema freeze documents (feedback §12), BRAM ownership report (SPEC §28), or any semantic claim.

Nothing here changes the standing order as of **2026-08-22**: `mig_board_r2` is **DONE_ENG**
(BOARD_MIG 16/16); pre-metric board rows remain quarantined for history only; GOAL = **NOT EVIDENCED**.

**See:** `STATUS/RECONCILIATION_FEEDBACK_SPEC_vs_MASTERPLAN_V2.md` for full feedback/SPEC ↔ evidence map.

## 8. Recommended next narrow gates (queued `QUEUED`, non-dispatchable)

Entered in `LOOP_STATE.queue` with `status="QUEUED"`, which the dispatcher ignores
(`run_blueprint_loop.py` selects only `status` starting with `OPEN`). Nothing here auto-runs.

1. ~~`mig_sweep_full`~~ — **MERGED/DONE** as `mig_board_r2` (16/16 silicon grid).
2. `bram_ownership_report` — **EXTEND** the existing `INTEGRATE/BRAM_OWNERSHIP_POST_ROUTE.md` to cover
   router and integration FIFOs, and re-issue it against the final Native V1 cut rather than the
   `integrate_fit` cut. The SPEC §28 report is not missing, it is partial; full integration claims stay
   blocked until it covers the shipped configuration.
3. `record_schema_freeze` — feedback §12 authoritative NodeRecord/EdgeRecord/EpisodeRecord + golden round-trip tests.
4. `mig_pe_wide` — SPEC §45.6 multi-lane service; today ≤1 grant/cycle.
   **SUPERSEDED IN PART** by the now-OPEN `ddr_wavefront_00` (see `AUTHORITY_MEMORY_DOCTRINE.md`),
   whose single unknown is whether a bounded working set can feed 16 physical lanes with measured
   traffic. Do not run both; fold `mig_pe_wide` into the wavefront result.

## 9. Provenance / limits of this note

Derived by reading both authority docs in full plus the MIG-METRIC-00 archive and the three
ddr_feed RTL files. Counter presence/absence claims come from direct port and signal inspection,
not from documentation. Not verified here: repo-wide stride usage (Python/frontend/loader), and any
post-route number. This note asserts no BOARD or semantic claim.
