# AUDIT — wf_global_topk_integrated_00 (VERIFY_ONLY)

**Auditor:** `a7-evidence-auditor`  
**Mode:** READ_ONLY_AUDIT / VERIFY_ONLY (no RTL edit; no LOOP_STATE flip)  
**Date:** 2026-08-22  
**Evidence_class:** **MIG_XSIM_WAVEFRONT_INTEGRATED** (not silicon, not BOARD)  
**GATE:** `wf_global_topk_integrated_00`  
**LOOP_STATE:** `next` = `descriptor_contract_00` (gate already `DONE_ENG`; auditor verify completes here)

```text
MUST_READ_UNBLOCK_H5: read. Next = ungated DIFF twin (not S2, not glue).
BLUEPRINT_LOOP: read. Goal=NATIVE_V1_MINI_AI_BOARD_PASS. Next=descriptor_contract_00
```

---

## Verdict

```text
AUDIT: 2 FINDINGS
result: PASS_NARROW
allow_loop_done_eng: true
evidence_class: MIG_XSIM_WAVEFRONT_INTEGRATED
carried_risk_r1: CLOSED (integrated wavefront path only)
```

H_CANDIDATE (integrated `a7ng_ddr_wavefront_top` + `a7ng_topk_wavefront_global` preserves cross-wave Top-8) **SUPPORTED** — **EVIDENCE** (`xsim_wf_global_topk_integrated.log`, integrated TB).  
H_RIVAL (per-wave-only suffices) **FALSIFIED** on executed counterexample — **EVIDENCE** (8/8 slot divergence logged).  
Prior `wf_global_topk_00` **3 MAJOR** findings **closed** (see below).  
**Do not declare BOARD_PASS.** **Do not claim HS-02 / retrieval / SOA ordering closed.**

---

## Dispatch law

| Check | Outcome |
|-------|---------|
| Last `DISPATCH_LOG.jsonl` line `gate=wf_global_topk_integrated_00` | **PASS** |
| Last line `agent=a7-ng-topk-frontier` | **PASS** — matches `run_blueprint_loop.py:61` |
| Implementer `result=PASS` artifact `integrated/CLOSEOUT.md` | **PASS** |
| `LOOP_STATE` entry `wf_global_topk_integrated_00` status `DONE_ENG` | **PASS** |
| Verify trio independent dispatch (`a7-ng-xsim-verify`) | **NOT LOGGED** — relied on archived integrated log |
| Parent wrote RTL (void) | **PASS** — implementer agent path |

---

## Prior auditor MAJOR fixes (`AUDIT_wf_global_topk_00.md`)

| Prior finding | Status | Evidence |
|---------------|--------|----------|
| **MAJOR** PREREGISTER counterexample stream mismatch | **CLOSED** | `PREREGISTER.md:71-77` now documents integrated TB table separately from unit TB |
| **MAJOR** Integrated wavefront path not in XSim | **CLOSED** | `wf_global_topk_integrated_xsim.prj` includes `a7ng_ddr_wavefront_top.sv` + MIG; marker `A7NG_WF_GLOBAL_TOPK_INTEGRATED_XSIM_PASS` |
| **MAJOR** `lane_pop` forward reference | **CLOSED** | `a7ng_ddr_wavefront_top.sv:287-301` — `lane_pop` comb before `wave_scored_q` always_ff; `xvlog_wf_global_topk_integrated.log` has no VRFC 10-3380 |

---

## Required checks

### 1. `a7ng_topk.sv` SHA unchanged vs NG-02R — **PASS**

| Artifact | SHA256 | Match |
|----------|--------|-------|
| Live `rtl/native_graph/topk/a7ng_topk.sv` | `F671FCB1B8FB891EE77A9AC3D5A0BA24AE4DBB8109A6645F2250F611AA197636` | **MATCH** |
| `integrated/SHA256.txt` | `F671FCB1…` | **MATCH** |
| NG-02R frozen SHA | `F671FCB1…` | **MATCH** |

Comparator law `a7ng-topk-global-v1` primitive **unchanged** — **EVIDENCE** (live rehash).

### 2. Integrated XSim marker + counterexample — **PASS**

| Check | Outcome |
|-------|---------|
| `xsim_wf_global_topk_integrated.log` marker | `A7NG_WF_GLOBAL_TOPK_INTEGRATED_XSIM_PASS fails=0 merge_count=2` — **EVIDENCE** |
| Marker file `A7NG_WF_GLOBAL_TOPK_INTEGRATED_XSIM_PASS` | Present — **EVIDENCE** |
| W1 8th displaced (`id=10@161`) | Log line `PASS integrated_global w1_8th id=10@161 displaced` — **EVIDENCE** |
| Per-wave-only differs | `PASS integrated_perwave_only differs from global (8 slots)` — **EVIDENCE** |
| `merge_count` | TB expects `2`; log `merges=2` / `merge_count=2` — **EVIDENCE** |
| `beat_mm` | TB fails if `beat_mm != 0`; no FAIL in log; DISPATCH `beat_mm=0` — **EVIDENCE** (silent pass) |
| Candidate conservation | `scored=32 waves=2` in `WFGI_DIAG` — **EVIDENCE** |
| Log SHA vs manifest | `213D17AD8BD17B37FD83D5B7BD296486D981CF09464DADF76FC868B5D5E1C4C7` — **MATCH** `SHA256.txt` |

