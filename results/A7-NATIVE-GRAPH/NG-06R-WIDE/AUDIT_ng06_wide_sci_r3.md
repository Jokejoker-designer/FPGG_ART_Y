# AUDIT r3 — ng06_wide_dispatch (VERIFY_ONLY after SHA_FREEZE_MATCH)

**Auditor:** `a7-evidence-auditor`  
**Mode:** READ_ONLY_AUDIT / VERIFY_ONLY (no RTL edit; no LOOP_STATE flip)  
**Date:** 2026-08-22  
**Round:** 3  
**Evidence_class:** **XSIM** (not BOARD, not silicon)  
**GATE:** `ng06_wide_dispatch`  
**LOOP_STATE:** first OPEN = `ng06_wide_dispatch` (matches this audit)  
**Prior:** `AUDIT_ng06_wide_sci_r2.md` → PASS_NARROW (`allow_loop_done_eng=false`; SHA RTL stale)  
**Implementer DISPATCH (last):** `a7-ng-scientific` / `SHA_FREEZE_MATCH` / sha `4C604278…`  
**Skills:** scientific-critical-thinking + PLAN_KDENSE Phase A1  

```text
MUST_READ_UNBLOCK_H5: read. Next = ungated DIFF twin (not S2, not glue).
BLUEPRINT_LOOP: read. Goal=NATIVE_V1_MINI_AI_BOARD_PASS. Next=ng06_wide_dispatch
```

---

## Verdict

```text
AUDIT: CLEAN
result: PASS
allow_loop_done_eng: true
missing_bag: none
```

Archive↔live SHA binding holds for the DUT+TB that the repair ladder elaborated.  
Three ready bags file-backed; `lane_grant_o` authority; way16 sparse starve=0; no BOARD_PASS.  
**A1 DONE_ENG allow = true.** Orchestrator may flip `LOOP_STATE` — this auditor does **not**.

**Do not declare BOARD_PASS.** Evidence_class remains **XSIM**.

---

## Declared scientific frame (graded)

| Slot | Declared (closeout SHA repair) | Auditor grade |
|------|--------------------------------|---------------|
| OBSERVATION | r2 PASS_NARROW; archive 3D39 ≠ live 4C60 | **EVIDENCE** (r2) |
| UNKNOWN | `SHA_FREEZE_MATCH` — re-run + re-freeze binds archive to live | **Closed YES** — **EVIDENCE** |
| H_CANDIDATE | Accept live 4C60 + full ladder re-run | **SUPPORTED** — **EVIDENCE** |
| H_RIVAL | Post-freeze rewrite broke allocator gates | **DID NOT FIRE** — same bag numbers + all PASS markers |
| FALSIFIER | Bag FAIL or SHA mutates during/after re-run before freeze | **DID NOT FIRE** |
| UNIT | ready-pattern bag / seed `0x00A70616` | **EVIDENCE** |
| CONTROL | ALWAYS bag + PRE/POST SHA + law `a7ng-share-v1` | **EVIDENCE** |
| METRICS | util, ready_duty, max_jpc, starve, jobs_acc + SHA | Re-derived below |

---

## Pass-rule checklist (PLAN A1 + user r3)

| # | Rule | Outcome |
|---|------|---------|
| 1 | SHA256.txt matches live `a7ng_multi_agent_share.sv` + `tb_a7ng_wide_dispatch.sv` | **PASS** — all three archive lines match live (UTF-8) |
| 2 | TB measures via `lane_grant_o` | **PASS** — grant popcount L175–184; `pop_valid_o` debug-only |
| 3 | ≥2 ready bags (SPARSE and/or BURSTY) file-backed | **PASS** — both present |
| 4 | starve=0 on sparse way16 | **PASS** |
| 5 | ALWAYS control; util≥80% not required on sparse | **PASS** — ALWAYS util16=100; sparse util≈duty |
| 6 | Closeout marker `NG06R_WIDE_ENGINEERING_PASS` | **PASS** — marker file + ladder log |
| 7 | No BOARD_PASS / silicon overclaim | **PASS** |

**DONE_ENG allow:** **true** (all A1 rules pass).

---

## SHA freeze binding (EVIDENCE)

| Artifact | SHA256 | Match |
|----------|--------|-------|
| live `rtl/native_graph/share/a7ng_multi_agent_share.sv` | `4C604278038E016840EBD49C3563EB6068CE4E2B8765DF1A53F8A26707B70052` | = SHA256.txt |
| live `tests/xsim/tb_a7ng_wide_dispatch.sv` | `A20BCA46D6FC497593AD91DCE3B289C9CA5142542FDAF003CEF21AB260F19FB9` | = SHA256.txt |
| live `tests/xsim/tb_a7ng_multi_agent_share.sv` | `E7232EC7E91FB27F562A3844A84B2836D024DDE518391BC52001B045E2F5A188` | = SHA256.txt |
| `PRE_RUN_RTL_SHA.txt` | `4C604278…` | = live |
| SHA256.txt encoding | UTF-8 (no NUL BOM) | **EVIDENCE** |

