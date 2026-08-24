# SOURCE_MAP — Masterplan V2 claim → evidence path

**Date:** 2026-08-22 · **Rule:** every path in this file was checked to exist before being written.
No invented evidence.

Legend for **Class**:
`BOARD` · `BOARD_MIG` · `POST_ROUTE` · `POST_ROUTE_SOC` · `POST_ROUTE_PROXY` ·
`POST_ROUTE_FIT_LIMIT` · `FIT_LIMIT` · `OOC_POST_ROUTE` · `MIG_XSIM` · `XSIM` · `HARNESS` ·
`CHECKLIST_MAP` · `DOC` · `ENGINEERING_ESTIMATE` · `HISTORICAL_ESTIMATE` · `ABSENT`

---

## 1. LM-06 memory truth

| Claim | Class | Source |
|-------|-------|--------|
| LM-06 BRAM ownership is `u_a` 66 / `u_w` 64 / `u_snap` 2 = 132 tiles | POST_ROUTE | `results/A7-NATIVE-GRAPH/MEM-00/LM06_BRAM_OWNERSHIP_SOURCE.md` |
| 132 `BMEM` primitives enumerated from `build/out/a7lm06_post_route.dcp` | POST_ROUTE | same |
| `u_w` = 64 tiles × 36 Kbit = 2.36 Mbit vs 6.42 Mbit for 8-bit `P_LM = 802,816`, so `u_w` holds ≤ ~37% of the model and is a staging buffer | POST_ROUTE (derived) | same |
| LM-06 persistent weights are already DDR-resident; the integration problem is working-set BRAM | DOC (locked doctrine) | `results/A7-NATIVE-GRAPH/STATUS/AUTHORITY_MEMORY_DOCTRINE.md` §1–2 |
| MEM-00 gate closure | POST_ROUTE | `results/A7-NATIVE-GRAPH/MEM-00/GATE_mem00.md`, `results/A7-NATIVE-GRAPH/MEM-00/BRAM_OWNERSHIP.md` |
| Whether `u_w` is shape-sized or BRAM-sized is unresolved | POST_ROUTE (stated non-claim) | `results/A7-NATIVE-GRAPH/MEM-00/LM06_BRAM_OWNERSHIP_SOURCE.md`, "What this audit does not claim" |
| Frozen LM-06 footprint 37,555 LUT / 35,864 FF / 132 BRAM / 154 DSP, WNS +0.179 | POST_ROUTE | `results/A7-NATIVE-GRAPH/TINYGPT-SOC/frozen_lm06_utilization_route.rpt`; summarized in `results/A7-NATIVE-GRAPH/TINYGPT-SOC/FIT_BUDGET_TINYGPT_SOC.json` |

## 2. Naive BRAM stacking = FALSIFIED

| Claim | Class | Source |
|-------|-------|--------|
| Four-block naive sum = 243 BRAM / 135 (180%) | POST_ROUTE | `docs/native_graph/RESOURCE_BUDGET.md`; `results/A7-NATIVE-GRAPH/INTEGRATE/BRAM_OWNERSHIP_POST_ROUTE.md` |
| UA SoC 128 + frozen LM-06 132 = **260 / 135**, overshoot 125 | POST_ROUTE_FIT_LIMIT | `results/A7-NATIVE-GRAPH/TINYGPT-SOC/LIMIT_tinygpt_bram_fit.md`; `results/A7-NATIVE-GRAPH/TINYGPT-SOC/FIT_BUDGET_TINYGPT_SOC.json` |
| consol 132 + TinyGPT-class LM-06 132 = **264 / 135**, overshoot 129 | FIT_LIMIT | `results/A7-NATIVE-GRAPH/TINYGPT-CONSOL/LIMIT_tinygpt_consol.md` |
| Capacity co-fit shared pool = max(128, 132) = 132 tiles; WNS +0.586, TNS 0; soft ≤130 NOT met | POST_ROUTE_PROXY | `results/A7-NATIVE-GRAPH/BRAM-CONSOL/METRICS.json`; `results/A7-NATIVE-GRAPH/BRAM-CONSOL/AUDIT_bram_consolidate.md` |
| `UA128 + full LM06` stacking is forbidden | DOC (locked doctrine) | `results/A7-NATIVE-GRAPH/STATUS/AUTHORITY_MEMORY_DOCTRINE.md`, "Forbidden (NO)" |
| Device hard limit 135 BRAM; soft objective ≤130 | DOC | `BRAM_WORKING_MEMORY_SPEC.md` §31 |
| Naive sum over device is an architectural FAIL, not a warning | DOC | `docs/NATIVE_AI_ARTY_A7_BLUEPRINT/04_HARDSTOPS.md` HS-11 |

