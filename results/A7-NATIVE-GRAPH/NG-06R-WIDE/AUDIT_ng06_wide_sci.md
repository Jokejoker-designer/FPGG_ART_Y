# AUDIT — ng06_wide_dispatch (Phase A1 / VERIFY_ONLY)

**Auditor:** `a7-evidence-auditor`  
**Mode:** READ_ONLY_AUDIT / VERIFY_ONLY (no RTL edit)  
**Date:** 2026-08-22  
**Evidence_class:** **XSIM** (not BOARD, not silicon)  
**GATE:** `ng06_wide_dispatch`  
**LOOP_STATE:** first OPEN = `ng06_wide_dispatch` (matches this audit)  
**Skills:** scientific-critical-thinking + PLAN_KDENSE Phase A1  

```text
MUST_READ_UNBLOCK_H5: read. Next = ungated DIFF twin (not S2, not glue).
BLUEPRINT_LOOP: read. Goal=NATIVE_V1_MINI_AI_BOARD_PASS. Next=ng06_wide_dispatch
```

---

## Verdict

```text
AUDIT: 2 FINDINGS (1 CRITICAL, 1 MAJOR)
result: PASS_NARROW
allow_loop_done_eng: false
```

GATE file / closeout **XSim ladder on one always-ready hotset** is real as XSim engineering evidence.  
It is **not** sufficient to flip `LOOP_STATE.ng06_wide_dispatch` → `DONE_ENG` under PLAN A1.

**Do not declare BOARD_PASS.** Auditor does not flip `LOOP_STATE` (orchestrator only).

---

## Declared scientific frame (graded)

| Slot | Declared | Auditor grade |
|------|----------|---------------|
| OBSERVATION | LOOP OPEN vs GATE util16=100% | **EVIDENCE** — CONFLICTING remains |
| UNKNOWN | Evidence enough for DONE_ENG? | **Answered: NO** |
| H_CANDIDATE (H-disp) | N_WAY=16 feeds 16 PE under util≥80% on varied ready patterns | **NOT CONFIRMED** — only one bag |
| H_RIVAL | 100% util = always-ready hotset / cycle pseudoreplication | **SUPPORTED** (not falsified) |
| FALSIFIER | util only on always-ready → PASS_NARROW | **FIRED** |
| UNIT | ready-pattern / seed bag ≠ 100k cycles as queries | **VIOLATED** if closeout is read as DONE_ENG |
| CONTROL | SHA live vs SHA256.txt; TB `lane_grant_o` | SHA **FAIL**; TB grant authority **PASS** |
| METRICS | util, max_jpc, starve | Re-derived from logs (below) |

---

## Pass-rule checklist (PLAN A1)

| # | Rule | Outcome |
|---|------|---------|
| 1 | SHA matches live RTL | **FAIL** — see Finding 1 |
| 2 | TB asserts/measures via `lane_grant_o` | **PASS** — `tb_a7ng_wide_dispatch.sv` L115–123; `pop_valid_o` debug-only |
| 3 | util on **≥2 ready-sparsity bags** | **FAIL** — only always-ready bag |
| 4 | starve=0 on those bags for way16 | **PASS on bag-1 only**; bags 2+ **MISSING** |
| 5 | No BOARD_PASS / silicon overclaim | **PASS** — GATE/closeout label XSim-only |

**DONE_ENG allow:** false (rules 1 and 3 fail).

---

## Re-derived headline numbers (EVIDENCE — XSim logs)

From `xsim_way*.log` / `run_wide_ladder2.log`:

| N_WAY | busy_acc | util re-derive `100*busy/(16*100000)` | jobs/cyc | max_jpc | starve |
|------:|---------:|--------------------------------------:|---------:|--------:|-------:|
| 1 | 100000 | **6.25%** | 1.0 | 1 | 0 |
| 4 | 400000 | **25.00%** | 4.0 | 4 | 0 |
| 8 | 800000 | **50.00%** | 8.0 | 8 | 0 |
| 16 | 1600000 | **100.00%** | 16.0 | 16 | 0 |

Identity check: util% = `100 * N_WAY / 16` exactly on every rung.  
That is the fingerprint of **always-ready PE + continuous hot_feed + SERVICE=1**, not a multi-sparsity confirmation.

Stimulus (single bag): each idle lane sets `lane_req[i]=1` every cycle (`tb_a7ng_wide_dispatch.sv` L98–108). No alternate ready mask / seed bag in TB or logs.

---

## Findings

### [CRITICAL] Archive SHA ≠ live `a7ng_multi_agent_share.sv` (and TB)

