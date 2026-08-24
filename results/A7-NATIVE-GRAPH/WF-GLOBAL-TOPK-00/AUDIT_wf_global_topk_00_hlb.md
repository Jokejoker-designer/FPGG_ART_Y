# HLB AUDIT — gate `wf_global_topk_00` (VERIFY_ONLY)

**Auditor:** `a7-hlb-auditor` · **Mode:** VERIFY_ONLY (no RTL/TB/TCL edited)
**Verdict:** `HLB: CLEAN` — **0 violations**, 3 MINOR findings, 2 recorded risks for downstream gates
**Scope lock:** `results/A7-NATIVE-GRAPH/WF-GLOBAL-TOPK-00/` (PREREGISTER, RESULTS, CLOSEOUT, XSim log, SHA256)
**Audited set:** `a7ng_topk_wavefront_global.sv`, `a7ng_ddr_wavefront_top.sv` integration hook, `tb_a7ng_wf_global_topk.sv`, `run_a7ng_wf_global_topk.tcl`
**Evidence class:** `XSIM` — simulation only, **not BOARD**

## 1. Host / winner-injection boundary

**There is no host on this gate's runtime path.** The only host-side artifact is
`tests/xsim/run_a7ng_wf_global_topk.tcl`, which compiles RTL, runs XSim, and string-matches the
marker. It carries no data into the DUT and computes no Top-K result.

No Python file participates in this gate. Grep over `python/native_graph/` finds no
`global_topk`, `wavefront_global`, or board UART payload for Top-K. `train_v2_harness.py` computes
`top1_hits` / `topk_recall` inside a separate HARNESS evidence class and is **not cited** by this
gate's archive; it does not touch `a7ng_topk_wavefront_global` or drive board payloads.

### Production data path (FPGA-only global Top-K)

```text
Per wave (unchanged, FPGA):
  DDR read → cue_wave → 16× TermGen → 16× scorer → a7ng_topk (16→8) = TopK(W_t)

Cross-wave (new, FPGA):
  a7ng_topk_wavefront_global:
    G_(t+1) = TopK( G_t ∪ TopK(W_t) )   via frozen a7ng_topk 16→8 on slots 0..7 = G_t, 8..15 = W_t
```

Integration wiring (`a7ng_ddr_wavefront_top.sv:275-309`):

| Signal | Source | Class |
|--------|--------|-------|
| `wave_valid_i` | `tk_valid_o` (per-wave `a7ng_topk`) | FPGA telemetry |
| `wave_scored_i` | `wave_scored_q` (lane pop count from `sc_valid_o`) | FPGA telemetry |
| `wave_score_i[]` / `wave_id_i[]` | `tk_score_o[]` / `tk_id_o[]` (per-wave top-8) | FPGA-computed |
| `clear_i` | `start_i` (query boundary reset) | MODE |
| `global_score_o[]` / `global_id_o[]` | `u_global` accumulator | FPGA-computed |
| `top1_id_o` / `top1_score_o` | `gl_id_o[0]` / `gl_score_o[0]` when `gl_valid_o`, else per-wave fallback | FPGA-computed (see MINOR-1) |

**No external port accepts a pre-ranked list, winner id, address, way, hash, gradient, or weight.**
The accumulator module exposes only clock, reset, clear, and per-wave top-8 inputs that, in
integration, originate from the on-chip scorer→topk chain — never from a host.

### Unit-test oracle vs host injection

`tb_a7ng_wf_global_topk.sv` drives `wave_score_i` / `wave_id_i` directly into the isolated DUT.
This is **test stimulus for the accumulator primitive**, analogous to `tb_a7ng_topk.sv` driving
synthetic scores. Expected values (`exp_g`, `exp_gid`) are checked only against DUT **outputs**
(`global_score_o`, `global_id_o`); they are never wired back into DUT inputs. Deleting the
testbench would not change what the RTL computes; it would only remove the proof.