## 3. MIG evidence

| Claim | Class | Source |
|-------|-------|--------|
| `mig_metric_00 = PASS`, marker `A7NG_MIG_METRIC_XSIM_PASS` | MIG_XSIM | `results/A7-NATIVE-GRAPH/MIG-METRIC-00/CLOSEOUT.md` |
| Per-run **(1,1)** = 1024 bytes / 64 bursts / 64 beats, N=64 | MIG_XSIM | `results/A7-NATIVE-GRAPH/MIG-METRIC-00/MIG_METRIC_ROW.md` |
| Per-run **(4,8)** = 1024 bytes / 16 bursts / 64 beats, N=64 | MIG_XSIM | same |
| `data_mismatch = rresp_err = rlast_err = 0`; `expected = received = consumed = 64` | MIG_XSIM | same |
| `2048 bytes / 80 bursts` was CUMULATIVE CONTROL; per-run interpretation FALSIFIED (`H_RIVAL FALSIFIED`) | MIG_XSIM | same, "vs CONTROL" table; `results/A7-NATIVE-GRAPH/MIG-METRIC-00/CLOSEOUT.md` |
| `RVALID && !RREADY` is R-channel backpressure, not data drop; conservation authority is record/data equality | MIG_XSIM | `results/A7-NATIVE-GRAPH/STATUS/CONFORMANCE_MIG_METRIC_00_vs_FEEDBACK_SPEC.md` §6 row 2 |
| Auditor PASS for `mig_metric_00` | MIG_XSIM | `results/A7-NATIVE-GRAPH/MIG-METRIC-00/AUDIT_mig_metric_00.md` |
| `mig_board = PASS_NARROW`, evidence class `BOARD_MIG` | BOARD_MIG | `results/A7-NATIVE-GRAPH/MIG-BOARD/GATE_mig_board.md` |
| Board rows (1,1) stall = **0.923261**, (4,8) stall = **0.585366**, DROP = 0 | BOARD_MIG | `results/A7-NATIVE-GRAPH/MIG-BOARD/GATE_mig_board.md`; `results/A7-NATIVE-GRAPH/MIG-BOARD/BOARD_MIG_SWEEP_ROW.md` |
| Board WNS = +1.068 ns; Digilent AXI `mig.prj` SHA MATCH, untouched | BOARD_MIG | `results/A7-NATIVE-GRAPH/MIG-BOARD/GATE_mig_board.md` |
| Board bit SHA `EF94BA6B7D7D2ABF3B2E7EFAC965F78AD565E7300657E948062494D7008B2EF1` | BOARD_MIG | `results/A7-NATIVE-GRAPH/STATUS/QUARANTINE_MIG_BOARD_PREMETRIC.md` |
| Board rows quarantined: pre-repair cumulative counters; DROP was backpressure-derived; no integrity counters existed at capture | BOARD_MIG (scoped) | same |
| MIG_XSIM control rows (1,1) 0.958710 → (4,8) 0.549296; `H_RIVAL` FALSIFIED | MIG_XSIM | `results/A7-NATIVE-GRAPH/MIG-RIVAL/AUDIT_mig_h_rival.md` |
| **Evidence lineage:** MIG-METRIC-00 changed feeder RTL *after* the `mig_board` bit; revised RTL does not inherit BOARD evidence | derived from the two above | `results/A7-NATIVE-GRAPH/STATUS/QUARANTINE_MIG_BOARD_PREMETRIC.md`, "Required before any board MIG claim" |
| Sweep breadth is 2 of 16 burst × outstanding cells; no degree axis; no GB/s claimed | MIG_XSIM | `results/A7-NATIVE-GRAPH/STATUS/CONFORMANCE_MIG_METRIC_00_vs_FEEDBACK_SPEC.md` §1 |

