# HLB Audit — A-FAST-LM-BOARD-LANE-00 (VERIFY_ONLY)

**Auditor:** `a7-hlb-auditor`  
**Date:** 2026-08-24  
**Worktree:** `D:\Jetking_sem4\SEM_4\arty-a7-online-lm-board`  
**Evidence class:** `XSIM_FAST_CAUSAL` / `PASS_NARROW`  
**Scope:** Class A fast causal path — `tb_a7ng_native_v1_ab_fast.sv` → `a7ng_native_v1_ab_core.sv` → bind → TinyGPT (`SIM_FULL=1`)

---

## Verdict

**HLB: CLEAN** (0 violations)

**Gate HLB: PASS**

---

## Question

If all host/TB authority were deleted at `exam=1`, would the claim *“live SOA → global Top-8 → accepted bind → TinyGPT forward produces `pred=664` with zero exam-time weight writes and clean dual-owner”* still be true?

**Answer:** Yes, for the narrow XSim causal claim. No host Python participates. TB supplies only pre-exam memory/weight setup and post-hoc metric checks; the credited Top-8, context capture, and token prediction are produced inside RTL.

---

## Files audited

| File | Role |
|------|------|
| `tests/xsim/tb_a7ng_native_v1_ab_fast.sv` | Sole “host” surface (SV TB) |
| `rtl/native_graph/integrate/a7ng_native_v1_ab_core.sv` | SOA + arb + bind mux + TinyGPT integration |
| `rtl/native_graph/lm/a7ng_native_ctx_bind.sv` | Accepted-packet capture FSM |
| `rtl/native_graph/integrate/a7ng_lm_graph_arb.sv` | LM/graph grant + `dual_owner_err_o` |
| `results/A7-NATIVE-GRAPH/A-FAST-LM-BOARD-LANE-00/xsim_fast.log` | Runtime counters |
| `results/A7-NATIVE-GRAPH/A-FAST-LM-BOARD-LANE-00/PREREGISTER.md` | Falsifiers / scope |

**No Python host, UART decoder, or board runtime** in this gate’s evidence path.

---

## Forbidden compute — exam window (`exam=1`)

| Forbidden | Present? | Evidence |
|-----------|----------|----------|
| Gradient / weight delta | **No** | `a7ng_native_v1_ab_core.sv:191` ties `start_train/start_ce/start_corpus` to `0`; TB `mem_we` never asserted (only init `1'b0`, line 282) |
| EAM/graph winner choice | **No** | Bind GID mux takes `topk_id_o` from live SOA reducer (`ab_core.sv:124`); TB does not drive `topk_id` inputs |
| BRAM/DDR record address | **No** | TB never assigns `mem_addr` / `mem_wdata`; no runtime address injection |
| 64-bit cue generation for bind | **No** | `ctx_pack` built in `a7ng_native_ctx_bind` from latched `global_id_i[7:0]` bytes (`ctx_bind.sv:43–47,78`) |
| Next-token / answer on host | **No** | `pred` is DUT output `pred_o`; TB only compares after `bind_done` |
| Semantic hint at compare time | **No** | `aos_global_top8_id()` / expected pack used as **checkers only**; not wired into bind or LM |

---

## Dynamic guards (from `xsim_fast.log`)

| Metric | Required | Observed | Status |
|--------|----------|----------|--------|
| `dual_owner_err` / `dual_ticks` | 0 | 0 | **PASS** |
| `mem_we_exam` | 0 | 0 | **PASS** |
| Poison adversarial capture | `ctx_pack` latched pre-poison | `CAPTURE_OK pack=3b392b291b190b09` after `poison_id=255` | **PASS** |
| `pred` | 664 (FPGA) | 664 | **PASS** |
| `start_fwd_beats` | 1 | 1 | **PASS** |
| PASS marker | present | `A_FAST_LM_BOARD_LANE_XSIM_PASS pred=664` | **PASS** |

Poison sequence matches HS22 R2 law: `final_accept` → posedge → negedge → live-bus poison → S_CTX sample proves capture register immunity (`tb` lines 395–414; `ctx_bind.sv:77–87`).

---

## Bind / core path review