Timeline check (**FACT**): live RTL mtime `2026-08-22T02:13:19` **before** repair session start `02:18:43` and freeze `02:23:00`. Repair log `run_wide_bags_sha_repair.log` elaborated the 4C60 tree; freeze after ladder. Live hash at audit time still equals archive — **no post-freeze rewrite detected** (closes r2 CRITICAL).

`DIFF_SHA_DRIFT.md` present: documents 3D39→4C60 unrecoverable hunk; accept-live decision. Byte-level old hunk remains **UNKNOWN** (not blocking after re-bind).

---

## Re-derived headline numbers (EVIDENCE — XSim logs)

Authority: `RESULT` / `A7NG06R_WIDE_XSIM_PASS` in `xsim_{always,sparse,bursty}_way{1,4,8,16}.log`.  
Batch: `run_wide_bags_sha_repair.log` → `A7NG06R_WIDE_LADDER_PASS` / `NG06R_WIDE_ENGINEERING_PASS`.

### BAG_ALWAYS_READY (control)

| N_WAY | util% | ready_duty% | max_jpc | starve | jobs_acc |
|------:|------:|------------:|--------:|-------:|---------:|
| 1 | 6.25 | 100.00 | 1 | 0 | 100000 |
| 4 | 25.00 | 100.00 | 4 | 0 | 400000 |
| 8 | 50.00 | 100.00 | 8 | 0 | 800000 |
| **16** | **100.00** | **100.00** | **16** | **0** | **1600000** |

### BAG_SPARSE_READY (seed `0x00A70616`)

| N_WAY | util% | ready_duty% | max_jpc | starve | jobs_acc |
|------:|------:|------------:|--------:|-------:|---------:|
| 1 | 6.25 | 49.95 | 1 | 0 | 100000 |
| 4 | 24.92 | 49.95 | 4 | 0 | 398690 |
| 8 | 45.08 | 49.95 | 8 | 0 | 721207 |
| **16** | **49.95** | **49.95** | **15** | **0** | **799268** |

### BAG_BURSTY_READY (64/64)

| N_WAY | util% | ready_duty% | max_jpc | starve | jobs_acc |
|------:|------:|------------:|--------:|-------:|---------:|
| 1 | 3.13 | 50.02 | 1 | 0 | 50016 |
| 4 | 12.50 | 50.02 | 4 | 0 | 200064 |
| 8 | 25.01 | 50.02 | 8 | 0 | 400128 |
| **16** | **50.02** | **50.02** | **16** | **0** | **800256** |

Closeout tables **match** re-derived logs (**EVIDENCE**). Occupancy util≈ready_duty under sparsity (**EVIDENCE**). max_jpc ladder meets TB floors (way16 ≥8).

---

## Findings

None. Prior r2 CRITICAL (archive SHA ≠ live RTL) is **closed** by re-run + UTF-8 re-freeze to `4C604278…` with live still matching at audit time.

---

## Claim grading (closeout)

| Claim | Closeout label | Auditor |
|-------|----------------|---------|
| Full bag ladder on live RTL `4C604278…` | FACT | **EVIDENCE** |
| SHA256.txt matches live RTL+TB of that run | FACT | **EVIDENCE** |
| ALWAYS way16 util≥80, starve=0, max_jpc=16 | FACT | **EVIDENCE** |
| SPARSE/BURSTY way16 starve=0; max_jpc ladder; jobs flow | FACT | **EVIDENCE** |
| Law `a7ng-share-v1` unchanged; no epochs | FACT | **EVIDENCE** (law string present; epochs not started) |
| Exact byte hunk 3D39→4C60 | UNKNOWN | **UNKNOWN** (documented; non-blocking) |
| BOARD_PASS / silicon | NOT claimed | **OK** |

---

## Dispatch integrity

| Check | Result |
|-------|--------|
| LOOP first OPEN == `ng06_wide_dispatch` | **PASS** |
| Implementer agent `a7-ng-scientific` | **PASS** (crew / `pipeline.json` `ng06` character_id) |
| This VERIFY agent `a7-evidence-auditor` | **PASS** |
| Marker + SHA + XSim log present | **PASS** (not paper PASS) |

---

## NOT VERIFIED

- Byte-level diff of lost `3D394158…` vs live `4C604278…` (no VCS snapshot) — irrelevant to current binding after re-run.  
- Board / post-route util (out of scope; Evidence_class=XSIM).  
- Whether orchestrator will flip LOOP / set DONE_ENG (reserved to parent; this audit only sets `allow_loop_done_eng`).

---

## Return block (for orchestrator)

```text
GATE: ng06_wide_dispatch
PASS-FAIL: PASS
allow_loop_done_eng: true
MAJOR_FINDINGS: none
Evidence_class: XSIM
NEXT: orchestrator may set LOOP_STATE.ng06_wide_dispatch DONE_ENG (allow=true); then dispatch ng06_epoch / unblock dependents. Do not flip LOOP_STATE in this auditor turn. No BOARD_PASS.
```