## 4. DDR bottleneck and lane feeding

| Claim | Class | Source |
|-------|-------|--------|
| Arty A7 DDR3 link ≈ 16-bit @ 667 MT/s ≈ 1.33 GB/s theoretical raw | ENGINEERING_ESTIMATE | device-level arithmetic, stated as an estimate in `11_` §7.1 — **no repo measurement asserts this** |
| 16 × 16 B/cycle @ 100 MHz = 25.6 GB/s ≈ 19× the raw link | ENGINEERING_ESTIMATE (derived) | same |
| Multi-lane access is NOT demonstrated: `ddr_feed_mig_top` grants ≤ 1 PE/cycle; `pe_data` is a single 128-bit service, not 16 lanes | MIG_XSIM | `results/A7-NATIVE-GRAPH/STATUS/CONFORMANCE_MIG_METRIC_00_vs_FEEDBACK_SPEC.md` §6 row 6 |
| `lane_util >= 80%` is a scheduler-local engineering gate, not a DDR-path hard gate | DOC | `results/A7-NATIVE-GRAPH/STATUS/AUTHORITY_MEMORY_DOCTRINE.md`, DDR-WAVEFRONT-00 contract; `feedback.md` §5 |
| Best measured service in the MIG feed path = 0.444444 records/cycle | MIG_XSIM | `results/A7-NATIVE-GRAPH/STATUS/CONFORMANCE_MIG_METRIC_00_vs_FEEDBACK_SPEC.md` §1; `results/A7-NATIVE-GRAPH/MIG-METRIC-00/MIG_METRIC_ROW.md` |
| Older 1.159 GB/s mixed-throughput figure and its candidate ceilings | HISTORICAL_ESTIMATE | pre-existing text in `11_` §7.2, retained and demoted; no current artifact asserts it |
| Ping-pong DDR→working-memory architecture is the recommended direction | DOC | `feedback.md` §9; `BRAM_WORKING_MEMORY_SPEC.md` §10 |

## 5. Gate definitions (planned work)

| Claim | Class | Source |
|-------|-------|--------|
| DDR-WAVEFRONT-00 one unknown, path, must-not-change list, 8 metrics | DOC (gate contract) | `results/A7-NATIVE-GRAPH/STATUS/AUTHORITY_MEMORY_DOCTRINE.md`, "DDR-WAVEFRONT-00 (narrow)"; `results/A7-NATIVE-GRAPH/STATUS/LOOP_STATE.json` queue entry |
| LM06-WM-00 equivalence gate: same input / frozen weights / arithmetic / forward fold / update fold / persist-reload | DOC (gate contract) | `results/A7-NATIVE-GRAPH/STATUS/AUTHORITY_MEMORY_DOCTRINE.md`, "LM06-WM-00" |
| Ladder targets ≤96 / ≤64 / ≤48 / ≤32; Pareto stop; 32 not mandatory | DOC (gate contract) | same, "Ladder stop rule" |
| BRAM-OWNER-00 FSM and the one-writer-per-bank invariant | DOC (gate contract) | same, "BRAM-OWNER-00"; `BRAM_WORKING_MEMORY_SPEC.md` §29–§30 |
| Locked gate order MIG → wavefront → WM-00 → ladder → owner → integration | DOC | `results/A7-NATIVE-GRAPH/STATUS/AUTHORITY_MEMORY_DOCTRINE.md`, "Locked gate order" |
| `lm06_wm_00`, `lm06_wm_ladder`, `bram_owner_00`, `full_integration` are BLOCKED | live queue | `results/A7-NATIVE-GRAPH/STATUS/LOOP_STATE.json` |

## 6. Routed resource numbers used in `11_`

