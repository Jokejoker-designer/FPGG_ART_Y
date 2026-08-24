# AUDIT r2 — ng06_wide_dispatch (Phase A1 / VERIFY_ONLY after PASS_NARROW repair)

**Auditor:** `a7-evidence-auditor`  
**Mode:** READ_ONLY_AUDIT / VERIFY_ONLY (no RTL edit; no LOOP_STATE flip)  
**Date:** 2026-08-22  
**Round:** 2  
**Evidence_class:** **XSIM** (not BOARD, not silicon)  
**GATE:** `ng06_wide_dispatch`  
**LOOP_STATE:** first OPEN = `ng06_wide_dispatch` (matches this audit)  
**Prior:** `AUDIT_ng06_wide_sci.md` → PASS_NARROW (`allow_loop_done_eng=false`)  
**Skills:** scientific-critical-thinking + PLAN_KDENSE Phase A1  

```text
MUST_READ_UNBLOCK_H5: read. Next = ungated DIFF twin (not S2, not glue).
BLUEPRINT_LOOP: read. Goal=NATIVE_V1_MINI_AI_BOARD_PASS. Next=ng06_wide_dispatch
```

---

## Verdict

```text
AUDIT: 1 FINDING (1 CRITICAL)
result: PASS_NARROW
allow_loop_done_eng: false
missing_bag: (none — BAG_SPARSE_READY + BAG_BURSTY_READY now file-backed)
```

Ready-sparsity repair is **scientifically real as XSim**: three bags, `lane_grant_o` authority, starve=0, max_jpc ladder, jobs flow.  
Archive↔live **RTL SHA binding is broken again** (live file rewritten after freeze). DONE_ENG remains **disallowed**.

**Do not declare BOARD_PASS.** Auditor does not flip `LOOP_STATE`.

---

## Declared scientific frame (graded)

| Slot | Declared (closeout) | Auditor grade |
|------|---------------------|---------------|
| OBSERVATION | Prior PASS_NARROW; SHA≠live; util100% only on always-ready | **EVIDENCE** (r1) |
| UNKNOWN | N_WAY=16 under sparse ready? | **Closed for XSim bags** — see metrics |
| H_CANDIDATE | Allocator feeds under SPARSE/BURSTY | **ENGINEERING_INFERENCE** (supported by starve=0 + max_jpc + jobs_acc) |
| H_RIVAL | High occupancy util = always-ready artifact | **SUPPORTED** for util% (sparse/bursty util≈ready_duty ≈50%) — **EVIDENCE** |
| FALSIFIER | way16 starve>0 OR max_jpc ladder breaks OR jobs_acc=0 | **DID NOT FIRE** on archived logs |
| UNIT | ready-pattern bag / seed | **EVIDENCE** — seed `0x00A70616`; bags≠cycle-as-query |
| CONTROL | ALWAYS bag + SHA freeze | ALWAYS **PASS**; SHA freeze **FAIL** (Finding 1) |
| METRICS | util, ready_duty, max_jpc, starve, jobs_acc | Re-derived below |

---

## Pass-rule checklist (PLAN A1 + user r2)

| # | Rule | Outcome |
|---|------|---------|
| 1 | SHA256.txt matches live `a7ng_multi_agent_share.sv` + `tb_a7ng_wide_dispatch.sv` | **FAIL** — TB match; **RTL mismatch** (Finding 1) |
| 2 | TB measures via `lane_grant_o` | **PASS** — grant popcount L175–184; `pop_valid_o` debug-only |
| 3 | `BAG_SPARSE_READY` present with file-backed numbers | **PASS** — `xsim_sparse_way*.log` |
| 4 | `BAG_BURSTY_READY` if claimed | **PASS** — `xsim_bursty_way*.log` |
| 5 | starve=0 on sparse (+ bursty) way16 | **PASS** |
| 6 | ALWAYS control; util≥80% **not** required on sparse; require max_jpc ladder + starve=0 + jobs flow | **PASS** |
| 7 | No BOARD_PASS / silicon overclaim | **PASS** |

**DONE_ENG allow:** false (rule 1 fails).

---

## Re-derived headline numbers (EVIDENCE — XSim logs)

Authority: `RESULT` / `A7NG06R_WIDE_XSIM_PASS` lines in `xsim_{always,sparse,bursty}_way{1,4,8,16}.log`.  
Batch marker: `run_wide_bags.log` → `A7NG06R_WIDE_LADDER_PASS` / `NG06R_WIDE_ENGINEERING_PASS` (exit 2026-08-22 02:12:02).

### BAG_ALWAYS_READY (control)

| N_WAY | util% | ready_duty% | max_jpc | starve | jobs_acc |
|------:|------:|------------:|--------:|-------:|---------:|
| 1 | 6.25 | 100.00 | 1 | 0 | 100000 |
| 4 | 25.00 | 100.00 | 4 | 0 | 400000 |
| 8 | 50.00 | 100.00 | 8 | 0 | 800000 |
| **16** | **100.00** | **100.00** | **16** | **0** | **1600000** |

util16≥80% control gate: **met**. Identity util%=100×N_WAY/16 still holds on this bag only (**EVIDENCE** of always-ready occupancy).

### BAG_SPARSE_READY (Bernoulli p≈0.5, seed `0x00A70616`)

| N_WAY | util% | ready_duty% | max_jpc | starve | jobs_acc |
|------:|------:|------------:|--------:|-------:|---------:|
| 1 | 6.25 | 49.95 | 1 | 0 | 100000 |
| 4 | 24.92 | 49.95 | 4 | 0 | 398690 |
| 8 | 45.08 | 49.95 | 8 | 0 | 721207 |
| **16** | **49.95** | **49.95** | **15** | **0** | **799268** |

