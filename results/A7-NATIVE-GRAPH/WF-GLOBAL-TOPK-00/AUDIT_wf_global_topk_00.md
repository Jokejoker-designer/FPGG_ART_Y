# AUDIT — wf_global_topk_00 (VERIFY_ONLY)

**Auditor:** `a7-evidence-auditor`  
**Mode:** READ_ONLY_AUDIT / VERIFY_ONLY (no RTL edit; no LOOP_STATE flip)  
**Date:** 2026-08-22  
**Evidence_class:** **XSIM** (not silicon, not BOARD)  
**GATE:** `wf_global_topk_00`  
**LOOP_STATE:** `next` = `wf_global_topk_00` (first OPEN — matches this audit)  
**Implementer DISPATCH:** `a7-ng-topk-frontier` / `PASS` / marker `A7NG_WF_GLOBAL_TOPK_XSIM_PASS` / law `a7ng-topk-wavefront-global-v1`

```text
MUST_READ_UNBLOCK_H5: read. Next = ungated DIFF twin (not S2, not glue).
BLUEPRINT_LOOP: read. Goal=NATIVE_V1_MINI_AI_BOARD_PASS. Next=wf_global_topk_00
```

---

## Verdict

```text
AUDIT: 4 FINDINGS
result: PASS
allow_loop_done_eng: true
result_class: PASS_NARROW
evidence_class: XSIM (accumulator unit only)
```

H_CANDIDATE (`G_(t+1)=TopK(G_t ∪ TopK(W_t))` via unchanged `a7ng_topk` 16→8) **SUPPORTED** at **accumulator-unit** scope — **EVIDENCE** (`xsim_wf_global_topk.log`, TB counterexample).  
H_RIVAL (per-wave-only suffices) **FALSIFIED** on executed counterexample — **EVIDENCE** (8/8 slot divergence logged).  
`carried_risk_r1` **partially remediated**: integration `law_id` + module + `a7ng_ddr_wavefront_top` hook present; full wavefront path **not** XSim-closed (findings below).  
**Do not declare BOARD_PASS.** **Do not claim HS-02 / retrieval / SOA ordering closed.**

---

## Dispatch law

| Check | Outcome |
|-------|---------|
| `LOOP_STATE.next` / first OPEN `wf_global_topk_00` | **PASS** |
| Last `DISPATCH_LOG.jsonl` line `gate=wf_global_topk_00` | **PASS** |
| Last line `agent=a7-ng-topk-frontier` | **PASS** — matches `run_blueprint_loop.py` mapping |
| Implementer `result=PASS` artifact `CLOSEOUT.md` | **PASS** |
| Verify trio (`a7-ng-xsim-verify`, `a7-vivado-gate`) logged | **NOT YET** — only implementer line present |
| Parent wrote RTL (void) | **PASS** — implementer agent path |

---

## Required checks

### 1. `a7ng_topk.sv` SHA unchanged vs NG-02R — **PASS**

| Artifact | SHA256 | Match |
|----------|--------|-------|
| Live `rtl/native_graph/topk/a7ng_topk.sv` | `F671FCB1B8FB891EE77A9AC3D5A0BA24AE4DBB8109A6645F2250F611AA197636` | **MATCH** |
| NG-02R `closeout.md` / `SHA256.txt` | `F671FCB1…` | **MATCH** |
| WF-GLOBAL-TOPK `SHA256.txt` | `F671FCB1…` | **MATCH** |
| `ddr_wavefront_00` DISPATCH frozen `topk_sha` | `F671FCB1…` | **MATCH** |

Comparator law `a7ng-topk-global-v1` primitive **unchanged** — **EVIDENCE** (live rehash).

### 2. XSim marker + counterexample — **PASS** (unit TB)

| Check | Outcome |
|-------|---------|
| `xsim_wf_global_topk.log` marker | `A7NG_WF_GLOBAL_TOPK_XSIM_PASS fails=0` — **EVIDENCE** |
| Per-wave-only differs (8 slots) | Logged `PASS counterexample_perwave_only` — **EVIDENCE** |
| `merge_count` after counterexample | TB expects `2`; final log `merge_count=3` includes three-wave section — consistent — **EVIDENCE** |
| Marker file `A7NG_WF_GLOBAL_TOPK_XSIM_PASS` | Present — **EVIDENCE** |

### 3. `carried_risk_r1` remediation — **PASS_NARROW**

| Remediation required (`lm06_wm_00.carried_risk_r1`) | Status |
|-----------------------------------------------------|--------|
| Global cross-wave reduction **or** integration `law_id` | `a7ng-topk-wavefront-global-v1` declared — **EVIDENCE** |
| Module `a7ng_topk_wavefront_global.sv` | Present; SHA `D6D6882B…` matches `SHA256.txt` — **EVIDENCE** |
| Wavefront integration hook | RTL in `a7ng_ddr_wavefront_top.sv` (`u_global`, `top1_*` from `gl_*`) — **ENGINEERING_INFERENCE** (not XSim-proven) |
| Counterexample non-sequential `node_id` | Executed in TB (`0xDEADBEEF` beats W1 8th) — **EVIDENCE** (unit scope) |