| Claim | Class | Source |
|-------|-------|--------|
| NG-01 16-lane scorer: 16 lanes, LUT 618, FF 411, BRAM 0, DSP 0, WNS +2.400, TNS 0 | POST_ROUTE | `results/A7-NATIVE-GRAPH/NG-01/closeout.md` |
| Integrate SoC `u_sc` = `a7ng_scorer_array`: LUT 1046, FF 1856, BRAM 0, DSP 0 | POST_ROUTE_SOC | `results/A7-NATIVE-GRAPH/INTEGRATE/fit_soc_util_hier.rpt` line 80 |
| Integrate SoC whole design: LUT 5695, FF 5903, BRAM 0, DSP 0, WNS +0.952, TNS 0, PE lanes 16 | POST_ROUTE_SOC | `results/A7-NATIVE-GRAPH/INTEGRATE/FIT_BUDGET_SOC.json`; `results/A7-NATIVE-GRAPH/INTEGRATE/fit_soc_util.rpt` |
| Integrate SoC bit SHA `D65F3524…A4DF`; LM-06 weight fabric ABSENT; blind exam DEFERRED | POST_ROUTE_SOC | `results/A7-NATIVE-GRAPH/INTEGRATE/AUDIT_integrate_fit_soc.md`; `results/A7-NATIVE-GRAPH/INTEGRATE/FIT_BUDGET_SOC.json` |
| LM06-SOC: BRAM 64, WNS +0.365, TNS 0, `pe_lut_u_sc` 1048, 16 lanes, `u_a` ABSENT | POST_ROUTE_SOC | `results/A7-NATIVE-GRAPH/LM06-SOC/FIT_BUDGET_LM06_SOC.json`; `results/A7-NATIVE-GRAPH/LM06-SOC/AUDIT_lm06_soc_path.md` |
| LM06-UA: BRAM 128 (`wt` 64 + `u_a` 64), WNS +0.257, TNS 0, `pe_lut_u_sc` 1047, 16 lanes, TinyGPT/DSP ABSENT | POST_ROUTE_SOC | `results/A7-NATIVE-GRAPH/LM06-UA/FIT_BUDGET_LM06_UA.json`; `results/A7-NATIVE-GRAPH/LM06-UA/AUDIT_lm06_ua_core.md` |
| Derived ≈ 65 LUT per routed lane (1046 / 16) | POST_ROUTE_SOC (derived) | arithmetic on the `u_sc` row above |
| 180 / 260 / 400 LUT per lane and all tables built on them | HISTORICAL_ESTIMATE | pre-existing `11_` §4 text and `docs/NATIVE_AI_ARTY_A7_BLUEPRINT/RESOURCE_ESTIMATE_SNAPSHOT.txt` |
| WM-00 OOC: WNS +0.069, TNS 0; CONTROL WNS −290.499 | OOC_POST_ROUTE | `results/A7-NATIVE-GRAPH/BRAM-WM-00/timing/AUDIT_wm00_timing.md`; `results/A7-NATIVE-GRAPH/STATUS/AUDIT_section14.md` re-derive table |
| Device resources 63,400 LUT / 126,800 FF / 135 BRAM / 240 DSP | DOC | `docs/native_graph/RESOURCE_BUDGET.md` |

## 7. Status-table rows

