# PROPOSED_GATE_DAG — NATIVE-V1-BOTTLENECK-RESOLUTION-REVIEW-00

Proposal §22 DAG verified against `LOOP_STATE.json` and Master Blueprint.

**Legend:** VALID | INVALID | MISSING_DEPENDENCY | UNNECESSARY

---

## Foundation (DONE — not re-gated)

| Gate | Status | Evidence |
|------|--------|----------|
| `mig_metric_00` | DONE_ENG | MIG_XSIM |
| `mig_board_r2` | DONE_ENG | BOARD_MIG 16/16 |
| `ddr_wavefront_00` | DONE_ENG PASS_NARROW | MIG_XSIM_WAVEFRONT |
| `lm06_wm_00` | DONE_ENG PASS_NARROW | LM06_WM_XSIM |
| `ng02` global Top-K primitive | DONE_ENG | NG-02R |
| `mem_schema_v1` | DONE_ENG | PYTEST+XSIM |

---

## Proposed edges

| From | To | Verdict | Notes |
|------|-----|---------|-------|
| `record_schema_freeze` | `WF-GLOBAL-TOPK-00` | **UNNECESSARY** (hard) | Top-K is logic; soft doc hygiene OK |
| `WF-GLOBAL-TOPK-00` | `DESCRIPTOR-CONTRACT-00` | **VALID** | Human-approved: descriptor bits NOT YET FROZEN |
| `DESCRIPTOR-CONTRACT-00` | `DDR-CUE-SOA-00` | **VALID** | SOA blocked until lawful stage-1 fields resolved (96 vs 104b) |
| `WF-GLOBAL-TOPK-00` | `DDR-CUE-SOA-00` | **INVALID** (direct) | Must pass descriptor contract — human correction 2026-08-22 |
| `DDR-CUE-SOA-00` | `LM06 WM Pareto ladder` | **AMEND → parallel** | Ladder blocked on human re-open; SOA is DDR layout — serial not required after global Top-K |
| `WF-GLOBAL-TOPK-00` | `HS-02 semantic` | **VALID** | Implicit via retrieval correctness |
| `LM06 ladder` | `BRAM-OWNER-00` | **VALID** | Doctrine order |
| `BRAM-OWNER-00` | `HS22-LM06-ACTIVE-00` | **VALID** | Stale read risk without owner FSM |
| `HS22-LM06-ACTIVE-00` | `HS-02 teacher-off` | **VALID** | Token path before semantic exam |
| `ENC-GEOM-DIAG-00` | graph gates | **UNNECESSARY** | Parallel PARKED lane |
| `HS-02` | `FINAL BRAM OWNERSHIP` | **VALID** | SPEC §28 ship config |
| `FINAL BRAM OWNERSHIP` | `FULL INTEGRATION` | **VALID** | `full_integration` blocked |
| `FULL INTEGRATION` | `HUMAN §14` | **VALID** | `human_declares_board_pass` |

---

## MISSING_DEPENDENCY edges (add to mental model)

| Missing | Blocks |
|---------|--------|
| `01R scale ladder` before HNSW | Branch T — research only |
| `TRAIN-V2` silicon re-run after law change | Harness ≠ HS-02 |
| Counterexample stream for WF-GLOBAL-TOPK | Non-sequential node_id |
| MRC trace gate before ladder rung claims | `lm06_wm_01` scope |
| Post-route FIFO/MIG enum | `bram_ownership_report` |

---

## INVALID edges (if attempted)

| Edge | Why INVALID |
|------|-------------|
| Skip WF-GLOBAL-TOPK → HS-02 / retrieval claim | carried_risk_r1 |
| `ddr_wavefront_00` → Native V1 BOARD_PASS | PASS_NARROW only |
| `lm06_wm_00` → BRAM reduction claim | struck inference |
| Encoder diagnostic → graph NG PASS | HS-20 glue forbidden |
| `record_schema_freeze` alone → DDR-CUE-SOA byte win | No measured reduction yet |

---

## Recommended execution order (human-approved 2026-08-22)

See `HUMAN_APPROVAL_20260822.md`.

```text
GRAPH TRACK:
  WF-GLOBAL-TOPK-00 → DESCRIPTOR-CONTRACT-00 → DDR-CUE-SOA-00

LM TRACK (parallel):
  LM06-WM-TRACE/MRC → one physical WM candidate → P&R → BRAM-OWNER-00

INTEGRATION (after tracks):
  HS22-LM06-ACTIVE-00 → HS-02 teacher-off → bram_ownership_report → full_integration → §14

ENCODER (parallel, no graph credit):
  ENC-GEOM-DIAG-00 — REFERENCE_MODEL only
```

`record_schema_freeze` — parallel doc hygiene. `lm06_wm_ladder` — BLOCKED until human re-open after MRC.