Per-wave-only Top-K risk is **closed for accumulator law claims**; **not closed** for end-to-end retrieval / HS-02 until integrated wavefront XSim (finding F2).

### 4. Frozen-artifact law — **PASS**

- `a7ng_topk.sv` not edited (SHA match).  
- `a7ng_ddr_wavefront_top.sv` SHA changed `E6DDD67A…` → `C1167BFC…` — **expected** for allowed global-hook edit; prior `ddr_wavefront_00` frozen SHA is superseded for integration, not silently identical.  
- No frozen LM-06 / 01R / 02M bit overwrite claimed.

### 5. HLB / forbidden PASS routes — **PASS**

- No BOARD_PASS, no silicon, no host winner/address/answer path.  
- TB expected values are harness oracle (standard); DUT computes merge via RTL `a7ng_topk`.  
- No golden edit, no skipped falsifier, no seed shopping observed.

---

## Findings (ordered by severity)

```
[MAJOR] Preregistered counterexample stream not executed as written
  where     : PREREGISTER.md:67-68 vs tests/xsim/tb_a7ng_wf_global_topk.sv:145-168
  claim      : W1 scores 200..185; W2 superstar score 190 beats W1 8th (185)
  evidence   : TB uses W1 top-8 200..130 (step −10); W2 superstar score 135 beats 130
  why it matters: preregistration is weakened; a reader cannot reproduce the documented stream from PREREGISTER alone
  fix        : update PREREGISTER counterexample table to match executed TB, or rerun with preregistered scores

[MAJOR] Integrated wavefront path not in XSim project
  where     : wf_global_topk_xsim.prj; CLOSEOUT.md:24; RESULTS.md:45
  claim      : "`a7ng_ddr_wavefront_top.sv` integration hook" closes wavefront global Top-K
  evidence   : XSim compiles only `a7ng_topk.sv` + `a7ng_topk_wavefront_global.sv` + unit TB; `a7ng_ddr_wavefront_top.sv` absent from project
  why it matters: wiring (`wave_scored_q`, `tk_valid_o` timing, `start_i` clear) is unproven; carried_risk_r1 closure is unit-level only
  fix        : add integrated TB (or extend ddr_wavefront TB) with cross-wave counterexample; archive log + SHA

[MAJOR] `lane_pop` forward reference in integrated top
  where     : rtl/native_graph/memory/a7ng_ddr_wavefront_top.sv:294 vs :314
  claim      : `wave_scored_q <= lane_pop` drives `wave_scored_i` into global accumulator
  evidence   : `lane_pop` declared after use; `DDR-WAVEFRONT-00/xvlog_ddr_wavefront.log` records VRFC 10-3380 at line 294
  why it matters: integrated hook may not compile or may pass wrong `wave_scored_i`; global valid_mask could be wrong in silicon path
  fix        : move `lane_pop` declaration/comb block above `wave_scored_q` always_ff; re-xvlog integrated top

[MINOR] Retrieval supersession overclaim in closeout
  where     : CLOSEOUT.md:35
  claim      : per-wave-only Top-K "superseded by global accumulator for retrieval claims"
  evidence   : only unit XSim + RTL hook; no full-path retrieval test
  why it matters: reader may treat HS-02 / SOA ordering as unblocked
  fix        : qualify: "for accumulator-law claims only; retrieval/HS-02 still require integrated XSim"
```

---

## Independent re-derivation (headline numbers)

| Quantity | Closeout / log | Auditor re-derive | Match |
|----------|----------------|-------------------|-------|
| `a7ng_topk.sv` SHA | `F671FCB1…` | PowerShell `Get-FileHash` | **YES** |
| XSim `fails` | `0` | `xsim_wf_global_topk.log` line 15 | **YES** |
| Counterexample W1 8th score | `130` (RESULTS) | TB `200−10×7` | **YES** |
| Global rank-8 id | `0xDEADBEEF` | TB `exp_gid[7]` | **YES** |
| `merge_count` post-counterexample | `2` (RESULTS) | TB check line 179 | **YES** |

---

## NOT VERIFIED

- Vivado re-run this audit session (`vivado` not on PATH; relied on archived `xsim_wf_global_topk.log`).
- `a7ng_ddr_wavefront_top.sv` compile / integrated XSim after global hook.
- Verify trio (`a7-ng-xsim-verify`, `a7-vivado-gate`) DISPATCH lines for this gate.
- OOC / post-route utilisation of new accumulator.
- Board silicon.
- Python oracle `global_topk_match` metric (preregistered but not implemented; TB uses hand-rolled expected arrays).

---

## Auditor disposition

| Field | Value |
|-------|-------|
| **result** | **PASS** |
| **result_class** | **PASS_NARROW** |
| **allow_loop_done_eng** | **true** |
| **evidence_class** | **XSIM** (unit `a7ng_topk_wavefront_global` only) |
| **carried_risk_r1** | **partially closed** — law + module + hook; integrated path OPEN |
| **BOARD_PASS** | **reserved** (human only) |

Parent may mark `wf_global_topk_00` **DONE_ENG** with `allow_loop_done_eng: true` and `result_class: PASS_NARROW`. Recommend dispatch integrated wavefront XSim before any retrieval / HS-02 / SOA claim.