Occupancy util≈duty (**EVIDENCE**). max_jpc ladder 1→4→8→15 meets TB floor (≥8 @ way16). jobs_acc>0. starve=0.

### BAG_BURSTY_READY (64 on / 64 off)

| N_WAY | util% | ready_duty% | max_jpc | starve | jobs_acc |
|------:|------:|------------:|--------:|-------:|---------:|
| 1 | 3.13 | 50.02 | 1 | 0 | 50016 |
| 4 | 12.50 | 50.02 | 4 | 0 | 200064 |
| 8 | 25.01 | 50.02 | 8 | 0 | 400128 |
| **16** | **50.02** | **50.02** | **16** | **0** | **800256** |

Same pattern: util≈duty; max_jpc=N_WAY on every rung; starve=0; jobs flow.

Closeout numeric tables **match** re-derived logs (**EVIDENCE**).

---

## Findings

### [CRITICAL] Archive SHA ≠ live `a7ng_multi_agent_share.sv`

- **where:** `results/A7-NATIVE-GRAPH/NG-06R-WIDE/SHA256.txt` vs live `rtl/native_graph/share/a7ng_multi_agent_share.sv`  
- **claim:** Closeout / GATE / `NG06R_WIDE_ENGINEERING_PASS.md`: “SHA matches live tree”; RTL SHA `3D3941582901C1B081228AC9A53B497FB7EA2A1FB9FD2E6C6420E267981AA711`  
- **evidence:**  
  - SHA256.txt RTL = `3D3941582901C1B081228AC9A53B497FB7EA2A1FB9FD2E6C6420E267981AA711` (mtime 02:12:38)  
  - live RTL SHA256 = `4C604278038E016840EBD49C3563EB6068CE4E2B8765DF1A53F8A26707B70052` (mtime **02:13:19** — after freeze and after `run_wide_bags.log` 02:12:02)  
  - live TB = `A20BCA46D6FC497593AD91DCE3B289C9CA5142542FDAF003CEF21AB260F19FB9` — **matches** SHA256.txt  
  - Closeout line “Three ready bags run; SHA matches live tree | FACT” is **FALSE_OR_OVERCLAIM** at audit time  
- **why it matters:** DONE_ENG requires archive↔live binding of the DUT that XSim elaborated. Post-freeze RTL rewrite means current tree is not the hashed artifact; promoting would stamp an unproven binary (same class of defect as r1 Finding 1).  
- **fix:** Stop editing share.sv; re-hash live RTL; if hash≠`3D394158…`, re-run full always/sparse/bursty ladder on frozen SHA; refresh SHA256.txt (UTF-8 preferred) + GATE; then re-dispatch auditor. Do not flip LOOP until match.

---

## What is clean (non-findings vs r1)

- **BAG_SPARSE_READY** and **BAG_BURSTY_READY** are no longer missing — file-backed ladders + markers (**EVIDENCE**).  
- TB job accounting uses `lane_grant` popcount, not `pop_valid_o` alone (**EVIDENCE**).  
- ALWAYS util≥80% retained as control only; sparse util not re-gated at 80% (HS-17) (**EVIDENCE** in TB L282–286).  
- H_RIVAL on occupancy util% correctly treated as supported under sparsity (**EVIDENCE** util≈duty).  
- No BOARD_PASS / silicon claim in GATE/closeout/marker (**EVIDENCE**).  
- Implementer DISPATCH agent `a7-ng-scientific` consistent with NG-06 crew; gate id matches LOOP first OPEN.

---

## Claim grading (closeout)

| Claim | Closeout label | Auditor |
|-------|----------------|---------|
| Three bags run with logged metrics | FACT | **EVIDENCE** |
| ALWAYS way16 util≥80, starve=0, max_jpc=16 | FACT | **EVIDENCE** |
| SPARSE/BURSTY way16 starve=0; max_jpc ladder; jobs flow | FACT | **EVIDENCE** |
| Occupancy util≈ready_duty under sparse/bursty | FACT | **EVIDENCE** |
| Allocator feeds under sparsity (H_CANDIDATE) | INFERENCE | **ENGINEERING_INFERENCE** (OK) |
| SHA matches live tree | FACT | **FALSE_OR_OVERCLAIM** at audit time |
| BOARD_PASS | NOT claimed | **OK** |

---

## NOT VERIFIED

- Functional diff of live RTL (`4C604278…`) vs archived hash (`3D394158…`) — only mtime+hash proven; no byte-level blame without VCS.  
- Whether post-02:12:38 edit was intentional repair, accidental touch, or concurrent agent.  
- Board / post-route util (out of scope; Evidence_class=XSIM).  
- Parent did not write RTL this VERIFY turn (assumed; RTL mtime post-dates bag run).

---

## Return block (for orchestrator)

```text
GATE: ng06_wide_dispatch
PASS-FAIL: PASS_NARROW
allow_loop_done_eng: false
MAJOR_FINDINGS:
  1. CRITICAL — SHA256.txt RTL ≠ live a7ng_multi_agent_share.sv (TB matches; RTL rewritten after freeze)
missing_bag: none
Evidence_class: XSIM
NEXT: re-freeze SHA to live RTL (or revert RTL to 3D394158…); re-run bag ladder if hash changed; re-dispatch a7-evidence-auditor; then ng06_epoch only if allow_loop_done_eng=true. Do not flip LOOP_STATE on this audit.
```