```
SOA (u_soa) --topk_id_o[8]--> bind_gid mux --global_id_i--> a7ng_native_ctx_bind
                                    ^ poison_i (TB adversarial only, post-accept)
                                    |
                         captured_pack @ start_i (S_IDLE)
                                    |
                         ctx_we / ctx_pack / start_fwd --> tiny_gpt803k_core
```

- **No TB port for bind GID.** PREREG falsifier satisfied; TB prints `STRUCTURAL TB_DOES_NOT_DRIVE_BIND_OR_TOP8_INJECTION`.
- **`final_accept_o = start_pulse`** (`ab_core.sv:130`) fires when 4th global merge completes and `do_lm_i=1`; capture occurs on that pulse before poison.
- **`req_lm` held through bind** (`ab_core.sv:137`) — prevents grant hole that voided earlier R3/R4 captures.
- **`dual_owner_err_o`** is structurally unreachable (`a7ng_lm_graph_arb.sv`: `owner_is_graph && owner_is_lm`).

---

## Host/TB payload classification

| Field / action | When | Classification | Credits FPGA? |
|----------------|------|----------------|---------------|
| `preload_soa_planes()` — ID/cue/prior bytes into AXI stub | Pre-exam | **SUPERVISION** (dataset load) | No — memory image only |
| `$readmemh("a7lm06_wmem.hex", …)` | Pre-exam, `exam=0` | **SUPERVISION** (frozen weight init) | No — one-time backdoor |
| `q_query_cue_i` … `q_path_cue_i` (static 64b) | Wired at elaboration | **TOKENIZE / QUERY BYTES** | No — SOA query input |
| `start_query_i`, `do_lm_i`, `burst_i`, `outstanding_i`, `base_node_i`, `total_recs_i` | Exam | **MODE / TRAFFIC FLAGS** | No |
| `mem_we`, `mem_addr`, `mem_wdata` | Never asserted | **N/A** | — |
| `poison_i`, `poison_id_i` | Post-accept adversarial | **TEST HARNESS** (falsifier probe) | No — must not alter captured pack |
| `aos_global_top8_id()`, expected pack `3b39…`, `pred===664` checks | Post-run | **METRIC-EVAL-ONLY** | No |
| `topk_id_o`, `ctx_pack_o`, `pred_o` | DUT outputs | **FPGA TELEMETRY** | **Yes** |

---

## Pre-exam setup (permitted, not credited)

1. **SOA plane preload** via `golden_cue32/64` — defines candidate memory contents in the behavioral DDR stub, analogous to loading a fixed retrieval corpus. Does not select the winner at runtime; SOA scorer + reducer does.
2. **Weight backdoor** — `$readmemh` before `exam=1`; preregister allows init-only load while reset/inactive. Runtime counter confirms zero exam writes.
3. **Static query cues** — five 64-bit query-side inputs to SOA term generator; not per-example answer maps.

---

## Limits (not HLB violations; scope boundaries)

- **XSim only** — no silicon, MIG PHY, UART, or host board ladder.
- **`SIM_FULL=1`** — zero-latency weight fabric substitution disclosed in PREREGISTER.
- **Not generalization** — fixed 64-candidate corpus and frozen weights; single sealed forward.
- **Not `BOARD_PASS`** — existence / causal guard for Class A integration lane.
- **Top-8 checker tables in TB** — if SOA produced wrong IDs, gate fails at SOA check before LM; this validates transport/score law, not host-supplied answers.

---

## Parameter accounting (separate; never summed into headline)

| Quantity | Value | Note |
|----------|-------|------|
| `P_LM` | 802816 | Frozen LM-06 family |
| `P_encoder` | 9216 | EAM lane; not in this compile |
| `P_total_trainable` | 802816 + 9216 | LM + encoder reference only |
| `N_episodes` | — | Not exercised this gate |
| `episode_storage` | — | Not exercised |
| `index_storage` | — | SOA stub planes (dataset), not learned index |

Episodes are memory records, not parameters. No text in this gate sums episodes into parameter headlines.

---

## Conclusion

**PASS** — Zero HLB violations for the preregistered Class A fast causal claim. Exam window shows `dual_ticks=0`, `mem_we_exam=0`, poison capture holds accepted pack, and `pred=664` originates from TinyGPT inside the DUT. Host/TB authority is limited to pre-exam setup and post-hoc evaluation counters.

**Does not substitute:** board silicon, UART release proof, teacher-off KIDI, or HS-02 semantic generalization.