| Row claim | Class | Source |
|-----------|-------|--------|
| Exact global Top-8 replaces pair-winner Top-K (SEV-0) | XSIM | `results/A7-NATIVE-GRAPH/NG-02R-TOPK/closeout.md`; defect described in `feedback.md` §3 |
| Lossless flow control | XSIM | `results/A7-NATIVE-GRAPH/NG-02R-FLOW/closeout.md` |
| Wide dispatch, auditor r3 PASS | XSIM | `results/A7-NATIVE-GRAPH/NG-06R-WIDE/AUDIT_ng06_wide_sci_r3.md` |
| Query/path epochs, `DROP_STALE`, alive = 256 | XSIM | `results/A7-NATIVE-GRAPH/NG-06R-EPOCH/AUDIT_ng06_epoch.md` |
| TermGen 4 families exact at n=32, DSP 0 | XSIM + OOC | `results/A7-NATIVE-GRAPH/TERMGEN/AUDIT_termgen.md` |
| PERFMON counters | XSIM | `results/A7-NATIVE-GRAPH/PERFMON/AUDIT_perfmon.md` |
| Frontier shootout winner `B_systolic` | XSIM + OOC | `results/A7-NATIVE-GRAPH/FRONTIER-SHOOTOUT/AUDIT_frontier_shootout.md` |
| Record schema Node16 / Edge32 / Episode32 | XSIM + pytest | `results/A7-NATIVE-GRAPH/MEM_SCHEMA_V1/AUDIT_mem_schema_v1.md`; `docs/native_graph/RESOURCE_BUDGET.md` |
| WM-00 lossless, BRAM 0 | XSIM | `results/A7-NATIVE-GRAPH/BRAM-WM-00/AUDIT_bram_wm_00.md` |
| DDR-FEED synthetic ping-pong stall 0.96 → 0.47 (LAT=24, not MIG) | XSIM | `results/A7-NATIVE-GRAPH/DDR-FEED/AUDIT_ddr_feed.md` |
| Anti-leak boundary tests | HARNESS | `tests/native_graph/test_ng00_anti_leak.py` |
| Teacher-off framing, UART stub `0x91`, `lm_path = 0`, LM-06 ABSENT | BOARD_UART_STUB | `results/A7-NATIVE-GRAPH/TEACHER_OFF/AUDIT_teacher_off.md` |
| Board `lm_path = 1` visibility probe, bit `4451AFD9…`, UART `91B9` | BOARD_UART_LM_PATH_PROBE | `results/A7-NATIVE-GRAPH/HS02-LMPATH/AUDIT_hs02_lm_path.md` |
| Semantic HS-02 remains OPEN; TinyGPT/answer ABSENT LIMIT | BOARD_UART_SEMANTIC_LIMIT | `results/A7-NATIVE-GRAPH/HS02-SEMANTIC/AUDIT_hs02_semantic_evidence.md` |
| LM-06 answer path (HS-22) OPEN; TinyGPT absent on consol CONTROL, DSP 0 | FIT_LIMIT | `results/A7-NATIVE-GRAPH/TINYGPT-CONSOL/LIMIT_tinygpt_consol.md` |
| Evidence compose exists but ≠ LM-06 active integration | XSIM | `results/A7-NATIVE-GRAPH/LM_COMPOSE/GATE_lm_compose.md`; distinction in `feedback.md` §19 |
| DDR-backed episode/index stores | XSIM | `results/A7-NATIVE-GRAPH/MEM-01_02/GATE_mem01_mem02.md` |
| Reset / retrain logical generation | XSIM | `results/A7-NATIVE-GRAPH/RESET-00/AUDIT_reset00.md` |
| TRAIN-V2 harness only, not HS-02 silicon | HARNESS | `results/A7-NATIVE-GRAPH/TRAIN-V2/AUDIT_train_v2.md` |
| Native query anchors / intent shift | XSIM | `results/A7-NATIVE-GRAPH/NG-07/GATE_ng07.md`, `NG-08/GATE_ng08.md`, `NG-09/GATE_ng09.md` |
| 800k scale has no file-backed measurement | ABSENT | `results/A7-NATIVE-GRAPH/STATUS/AUDIT_section14.md`, MAJOR finding 3 |
| `NATIVE_V1_MINI_AI_BOARD_PASS = NOT EVIDENCED` | CHECKLIST_MAP | `results/A7-NATIVE-GRAPH/PROJECT_COMPLETE.md`, final verdict line |
| BRAM ownership post-route report exists at INTEGRATE | POST_ROUTE | `results/A7-NATIVE-GRAPH/INTEGRATE/BRAM_OWNERSHIP_POST_ROUTE.md` |
| 01R / 02M frozen contracts | DOC | `docs/contracts/A7-EAM-01R.md`, `docs/contracts/A7-EAM-02M.md` |
| Encoder lane OPEN / PARKED under its own authority | DOC | `MUST_READ_UNBLOCK_H5.md`; `results/A7-EAM-03E/MUST_READ_UNBLOCK_H5.md`; `results/A7-EAM-03E/final.md` |

## 8. Doctrine and policy claims