- **where:** `results/A7-NATIVE-GRAPH/NG-06R-WIDE/SHA256.txt` vs live tree  
- **claim:** GATE/closeout bind RTL SHA `DFE3BCF0501F69B17FF29FB03EFE99F63CFE8F711E5CCDA655E0757E042C7B4B`  
- **evidence:**  
  - live RTL SHA256 = `3D3941582901C1B081228AC9A53B497FB7EA2A1FB9FD2E6C6420E267981AA711`  
  - SHA256.txt RTL = `DFE3BCF0501F69B17FF29FB03EFE99F63CFE8F711E5CCDA655E0757E042C7B4B`  
  - live TB = `2EC9B7063D63F4BDAAE3116D6A318404FAB18E7EDC44B9DE2DD76D5283214EEC`  
  - SHA256.txt `tb_wide` = `C15E2BE5872071DB9F95FA9596D4DEADF0C80E41DB69E1480CEDCE6F0B9D37FC`  
- **why it matters:** DONE_ENG requires archive↔live binding. Drift means current tree is not proven by the archived XSim run; promoting would stamp a different binary.  
- **fix:** Re-hash after freeze; re-run `run_a7ng06_wide.tcl` ladder on **frozen** SHA; refresh `SHA256.txt` + GATE line. Do not flip LOOP until match.

### [MAJOR] Single always-ready hotset bag — H_RIVAL not falsified

- **where:** `tests/xsim/tb_a7ng_wide_dispatch.sv` L98–108; closeout util table; PLAN_KDENSE §2 H-disp rival  
- **claim:** util16=100% / starve=0 closes `ng06_wide_dispatch` for DONE_ENG / NEXT=`ng06_epoch`  
- **evidence:** One ready pattern only (`lane_req=all idle lanes`); 100k **cycles** on sticky always-ready; no second sparsity bag in artifact set. Util ladder collapses to `N_WAY/16`.  
- **why it matters:** PLAN A1 + SCI_METHOD session require ≥2 ready-sparsity bags. Cycle count ≠ independent query/seed units (pseudoreplication). H-disp discriminating prediction unmet.  
- **fix:** Keep OPEN. Add **missing bags** (below), measure util/max_jpc/starve per bag, then re-audit.

---

## missing_bag (explicit)

Required before DONE_ENG (minimum **≥1 additional** bag beyond always-ready; PLAN says ≥2 sparsity bags total):

1. **BAG_ALWAYS_READY** — present (current TB). util16=100%, starve=0. Class: PASS_NARROW only.  
2. **BAG_SPARSE_READY** — **MISSING**. Example preregister: fixed masks with ~25% and/or ~50% of lanes asserting `lane_req` per cycle (or Bernoulli p∈{0.25,0.5} with recorded seed).  
3. **BAG_BURSTY_READY** — **MISSING** (strongly recommended second sparsity). Alternating windows ready/idle or duty-cycled req; same HORIZON / N_WAY=16; starve gate still 0.

Until (2) and preferably (3) exist with archived logs + SHA match → **no DONE_ENG**.

---

## What is clean (non-findings)

- TB job accounting uses `lane_grant` popcount, not `pop_valid_o` alone (**EVIDENCE**).  
- RTL header documents `lane_grant_o` authoritative / `pop_valid_o` first-grant debug (**EVIDENCE**).  
- Closeout correctly refuses BOARD_PASS / DDR / epoch / TermGen (**EVIDENCE**).  
- Marker `A7NG06R_WIDE_XSIM_PASS` appears in way logs (**EVIDENCE** — XSim).  
- Implementer DISPATCH line agent `a7-ng-scientific` is consistent with NG-06 crew; gate id matches LOOP first OPEN.

---

## NOT VERIFIED

- Whether live RTL diff vs archived SHA is functional or comment-only (auditor did not diff byte-by-byte beyond hash).  
- Board / post-route util (out of scope; Evidence_class=XSIM).  
- Vivado OOC logs as DONE_ENG authority (not required for A1 util bags).  
- Parent did not write RTL this turn (assumed Task path; not re-proven from chat transcript).

---

## Return block (for orchestrator)

```text
GATE: ng06_wide_dispatch
PASS-FAIL: PASS_NARROW
allow_loop_done_eng: false
MAJOR_FINDINGS:
  1. CRITICAL — SHA256.txt RTL/TB ≠ live tree
  2. MAJOR — util16=100% on single always-ready hotset only (H_RIVAL supported)
missing_bag: BAG_SPARSE_READY (+ BAG_BURSTY_READY recommended); keep BAG_ALWAYS_READY as control
Evidence_class: XSIM
NEXT: keep LOOP OPEN; implementer adds sparsity bags + re-freeze SHA; re-dispatch a7-evidence-auditor; then ng06_epoch only if allow_loop_done_eng=true
```