### 3. `carried_risk_r1` — **CLOSED (PASS_NARROW scope)**

| Requirement (`lm06_wm_00.carried_risk_r1`) | Status |
|--------------------------------------------|--------|
| Global cross-wave reduction **or** integration `law_id` | `a7ng-topk-wavefront-global-v1` — **EVIDENCE** |
| Module + wavefront hook | `a7ng_topk_wavefront_global.sv` + `a7ng_ddr_wavefront_top` `u_global` — **EVIDENCE** |
| Integrated path XSim counterexample | **EVIDENCE** (this gate) |
| HS-02 / retrieval / BOARD | **NOT CLOSED** — correctly excluded in `CLOSEOUT.md:19` |

Per-wave-only Top-K risk is **closed for integrated wavefront law claims** at **MIG_XSIM** scope. Retrieval, HS-02, and arbitrary wave-partition stress remain **OPEN**.

### 4. Frozen-artifact law — **PASS**

- `a7ng_topk.sv` not edited (SHA match).  
- `a7ng_ddr_wavefront_top.sv` SHA `7971FB77193D5A0E365D1C44FEFF523D593BD7D591E014C7F4F891FF6F2613C7` — documented in `SHA256.txt`; expected integration edit, not silent overwrite of frozen LM/01R/02M bits.  
- No BOARD_PASS or frozen bitstream identity claim.

### 5. HLB / forbidden PASS routes — **PASS**

- No BOARD_PASS, no silicon, no host winner/address/answer path.  
- Golden `tb_a7ng_wf_global_topk_integrated_golden.svh` is harness oracle (auto-generated); DUT computes merge via RTL `a7ng_topk`.  
- No golden edit to pass failing test, no skipped falsifier, no seed shopping observed.

---

## Findings (ordered by severity)

```
[MINOR] Integrated TB header comment stale vs executed stream
  where     : tests/xsim/tb_a7ng_wf_global_topk_integrated.sv:5-6
  claim      : FALSIFIER references rank-9 0xDEADBEEF score 135 (unit counterexample)
  evidence   : Integrated TB executes schema-locked node_id 0..31; W1 8th is 10@161 per golden.svh
  why it matters: a reader opening the TB file may misread which counterexample ran
  fix        : update TB header comment to reference integrated W1 8th 10@161 stream

[MINOR] PREREGISTER PASS criterion cites unit marker only
  where     : PREREGISTER.md:89-91
  claim      : PASS = `A7NG_WF_GLOBAL_TOPK_XSIM_PASS` (unit)
  evidence   : Integrated gate uses `A7NG_WF_GLOBAL_TOPK_INTEGRATED_XSIM_PASS`; integrated table is documented above but PASS line not updated
  why it matters: preregistration reader may think integrated marker is out of scope
  fix        : add integrated PASS line: `A7NG_WF_GLOBAL_TOPK_INTEGRATED_XSIM_PASS`
```

---

## Independent re-derivation (headline numbers)

| Quantity | Closeout / DISPATCH | Auditor re-derive | Match |
|----------|---------------------|-------------------|-------|
| `a7ng_topk.sv` SHA | `F671FCB1…` | PowerShell `Get-FileHash` | **YES** |
| `a7ng_ddr_wavefront_top.sv` SHA | `7971FB77…` | PowerShell `Get-FileHash` | **YES** |
| XSim `fails` | `0` | log line 1968 | **YES** |
| `merge_count` | `2` | log `WFGI_DIAG … merges=2` | **YES** |
| W1 8th displaced | `10@161` | log line 1965 + `WFGI_W1_8TH_*` | **YES** |
| Per-wave-only divergence | `8/8` | log `8 slots` | **YES** |
| Archived log SHA | `213D17AD…` | PowerShell `Get-FileHash` | **YES** |

---

## NOT VERIFIED

- Independent `a7-ng-xsim-verify` DISPATCH line for this gate (archived log used).
- `a7-vivado-gate` post-route / OOC utilisation of integrated top.
- Board silicon / MIG board traffic on integrated global path.
- Non-sequential `node_id` through full integrated DDR pack (unit TB retains stronger stream; integrated uses sequential 0..31 by design).
- Python oracle `global_topk_match` metric (golden auto-generated; not re-run this session).

---

## Auditor disposition

| Field | Value |
|-------|-------|
| **result** | **PASS_NARROW** |
| **allow_loop_done_eng** | **true** |
| **evidence_class** | **MIG_XSIM_WAVEFRONT_INTEGRATED** |
| **carried_risk_r1** | **CLOSED** — integrated wavefront path; not HS-02 / retrieval / BOARD |
| **BOARD_PASS** | **reserved** (human only) |

Parent may retain `wf_global_topk_integrated_00` **DONE_ENG** with `allow_loop_done_eng: true` and `result_class: PASS_NARROW`. Proceed to `descriptor_contract_00` per `LOOP_STATE.next`.
