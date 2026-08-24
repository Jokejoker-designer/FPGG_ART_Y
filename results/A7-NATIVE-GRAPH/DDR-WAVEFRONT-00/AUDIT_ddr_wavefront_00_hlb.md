# HLB AUDIT — gate `ddr_wavefront_00` (VERIFY_ONLY)

**Auditor:** `a7-hlb-auditor` · **Mode:** VERIFY_ONLY (no RTL/TB/TCL edited)
**Verdict:** `HLB: CLEAN` — **0 violations**, 2 MINOR findings, 5 recorded risks for `lm06_wm_00`
**Scope lock:** `results/A7-NATIVE-GRAPH/STATUS/AUTHORITY_DDR_WAVEFRONT_ARTIFACTS.md`
**Audited set:** `tb_a7ng_ddr_wavefront` only. `tb_a7ng_wavefront_mig` / `PINGPONG16/` treated as UNCITED.
**Evidence class:** `MIG_XSIM_WAVEFRONT` — simulation only.

## 1. Host / answer-path boundary

There is **no host on this gate's path.** The only host-side file is
`tests/xsim/run_a7ng_ddr_wavefront.tcl`, which invokes `xvlog`/`xelab`/`xsim`, writes the compile
list, and string-matches the marker. It carries no data into the DUT and computes no result.

The only actor that drives the DUT is the testbench. Full payload surface, classified:

| TB → DUT field | Value in gate | Class |
|----------------|---------------|-------|
| `start_i` | pulse per pattern | MODE (per-run `metric_clear`) |
| `burst_i` / `outstanding_i` | 1/1, 4/8, 4/8, 16/8 | MODE (traffic pattern axis) |
| `base_node_i` | `0` | CONFIG — base of the query's record range, **not** a per-candidate address. Per-record addresses are generated inside frozen `a7ng_ddr_feed_pp`. |
| `total_recs_i` | 64 | CONFIG (candidate count = UNIT) |
| `sink_ready_i` | always / 1-in-8 | MODE (downstream throttle) |
| `flush_i` | `= feed_done` | MODE (tail-wave release; no stranding) |
| `query/relation/intent/context/path_cue_i` | fixed 64-bit literals | QUERY-CONTEXT, constant across all four patterns. Not a per-candidate cue, not a winner, not derived from any expected result. |
| `learned_prior_i` | `8'sd3` | QUERY-CONTEXT constant |
| AXI write channel (preload) | 128 `NodeRecordV1` beats | MEMORY-PRELOAD — the data under test must physically exist in DRAM. DUT has **no** AXI write port and is held in reset (`rst_n_ui` includes `feed_en`) throughout preload. |
| — | — | **No** VIOLATION field. No gradient, weight, delta, winner, way, per-record address, retrieval result, next token, or answer. |

### Golden data: measurement only, cannot reach a scoring decision

`pack_node()` / `golden_cue()` (`tests/xsim/tb_a7ng_ddr_wavefront.sv:274-289`) are used for exactly
two things:

1. **Preload** the DDR contents through the MIG AXI write channel (`preload_nodes`, line 350).
2. **Check at consumption** (line 299-323): for every fired wave and every one of the 16 lanes,
   `w_id[b] !== exp_id || w_cue[b] !== golden_cue(exp_id)` increments `tb_wave_mismatch`.

