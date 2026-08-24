# 16 — Masterplan execution path (human-approved)

**Written:** 2026-08-22  
**Authority:** Human approval `results/A7-NATIVE-GRAPH/BOTTLENECK-RESOLUTION-REVIEW-00/HUMAN_APPROVAL_20260822.md`  
**Supersedes for planning:** stale “re-open `lm06_wm_ladder` first” guidance in older Masterplan V2 drafts  
**Does not edit:** `LOOP_STATE.json` — live NEXT remains `STOP` until explicit human dispatch

---

## 1. Two completion concepts (do not conflate)

| Concept | Meaning | Done when |
|---------|---------|-----------|
| **Masterplan package complete** | Architecture docs reconciled with evidence; execution path to §14 documented; no stale contradictions | This file + `MASTERPLAN_FINISH_STATUS.md` audit PASS |
| **Native V1 program complete** | Every §14 box evidenced; human declares `NATIVE_V1_MINI_AI_BOARD_PASS` | `PROJECT_COMPLETE.md` all PASS + human |

This document closes the **masterplan package** path. It does **not** claim BOARD_PASS.

---

## 2. Human-approved gate DAG

### 2.1 Graph / retrieval track (serial)

```text
WF-GLOBAL-TOPK-00
        |
        v
DESCRIPTOR-CONTRACT-00
        |
        v
DDR-CUE-SOA-00
```

| Gate | ONE UNKNOWN | Blocks if skipped |
|------|-------------|-------------------|
| **WF-GLOBAL-TOPK-00** | Does wavefront integration preserve proven global Top-K across waves? | SOA survivor fetch; HS-02 Recall@K; §14 graph Top-K |
| **DESCRIPTOR-CONTRACT-00** | Which per-candidate fields does lawful stage-1 scoring actually consume? | SOA byte budget (96 vs 104 bits) |
| **DDR-CUE-SOA-00** | Can physical layout reduce first-stage DDR bytes/query without changing laws? | bytes/query optimization |

**Carried risk:** `lm06_wm_00.carried_risk_r1` — per-wave 16→8 without `G_t` accumulator. NG-02R proves the **primitive** only.

### 2.2 LM working-set track (parallel)

```text
LM06-WM-TRACE / MRC
        |
        v
one physical WM candidate (synthesized)
        |
        v
P&R (post-route evidence)
        |
        v
BRAM-OWNER-00
```

| Gate | Notes |
|------|-------|
| **LM06-WM-TRACE** | Reuse-distance / MRC from tile traces — **not** WM-00 port-demand counts |
| **LM06 ladder** | Reporting **ceilings** 96/64/48/32 — not blind cuts; stop at first Pareto good rung |
| **BRAM-OWNER-00** | Phase FSM; dirty policy; `WAIT_DDR_IDLE`; measured `phi_switch` |

`lm06_wm_ladder` in LOOP_STATE stays **BLOCKED** until human re-open **after** MRC scope defined.

### 2.3 Integration track (after graph + LM tracks mature)

```text
HS22-LM06-ACTIVE-00
        |
        v
HS-02 teacher-off semantic
        |
        v
bram_ownership_report (ship config)
        |
        v
full_integration
        |
        v
scale ladder 20 → 40 → … → 800k (when prior boxes PASS)
        |
        v
HUMAN §14 BOARD_PASS
```

### 2.4 Encoder lane (parallel, isolated)

```text
ENC-GEOM-DIAG-00  — REFERENCE_MODEL only
```

- Archive: `results/A7-EAM-03E/` only  
- **Must not** count as Native Graph progress  
- Preregister transforms: sign-space `b_ij=sign(h_ij)` vs continuous `z_ij=standardized(h_ij)`  
- **REJECT** ungated DIFF as next remedy (E1 falsified)

---

## 3. Descriptor contract (NOT YET FROZEN)

| Tier | Bits | Status |
|------|-----:|--------|
| Known lower bound | `node_id` 32 + lawful `node_cue` 64 = **96** | **KNOWN** |
| If per-node `learned_prior` lawful | +8 = **104** | **OPEN** until DESCRIPTOR-CONTRACT-00 |
| Full NodeRecordV1 | **128** (16 B) | Measured today on wavefront path |

Wiring artifacts (not law): `{cue,cue}` replication; broadcast `learned_prior_i`.

SOA **blocked** until descriptor contract closes.

---

## 4. Foundations already CLOSED (do not re-gate)

| Gate | Class |
|------|-------|
| `mig_metric_00` | MIG_XSIM |
| `mig_board_r2` | BOARD_MIG 16/16 |
| `ddr_wavefront_00` | MIG_XSIM_WAVEFRONT PASS_NARROW |
| `lm06_wm_00` | LM06_WM_XSIM bit-exact |
| `ng02` / NG-02R | XSIM global 16→8 primitive |
| `mem_schema_v1` | PYTEST+XSIM (repo-wide freeze still QUEUED) |

---

## 5. Queued documentation gates (parallel OK)

| id | Purpose |
|----|---------|
| `record_schema_freeze` | Repo-wide Node/Edge/Episode authority |
| `bram_ownership_report` | SPEC §28 ship-config enum |

---

## 6. Explicit DO NOT (program law)

- Open semantic HS-02 before HS22-LM06-ACTIVE-00 + global Top-K  
- Open DDR-CUE-SOA before DESCRIPTOR-CONTRACT-00  
- Stack UA128 + LM132 (260/264 FALSIFIED)  
- Raise MIG outstanding >8 without `in_flight` export (plateau measured)  
- Ungated DIFF encoder law  
- AI declare BOARD_PASS  

---

## 7. Next human dispatch (recommended)

**First implementer gate:** `WF-GLOBAL-TOPK-00`

Preregister: integration `law_id`, counterexample stream (non-sequential `node_id`), reuse `a7ng_topk` 8+8→8 merge.

---

## 8. Cross-references

| Document | Role |
|----------|------|
| `00_CURRENT_AUTHORITY.md` | Evidence delta + status table |
| `02_IMPLEMENTATION_ROADMAP.md` Part C | Dependency chains |
| `14_FINAL_ACCEPTANCE_CHECKLIST.md` | Closure criteria |
| `BOTTLENECK-RESOLUTION-REVIEW-00/` | Full technical review |
| `STATUS/MASTERPLAN_FINISH_STATUS.md` | Package vs program audit |
