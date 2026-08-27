# AUDIT_EVIDENCE — A-FAST-LM-BOARD-LANE-00 (VERIFY_ONLY)

**Auditor:** `a7-evidence-auditor`  
**Date:** 2026-08-24  
**Worktree:** `D:\Jetking_sem4\SEM_4\arty-a7-online-lm-board`  
**Gate:** `native_v1_existence_board_parallel_00` Stage A  
**Evidence class:** `XSIM_FAST_CAUSAL` / `PASS_NARROW`  
**Adapted authority:** `results/A7-NATIVE-GRAPH/STATUS/E0_ACCEPTANCE_CRITERIA.md` (MIG_XSIM predicates relaxed per preregister: AXI stub, backdoor wmem, `SIM_FULL=1`)

---

## Verdict

**AUDIT: 2 FINDINGS**

**Gate verdict: PASS** (`XSIM_FAST_CAUSAL` Stage A only — not board, not `NATIVE_EXISTENCE_XSIM_PASS`, not `BOARD_PASS`)

---

## Checklist (requested)

| # | Check | Result | Basis |
|---|--------|--------|-------|
| 1 | DISPATCH_LOG / gate id alignment | **N/A** | Parallel board lane; no `A-FAST-LM-BOARD-LANE-00` or `native_v1_existence_board_parallel_00` line in board-worktree `DISPATCH_LOG.jsonl` or `LOOP_STATE.json`. Main R6 dispatch chain does not own this gate. |
| 2 | SOA transport 832/52/4, `data_mismatch=0`, Top-8 exact | **PASS** | **EVIDENCE** — re-derived from `tests/xsim/xsim.log` L34–37, L39–46 |
| 3 | CAPTURE `3b392b291b190b09`, `pred=664`, `start_fwd_beats=1` | **PASS** | Pack + pred **EVIDENCE** (L49, L731); `start_fwd_beats=1` **ENGINEERING_INFERENCE** (TB pass conjunct, see Finding 2) |
| 4 | No illegal `BOARD_PASS` claim | **PASS** | CLOSEOUT/RESULTS/PREREGISTER state `XSIM_FAST_CAUSAL`; Stage E2 deferred |
| 5 | Evidence class `XSIM_FAST_CAUSAL` not BOARD | **PASS** | Log L29, all gate docs, TB banner L290 |

---

## E0 predicates (adapted for `XSIM_FAST_CAUSAL`)

| # | Predicate | Status | Class |
|---|-----------|--------|-------|
| 1 | Live SOA producer (no TB Top-8/bind/pred injection) | **MET** | **EVIDENCE** — `STRUCTURAL TB_DOES_NOT_DRIVE_BIND_OR_TOP8_INJECTION` (L16); AXI stub per prereg (not MIG) |
| 2 | 4 AR / 52 beats / 832 B / planes 16/32/4 | **MET** | **EVIDENCE** — `SOA_DELTA` bursts=4; `SOA_PLANE id=16 cue=32 prior=4`; 52×16=832 |
| 3 | Global Top-8 `9,11,25,27,41,43,57,59` @ 165 | **MET** | **EVIDENCE** — L39–46 all `expect_id` match |
| 4 | Pack → bind → `pred=664` after one `start_fwd` | **MET** | **EVIDENCE** CAPTURE L49; **EVIDENCE** `A_FAST_LM_BOARD_LANE_XSIM_PASS pred=664` L731; `start_fwd` count **ENGINEERING_INFERENCE** |
| 5 | Negative control / perturbation | **PARTIAL** | **EVIDENCE** pre-LM `NEG_CHECK pred=0 start_fwd_beats=0` (L48); no post-pass perturbation run (acceptable for Stage A prereg; full anti-hardcode perturbation deferred) |
| 6 | `dual_owner_err=0`, exam `mem_we=0` | **MET** | **ENGINEERING_INFERENCE** — TB emits pass only if `dual_ticks===0 && mem_we_exam===0` (`tb_a7ng_native_v1_ab_fast.sv:434`) |
| 7 | Frozen wmem SHA | **MET** | **EVIDENCE** — live `a7lm06_wmem.hex` SHA256 `9A6BBC7AC8AF82725CAFD0B50241EE683C07FB9943C754753025F3569967D10F` matches PREREGISTER |
| 8 | Backdoor wmem only (no R2-class live stall) | **MET** | **EVIDENCE** — `LM06_WMEM_BACKDOOR_DONE` (L18); sim elapsed ~6m40s (L733); no hang |