`tb_wave_mismatch` is consumed only by `$display` and by `cell_fail` (the TB's own verdict). It
drives **no DUT input**. The DUT's scoring input `tg_cues_i[b].node_cue` is wired from `w_cue[b]`
— the DUT's own DDR-read data path (`a7ng_ddr_wavefront_top.sv:245`) — never from `golden_cue()`.
There is therefore no path by which golden data can enter a score, a rank, or a Top-K comparison.

**No answer key exists at all on the scored output.** `top1_id_o` / `top1_score_o` are read out and
printed as `WF_DIAG` diagnostics; the TB never asserts them against an expected value. The
`id=57, score=165` figure in `RESULTS.md` §5 is an RTL-computed observation over synthetic preload
content, not a checked expectation.

### Zero weight / episode mutation — verified structurally, not by absence of a call

`a7ng_ddr_wavefront_top` exposes only the AXI **read** master (`m_axi_ar*` / `m_axi_r*`); it has no
`AW`/`W`/`B` ports and no weight or episode memory. No learning, persist or writeback module is in
the compile list (`ddr_wavefront_xsim.prj`). Zero weight writes and zero episode mutation hold by
construction on this gate, and the conservation ledger (E1–E5 = 1 in 4/4) independently shows the
record population is neither grown nor mutated.

No teacher, external-LLM, `learn`, `freeze` or hint port exists anywhere in the audited RTL/TB.

## 2. Law freeze — independently recomputed, not taken on trust

`Get-FileHash -Algorithm SHA256` re-run by this auditor; every value reproduces
`FROZEN_VERIFY.md` / `frozen_sha_verify.txt`:

| File | SHA256 | Verdict |
|------|--------|---------|
| `a7ng_ddr_feed_pp.sv` | `1FB685BD…4637` | MATCH (MIG-METRIC-00) |
| `a7ng_ddr_feed_axi_bridge.sv` | `D07A9742…8454` | MATCH |
| `topk/a7ng_topk.sv` | `F671FCB1…7636` | MATCH (`a7ng-topk-global-v1`) |
| `scorer/a7ng_termgen_array.sv` | `5A869703…93F7` | MATCH (`a7ng-termgen-v0`) |
| `scorer/a7ng_scorer_array.sv` | `57F3F8B1…73C7` | MATCH (`a7ng-scorer-v0`) |
| `pkg/a7ng_pkg.sv` | `267E5CF1…5959B` | MATCH |
| `memory/a7ng_mem_schema_v1.sv` | `F0FE426E…EB85` | MATCH |
| `mig.prj` | `870FA6EE…190D` | MATCH, `PortInterface=AXI`, `hand_edit=NO` |
| `build/out/arty_a7_lm06.bit` | `67C37DD5…E3BA` | MATCH (LM-06 frozen) |
| `build/out/arty_a7_eam02m.bit` | `DB3BC58A…E696` | MATCH (02M frozen) |
| `build/out/arty_a7_eam01r.bit` | `57D1DF1B…F6CF` | MATCH (01R frozen) |
| `a7ng_cue_wave_stage.sv` | `5D3D0EAE…5A10` | **NEW** |
| `a7ng_ddr_wavefront_top.sv` | `E6DDD67A…B2E4` | **NEW** |

01R law, HIT_MAX, TermGen, Top-K, relation law, learning/training law, encoder, LM-06, 02M, HNSW and
NTDE are untouched: two new files only, and the compile list contains no encoder / HNSW / NTDE /
LM-06 / 02M source. The compile list names `tb_a7ng_ddr_wavefront.sv` and neither
`a7ng_cue_wavefront.sv` nor `tb_a7ng_wavefront_mig.sv` — the authoritative and uncited sets did not
cross-contaminate.

## 3. Is the wave stage a search-law change disguised as buffering? — No

| Property | Basis |
|----------|-------|
| No candidate dropped or pruned | E3 `accepted == dispatched + resident + 0`; E5 `dispatched == received == 64`; 4/4 patterns |
| No reorder within a bank | RTL `struct_mismatch` (strictly increasing `node_id` per bank) = 0 |
| Bank identity holds | RTL `bank_map_err` (emitted `node_id[3:0] == bank`) = 0 |
| No reorder across lanes | TB checks exact identity `exp_id = base + wave_index·16 + lane` **and** the cue on all 16 lanes at consumption; `tb_wave_mismatch = 0`, 4/4 |
| Ranking cannot be moved by buffering — *structural reason, not just observation* | Lane index is content-determined (`bank = node_id[3:0]`), and `a7ng_topk.beats()` orders by (score desc, `node_id` asc, lane asc). Every term is a function of candidate content/id; none is a function of arrival time, burst depth or throttle. Empirically Top-1 = `57 / 165` in 4/4 patterns. |
| Delivery widened, not re-ranked | `jobs_per_emit_cycle = 16.0000`; DDR traffic byte- and burst-identical to the MIG-METRIC-00 control (1024 B / 64 and 1024 B / 16) |

**Residual risk (declared, not a violation here):** `a7ng_topk` in this top is a **per-batch** 16→8
network with no cross-wave reduction (`topk_batches = 4`; `top1_*` is the *last* batch). The wave
**partition** therefore decides which candidates compete. Under this gate's sequential `node_id`
stream the partition is fixed (ids 0–15, 16–31, …) independent of burst/throttle, which is why no
ranking effect is observable. With a residue-skewed or non-sequential id stream, wave membership
becomes arrival-interleaving dependent, and emit-requires-all-16-banks would additionally stall
until `flush`. `RESULTS.md` §5 and CLOSEOUT L9 correctly label the Top-1 result an observation and
decline Top-K credit, so no claim is invalidated — but the partition must be declared as law before
any retrieval or answer claim rides through this stage.

## 4. Teacher / external LLM / answer key on an inference path

None. No teacher, external-LLM, hint or answer port exists in the audited RTL or TB; no
prompt→answer mapping, no expected-answer literal, no test-string special case. Anti-hardcode greps
(`expected` / `answer` / `lookup` / `winner` / `addr` / `way` / `hash` / `grad` / `delta` /
`if…==…return`) over both new RTL files and the TB return no data-path hit; the only `expected*`
identifiers in the wider set are AXI beat-count expectations (`expected_records_o`), i.e. traffic
measurement.

## 5. Evidence class

`A7NG_DDR_WAVEFRONT_XSIM_PASS` at `xsim_ddr_wavefront.log:5498`, preceded by four `PATTERN_PASS`
lines (3681 / 4275 / 4886 / 5497). No `PATTERN_FAIL`, no `WF_MISMATCH_DBG`. Verdict `PASS_NARROW`,
`Evidence_class = MIG_XSIM_WAVEFRONT`, `COM12=NOT_PROGRAMMED`, `board_r2_rdb_latch=NOT_TOUCHED`.
No BOARD_PASS, no silicon-bandwidth claim (the MB/s table is labelled XSim-`ui_clk`-derived), no
Native V1 claim, no §14 box claimed. AI does not declare BOARD_PASS anywhere in the archive.

## 6. MINOR findings (not HLB violations)

**[MINOR-1] `drop_o` from the ping/pong is captured and discarded.**
`rtl/native_graph/memory/a7ng_ddr_wavefront_top.sv:115,135` — `pp_drop` is wired to
`u_pp.drop_o` and never exported or checked. A silent loss would only surface indirectly through
E2/E5. Harmless here (E2/E5 = 1 in 4/4), but export it before `lm06_wm_00`, where a writeback path
makes loss consequential.

**[MINOR-2] The UNCITED set grew a second closeout and a second PASS marker for the same gate id.**
`PINGPONG16/CLOSEOUT.md` (`PASS_NARROW`, marker `A7NG_DDR_WAVEFRONT00_XSIM_PASS`) and
`PINGPONG16/preflight_smoke.log` (`A7NG_WAVEFRONT_SMOKE_PASS`) were written **after** the authority
decision and after the authoritative `CLOSEOUT.md`. `AUTHORITY_DDR_WAVEFRONT_ARTIFACTS.md` does not
name them, so `ddr_wavefront_00` currently has two closeouts and three distinct PASS markers on
disk. The HLB content of that closeout is itself clean (it explicitly denies host-supplied
addresses), so this is a **citation hazard against the orchestrator**, not a boundary breach.
Recommend the parent extend the authority doc to name `PINGPONG16/CLOSEOUT.md`,
`A7NG_DDR_WAVEFRONT00_XSIM_PASS` and `A7NG_WAVEFRONT_SMOKE_PASS` as UNCITED.

## 7. Boundary risks recorded for `lm06_wm_00`

- **R1 — batch partition as search law.** Per-batch-only Top-K plus a content-addressed bank map
  means wave membership is a ranking-relevant choice for any non-sequential candidate stream.
  `lm06_wm_00` (or any successor carrying a retrieval/answer claim through this stage) needs either
  a cross-wave global reduction or an explicit declared `law_id` for the partition.
- **R2 — bit-exact control must be a recorded artifact, not a live host recompute.** Compare the
  candidate against outputs captured from frozen LM-06 (`arty_a7_lm06.bit`, `67C37DD5…E3BA`) before
  the candidate runs. A host that computes the expected token or logit at compare time is a
  next-token-on-host violation even when it is labelled "control".
- **R3 — the zero-write guarantee is structural here and will not survive.** This gate writes
  nothing because the DUT has no AXI write channel. Once WM tiles are writable, `lm06_wm_00` must
  prove EVAL writes == 0 from per-phase write counters, not from port or call absence.
- **R4 — do not inherit the `{cue, cue}` replication.** CLOSEOUT L7: the 32-bit NodeRecordV1 cue is
  replicated to the 64-bit TermGen bus. Reusing that wiring anywhere that scores real cues halves
  the cue entropy and would make a semantic retrieval number meaningless.
- **R5 — the carry-in working-set number is a non-saturating measurement.** 22 entries / 176 B peak
  and the 3 KiB declared bound come from sequential access, TOTAL = 64, no relation/edge traffic, no
  writeback, and `bank_full_stall = buffer_full_stall = 0` (L2/L5/L6). The recommended 4 entries/bank
  is a declared 4× margin over a workload that never filled the buffer — treat it as a starting
  budget, not a proven bound.

## 8. Parameter accounting (kept strictly separate — never summed)

| Quantity | Value on this gate |
|----------|--------------------|
| `P_LM` | 802816 — untouched (LM-06 frozen, bit SHA MATCH) |
| `P_encoder` | 9216 — untouched (encoder lane PARKED; not in compile list) |
| `P_total_trainable` | unchanged; this gate trains nothing and writes no weight |
| `N_episodes` | 0 exercised — no episode memory in this path |
| `episode_storage` | not exercised |
| `index_storage` | not exercised |

The gate's 256-entry / 2 KiB cue banks and 1 KiB ping/pong (3 KiB declared, 176 B measured peak) are
**candidate-delivery buffers** — neither parameters nor episodes. `RESULTS.md`, `CLOSEOUT.md` and
`PREREGISTER.md` keep them separate and do not add them into any parameter or episode headline; no
summed-total text was found to flag.