The `ddr_wavefront` integration TB (`tb_a7ng_ddr_wavefront.sv`) reads `top1_id_o` /
`global_topk_*` as `WF_DIAG` only (line 464–465); it does **not** assert global Top-K against an
expected winner and does not inject any rank back into the DUT.

### Host→board payload surface (this gate)

| Field | Present on gate? | Class |
|-------|------------------|-------|
| UART / host command payload | **No** | — |
| Precomputed winner / top-k list | **No** | — |
| Record address / way / hash | **No** | — |
| Gradient / weight delta | **No** | — |
| Query cue bytes (ddr_wavefront context) | Constant 64-bit literals in ddr_wavefront TB only; not part of wf_global_topk_00 XSim gate | QUERY-CONTEXT (out of scope for this unit gate) |

## 2. Global Top-K is FPGA-computed — structural proof

`a7ng_topk_wavefront_global.sv` implements the preregistered recurrence
`G_(t+1) = TopK(G_t ∪ TopK(W_t))`:

1. **State:** `g_score[]`, `g_id[]`, `g_valid[]` held in registers (lines 28–30, 147–152).
2. **Merge:** Concatenates `G_t` (slots 0–7, mask from `g_valid`) with latched `TopK(W_t)` (slots
   8–15, mask from `wave_slot_mask(wave_n_lat)`) and feeds unchanged `a7ng_topk #(.N(16),.K(8))`
   (lines 41–46, 80–93).
3. **Primitive law:** Comparator order is delegated entirely to frozen `a7ng_topk` (`a7ng-topk-global-v1`:
   score desc, `node_id` asc, lane asc). No host-side reordering.

XSim evidence (`xsim_wf_global_topk.log`):

- `PASS counterexample_perwave_only per-wave-only differs from global (8 slots)` — falsifier F2
  (per-wave-only must not match global) satisfied.
- `A7NG_WF_GLOBAL_TOPK_XSIM_PASS fails=0 merge_count=3` — rank-9 `0xDEADBEEF` score 135 enters
  `G_final` slot 7, displacing W1 8th (130); non-sequential `node_id` stream.

**If host code were deleted, the claim "global Top-K is computed in FPGA via
`G_(t+1)=TopK(G_t ∪ TopK(W_t))`" remains true** — it is an RTL structural claim proved by XSim,
not attributed to any host oracle.

## 3. Law freeze

SHA256 from `SHA256.txt`, independently consistent with NG-02R closeout:

| File | SHA256 (prefix) | Verdict |
|------|-----------------|---------|
| `a7ng_topk.sv` | `F671FCB1…7636` | MATCH — comparator law **unchanged** |
| `a7ng_topk_wavefront_global.sv` | `D6D6882B…B7B` | NEW (this gate) |
| `a7ng_ddr_wavefront_top.sv` | `C1167BFC…E912` | NEW hook — integration only |
| `tb_a7ng_wf_global_topk.sv` | `98DD3CE1…C17` | NEW |

Frozen artifacts not touched: 01R, HIT_MAX, TermGen, scorer, LM-06, 02M, encoder, `mig.prj`,
training law.

## 4. Teacher / EVAL / weight writes

Not applicable on this gate path:

- No teacher, external-LLM, `learn`, `freeze`, or hint port in audited RTL.
- No weight or episode memory; no AXI write path in `a7ng_ddr_wavefront_top`.
- Zero weight writes and zero episode mutation hold by construction.

## 5. Anti-hardcode grep (audited files)

Patterns `winner`, `lookup`, `expected.*answer`, `if.*==.*return` (data-path),
`gradient`, `delta`, host-injected `addr`/`way`/`hash` over:

- `rtl/native_graph/topk/a7ng_topk_wavefront_global.sv`
- `rtl/native_graph/memory/a7ng_ddr_wavefront_top.sv` (integration section)
- `tests/xsim/tb_a7ng_wf_global_topk.sv`