---

## Re-derived headline numbers (auditor, not trusting summary)

Source: `tests/xsim/xsim.log` (matches archived `xsim_fast.log` at pass markers).

```text
SOA_DELTA axi_read_bytes=832 axi_read_beats=52 bursts=4 gv=4 topk_updates=4
SOA_DATA_MISMATCH=0
SOA_GLOBAL_TOP8[0..7] id=9,11,25,27,41,43,57,59 score=165 (all expect_id match)
CAPTURE_OK pack=3b392b291b190b09
SMX t=182025265000 logit0=1310985
A_FAST_LM_BOARD_LANE_XSIM_PASS pred=664
```

Arithmetic check: 832 ÷ 52 = 16 B/beat (consistent with preregister burst geometry).

No `A_FAST_LM_BOARD_LANE_FAIL`, `ERROR`, or `BOARD_PASS` strings in `xsim.log`.

---

## Findings

### [MINOR] Preregister seal file absent

```
where     : results/A7-NATIVE-GRAPH/A-FAST-LM-BOARD-LANE-00/PREREGISTER.md:49
claim      : "Seal SHA: compute after file write → PREREGISTER_SEAL_SHA256.txt"
evidence   : `PREREGISTER_SEAL_SHA256.txt` not present under gate results dir
why it matters: Run timestamp vs prereg content cannot be independently bound; weakens pre-run seal law for parallel lane
fix        : Write `PREREGISTER_SEAL_SHA256.txt` from frozen PREREGISTER bytes (retroactive seal with explicit date note) or amend prereg to record why seal waived for board lane
```

### [MINOR] Post-pass counters reported without evidence class labels

```
where     : CLOSEOUT.md:16; RESULTS.md:25–26
claim      : `start_fwd_beats=1`, `dual_ticks=0`, `mem_we_exam=0` as table facts
evidence   : Log prints `NEG_CHECK ... start_fwd_beats=0` pre-LM (L48); pass marker omits `st_beats`/`dual_ticks`/`mem_we_exam`. Values hold only because TB pass branch requires them (tb:434–435)
why it matters: Unlabelled quantitative claims read as log-evidenced; reader may think counters were printed at pass
fix        : Label these **ENGINEERING_INFERENCE (TB pass conjunct)** or add explicit `$display` at pass time
```

---

## Forbidden routes — searched, not found

- Golden/expected values edited to match broken SOA (fix is RTL field-split, log shows zero mismatch before LM)
- Tests skipped/weakened (full forward ~18.2M cycles; heartbeat lines present)
- Host winner/next-token path (HLB audit `AUDIT_HLB.md` — CLEAN; no Python)
- XSim described as board/silicon (docs consistently `XSIM_FAST_CAUSAL`)
- `BOARD_PASS` or `NATIVE_V1_MINI_AI_BOARD_PASS` declaration

---

## Cross-auditor notes

- `AUDIT_XSIM.md` (`a7-ng-xsim-verify`): PASS — consistent with this audit.
- `AUDIT_HLB.md` (`a7-hlb-auditor`): HLB CLEAN — no conflict.

---

## NOT VERIFIED

- **DISPATCH_LOG alignment** — parallel board lane intentionally outside R6 `LOOP_STATE` queue; no dispatch line to match.
- **`PREREGISTER_SEAL_SHA256.txt`** — file missing (Finding 1).
- **RTL authorship / Task vs parent chat** — not git-blamed this turn; xsim-verify structural read only.
- **Cherry-pick of `a7ng_cue_soa_wavefront.sv` to R6 main tree** — out of Stage A evidence scope (CLOSEOUT “Next” item).
- **MIG / bitstream / COM12 board run** — explicitly forbidden for Stage A; Stage E2 not attempted.

---

## Gate close recommendation

**PASS** for `A-FAST-LM-BOARD-LANE-00` Stage A (`XSIM_FAST_CAUSAL` / `PASS_NARROW`).

Does **not** authorize Stage E2 board programming, `NATIVE_EXISTENCE_XSIM_PASS`, or any `BOARD_PASS` claim. Human/Codex `ALLOW_PROGRAM` remains required for physical lane per CLOSEOUT and `PROMPT_CURSOR_PARALLEL_BOARD_LANE.md`.