| Claim | Class | Source |
|-------|-------|--------|
| HNSW = `RESEARCH_ALLOWED, DATAPATH_NOT_APPROVED`; `M=16` is a coincidence; 01R-only ladder first; A/B/C arms with a quality gate | DOC | `results/A7-NATIVE-GRAPH/STATUS/PLAN_KDENSE_20260822.md` §1 RQ5, §2 H-hnsw, §4 Phase E |
| HNSW forbidden until correctness closes | DOC | `results/A7-NATIVE-GRAPH/STATUS/AUTHORITY_FEEDBACK_INGEST.md`, "Forbidden until CORRECTNESS_REPAIR_PASS" |
| Session law: one unknown per gate, no self-chaining | DOC + live | `results/A7-NATIVE-GRAPH/STATUS/AUTHORITY_MEMORY_DOCTRINE.md`, "Session law"; `LOOP_STATE.json` `session_override` |
| Migration must not retune semantic law (one unknown) | DOC | `docs/NATIVE_AI_ARTY_A7_BLUEPRINT/04_HARDSTOPS.md` HS-25 |
| Training writeback: dirty bit, coalescing, thresholded commit, end-of-query commit | DOC | `BRAM_WORKING_MEMORY_SPEC.md` §25; `feedback.md` §13 |
| SPEC §28 requires a BRAM ownership report before any full-integration claim | DOC | `BRAM_WORKING_MEMORY_SPEC.md` §28 |
| `BRAM_WORKING_MEMORY_ARCH_PASS` 10 conditions | DOC | `BRAM_WORKING_MEMORY_SPEC.md` §45 |
| Parameter count and memory capacity must stay separate | DOC | `docs/NATIVE_AI_ARTY_A7_BLUEPRINT/04_HARDSTOPS.md` HS-21 |
| Compute ceiling ≠ system throughput; 16 instantiated lanes ≠ 16 busy lanes | DOC | `feedback.md` §2.2, §7 |
| `EVIDENCE_PACKET_PASS != LM06_ACTIVE_INTEGRATION_PASS` | DOC | `feedback.md` §19 |

---

## 9. Unresolved / contested — recorded, not silently reconciled

| Item | Detail | Disposition |
|------|--------|-------------|
| **01R LUT figure** | `docs/NATIVE_AI_ARTY_A7_BLUEPRINT/README.md` records 1,252 LUT; `docs/native_graph/RESOURCE_BUDGET.md` records 1,452 LUT for the same block. The naive sum 48,618 in both documents is only consistent with **1,252** (8,107 + 1,252 + 1,704 + 37,555 = 48,618). | Masterplan V2 keeps 1,252 because it is arithmetically consistent with the frozen naive sum. `RESOURCE_BUDGET.md` is outside this task's scope and was not edited. Flagged for the owner. |
| **BRAM ownership report** | `results/A7-NATIVE-GRAPH/INTEGRATE/BRAM_OWNERSHIP_POST_ROUTE.md` **exists** with the seven SPEC §28 columns, but `results/A7-NATIVE-GRAPH/STATUS/CONFORMANCE_MIG_METRIC_00_vs_FEEDBACK_SPEC.md` §6 row 9 records it as MISSING, and `LOOP_STATE.json` keeps `bram_ownership_report` QUEUED. | Recorded in the status table as PASS_NARROW **with the contest noted**. Not resolved here; resolving it requires a gate, not a document. |
| **DDR-WAVEFRONT-00 live status** | Authored while OPEN; closed by a parallel session at 11:58 during this revision as DONE_ENG / PASS_NARROW / `MIG_XSIM_WAVEFRONT`. | Masterplan V2 carries **no result** from the gate — only its contract. Recorded in `00_CURRENT_AUTHORITY.md` §10.2. Read `LOOP_STATE.json` for live status. |
| **1.33 GB/s theoretical raw link** | Device-level arithmetic (16-bit @ 667 MT/s). No repository artifact measures it. | Labelled `ENGINEERING_ESTIMATE` everywhere it appears. Never used to derive a throughput claim. |
| **1.159 GB/s mixed throughput** | Pre-existing figure in `11_` with no artifact in this repository. | Demoted to `HISTORICAL_ESTIMATE` and explicitly excluded from current DDR capability claims. |