**No VIOLATION hits.** `expected` in the unit TB refers to post-hoc oracle comparison of DUT
outputs, not injected answers. `tb_a7ng_ddr_wavefront.sv` `expected_records_o` is AXI beat-count
traffic measurement (out of gate scope).

## 6. Evidence class and claim narrowness

| Claim | Allowed? | Basis |
|-------|----------|-------|
| Cross-wave global Top-8 recurrence correct on preregistered counterexample | **YES (XSim)** | `A7NG_WF_GLOBAL_TOPK_XSIM_PASS` |
| Closes `carried_risk_r1` for retrieval **architecture** | **YES (narrow)** | Global accumulator wired; per-wave-only path superseded in RTL |
| BOARD_PASS / silicon retrieval | **NO** | Not run; CLOSEOUT and RESULTS explicitly deny |
| End-to-end DDR wavefront global Top-K regression | **NO** | `ddr_wavefront_00` TB does not gate-check `global_topk_*` |
| HS-02 / metadata-after-G_final ordering | **NO** | Declared non-gate in PREREGISTER |

## 7. MINOR findings (not HLB violations)

**[MINOR-1] `top1_id_o` per-wave fallback before first global merge completes.**
`a7ng_ddr_wavefront_top.sv:327-328` — when `!gl_valid_o`, `top1_id_o` reverts to `tk_id_o[0]`
(last per-wave top-1). This is FPGA-local muxing, not host injection, but any downstream consumer
sampling `top1_*` before `global_topk_valid_o` asserts would observe per-wave-only rank. Document
or gate on `global_topk_valid_o` before retrieval claims.

**[MINOR-2] PREREGISTER metric `global_topk_match` names a Python oracle; none exists on disk.**
Verification was performed in SV TB with hand-derived expected arrays. Not a boundary breach (oracle
is not in the runtime path), but the metric name in PREREGISTER overstates what was executed.

**[MINOR-3] `ddr_wavefront` integration compiles global accumulator but does not regression-test it.**
`run_a7ng_ddr_wavefront.tcl` includes `a7ng_topk_wavefront_global.sv`; `tb_a7ng_ddr_wavefront.sv`
only logs `global_merge_count_o` / `top1_id_o` as diagnostics. Full MIG+global-Top-K co-verification
remains a future gate if end-to-end retrieval credit is sought.

## 8. Boundary risks recorded for downstream gates

- **R1 — `global_topk_valid_o` gating.** Consumers must not treat `top1_*` as final until global
  merge completes for the query; otherwise per-wave leakage reopens `carried_risk_r1` at the
  observability layer even though RTL accumulates correctly.
- **R2 — Metadata fetch ordering.** PREREGISTER and GLOBAL_TOPK_REVIEW require metadata fetch only
  after `G_final`. A host or RTL path that prefetches metadata on per-wave winners would violate
  retrieval law and waste DDR bandwidth; not present here but mandatory for DDR-CUE-SOA / HS-02.

## 9. Parameter accounting (kept strictly separate — never summed)

| Quantity | Value on this gate |
|----------|--------------------|
| `P_LM` | 802816 — untouched (LM-06 frozen) |
| `P_encoder` | 9216 — untouched (encoder lane not in compile list) |
| `P_total_trainable` | unchanged; gate trains nothing |
| `N_episodes` | 0 exercised |
| `episode_storage` | not exercised |
| `index_storage` | not exercised |

No text in the archive sums episodes or buffer bytes into parameter headlines.

---

## Verdict

**HLB: CLEAN** (0 violations)

**Gate HLB verdict: `PASS_NARROW`**

Global Top-K across waves is computed entirely inside FPGA RTL (`a7ng_topk_wavefront_global` +
frozen `a7ng_topk`). No host injects winners, addresses, or ranks. Scope is XSim unit proof plus
integration wiring only — not board, not end-to-end DDR regression, not HS-02.
