# AUDIT — frontier_shootout (VERIFY_ONLY)

**Auditor:** `a7-evidence-auditor`  
**Mode:** READ_ONLY_AUDIT / VERIFY_ONLY (no RTL edit; no LOOP_STATE flip)  
**Date:** 2026-08-22  
**Evidence_class:** **PYTEST_BEHAVIORAL + XSIM + OOC_SYNTH** (not silicon, not BOARD)  
**GATE:** `frontier_shootout`  
**LOOP_STATE:** first OPEN / `next` = `frontier_shootout` (matches this audit)  
**Implementer DISPATCH:** `a7-ng-topk-frontier` / `PASS` / marker `A7NG_FRONTIER_SHOOTOUT_XSIM_PASS`  
**Refuse rule:** DONE_ENG allow **false** if Top-8 law SHA drifts, A/B/C workload not identical, winner not from preregistered metrics, unit overclaimed as cycles, BOARD_PASS language, or missing comparison table / XSim marker.

```text
MUST_READ_UNBLOCK_H5: read. Next = ungated DIFF twin (not S2, not glue).
BLUEPRINT_LOOP: read. Goal=NATIVE_V1_MINI_AI_BOARD_PASS. Next=frontier_shootout
```

---

## Verdict

```text
AUDIT: 2 FINDINGS
result: PASS
allow_loop_done_eng: true
severity_metrics: identical A/B/C bag; winner B_systolic by M1→M2→M3 then M7 LUT among M1/M2/M3 ties; Top-8 SHA MATCH F671FCB1…; unit=64 queries (not cycles); Evidence_class=PY+XSIM+OOC; no BOARD_PASS
```

H_CANDIDATE (measurable shootout selects frontier arch by numbers) **SUPPORTED** under **behavioral + XSim + OOC** — **EVIDENCE**.  
H_RIVAL (single-seed / traffic-family confound) remains **OPEN** — correctly not closed; 64 query seeds × 4 bag modes mitigate but do not exhaust.  
**Do not declare BOARD_PASS.** **Do not flip LOOP_STATE** (orchestrator only).

---

## Declared scientific frame (graded)

| Slot | Declared | Auditor grade |
|------|----------|---------------|
| OBSERVATION | Bucket frontier is coarse; not proven vs exact best-first | **EVIDENCE** (A M1≈0.515, ovf=1631) |
| UNKNOWN | Under identical workload, which of {bucket, systolic PQ, two-level} wins on M1–M8 without changing Top-8? | **Closed** for this bag — **EVIDENCE** |
| H_CANDIDATE | Numbers pick architecture | **SUPPORTED** — **EVIDENCE** |
| H_RIVAL | Workload confound / single-seed pseudoreplication | **OPEN** — **EVIDENCE** that claim stays open |
| FALSIFIER | No comparison table; or Top-8 / flow law regresses | **Did not fire** — table archived; SHAs MATCH |
| UNIT | Query seed / query bag (N=64), not cycles-as-queries | **EVIDENCE** — 64 rows; marker `queries=64` |
| CONTROL | `a7ng-topk-global-v1` SHA; NG-02R-FLOW bucket SHA; frozen bits | **EVIDENCE** (live rehash MATCH) |
| METRICS | M1–M8 preregistered | **EVIDENCE** (list locked); ranking key order gap = finding #1 |

---

## Dispatch / loop law

| Check | Outcome |
|-------|---------|
| Implementer PASS `frontier_shootout` / `a7-ng-topk-frontier` | **PASS** — DISPATCH_LOG before verify trio |
| Agent vs `run_blueprint_loop.py` FALLBACK | **PASS** — `frontier_shootout` → `a7-ng-topk-frontier` |
| `LOOP_STATE.next` / first OPEN | **PASS** — `frontier_shootout` |
| Parent BOARD_PASS / silicon claim | **PASS** — explicit non-claims |
| Evidence_class mixed as board | **PASS** — labeled PY+XSIM+OOC |
| Auditor VERIFY_ONLY (no LOOP flip) | **PASS** — this file |

---

## Required checks (this gate)

### 1. Identical workload A/B/C table — **PASS**

| Source | What auditor checked |
|--------|----------------------|
| `COMPARISON_TABLE.csv` | 3 arms, M1–M8 columns present |
| `PER_QUERY.csv` | 64 rows; same `qseed` column drives all arms |
| `tb_a7ng_frontier_shootout.sv` | `push_all` drives A/B/C with identical score/id |
| Master seed | `0xF5022201`; qseeds `(MASTER ^ qi*0x9E3779B9)`; 64 unique; re-derived MATCH |

### 2. Winner by preregistered metrics — **PASS** (with MINOR #1)

Auditor re-derived from `PER_QUERY.csv` (means):

| Arm | M1 | M2 | M3 | M6 | M7 LUT (OOC rpt) |
|-----|----|----|----|----|------------------|
| A_bucket | 0.514836 | 0.650391 | 71.516 | 1631 | 1169 |
| B_systolic | 1.000000 | 1.000000 | 97.000 | 0 | 5848 |
| C_twolevel | 1.000000 | 1.000000 | 97.000 | 0 | 7936 |

- M4/M5 re-check: B/C `3072/6208 = 0.494845`; A `(3072−1631)/4577 = 0.314835` — **MATCH** summary/CSV.  
- OOC LUT/FF re-read from `util_{A,B,C}_*.rpt` — **MATCH** `OOC_UTIL.csv` / table.  
- Winner **B_systolic**: dominates A on M1/M2; ties C on M1/M2/M3; wins vs C on preregistered **M7 LUT** (5848 < 7936). Closeout states the tie explicitly.

### 3. Top-8 law untouched — **PASS**

| Artifact | Live SHA256 | Control |
|----------|-------------|---------|
| `rtl/native_graph/topk/a7ng_topk.sv` | `F671FCB1B8FB891EE77A9AC3D5A0BA24AE4DBB8109A6645F2250F611AA197636` | **MATCH** |
| `rtl/native_graph/frontier/a7ng_frontier_buckets.sv` | `CE38FEC3562343C64AB718243CE5F4B815A128524EBA2903BE20CD5ACDD2C565` | **MATCH** |

TB header: does not instantiate/modify Top-8. Frozen LM-06 / 01R / 02M / A0.3 prefixes MATCH prior ddr_feed controls.

### 4. Unit = 64 queries, not overclaimed — **PASS**

- `PREREGISTER.md`: Queries (units): 64  
- `PER_QUERY.csv`: 64 rows  
- XSim marker: `A7NG_FRONTIER_SHOOTOUT_XSIM_PASS queries=64` (implementer + verify logs)  
- M3 is cycles/**query** — not sold as 64 cycle-units. Closeout UNIT row: “not cycles-as-queries.”

---

## Findings

### [MINOR] Ranking key order not fully stamped in PREREGISTER.md

- **where:** `PREREGISTER.md` vs `closeout.md` ranking line vs `frontier_shootout_oracle.py` `ranking_by_M1_M2_M3`
- **claim:** Closeout ranks `M1 → M2 → M3 → M7 LUT` and names B winner among exact arms by LUT
- **evidence:** PREREGISTER locks M1–M8 **list** but not sort keys; oracle `winner_primary` sorts M1/M2/M3 only (B vs C full tie → stable-order pick); M7 tie-break applied after OOC in summary/closeout
- **why it matters:** A reader could think B beat C on primary correctness metrics; they are tied — LUT separates them
- **fix:** One PREREGISTER sentence: “rank M1 desc, M2 desc, M3 asc, then M7 LUT asc”

### [MINOR] Arm A M1/M2 are behavioral-oracle provenance, not XSim golden pops

- **where:** `tb_a7ng_frontier_shootout.sv` (B/C golden only); `PER_QUERY.csv` A columns
- **claim:** Shootout table includes A order/recall as first-class metrics
- **evidence:** TB checks B/C pop streams vs Python golden; A is smoke + overflow count only. A M1/M2 come from `frontier_shootout_oracle.py` behavioral model
- **why it matters:** Mixing PY and XSim without reading evidence_class could over-read A’s M1/M2 as RTL-proven
- **fix:** Keep evidence_class label; optional note on A columns in COMPARISON_TABLE header

---

## Forbidden-route scan

| Route | Result |
|-------|--------|
| Golden edited to match DUT | **Not found** — B/C XSim vs pre-generated golden from same oracle |
| Failing test deleted / tolerance widened | **Not found** |
| Seeds dropped after results | **Not found** — 64/64 present |
| Host winner/answer/gradient for retrieval | **N/A** — frontier structure shootout only |
| Top-8 law modified | **Not found** — SHA MATCH |
| Frozen bits overwritten | **Not found** — SHA MATCH |
| BOARD_PASS self-declared | **Not found** |
| Cycles sold as query units | **Not found** |

---

## allow_loop_done_eng

**true** — identical A/B/C table archived; winner B justified by preregistered metrics (with documented M1–M3 tie + M7); Top-8 + bucket controls MATCH; XSim marker `queries=64`; no BOARD_PASS. Two MINOR labeling/provenance issues do not block DONE_ENG.

**false would require:** Top-8 SHA drift, missing/unequal workload table, winner by taste / post-hoc metric not in M1–M8, unit overclaim, or BOARD_PASS language.

---

## NOT VERIFIED

- Board / silicon frontier latency or util (OOC synth only; M8 NA)
- Independent full oracle re-run this session (re-derived means from archived `PER_QUERY.csv`; SHAs re-hashed live)
- Multi-master-seed traffic families beyond 4 bag modes (H_RIVAL OPEN)
- Whether parent will flip LOOP after this audit (orchestrator only)

---

```text
allow_loop_done_eng: true
winner: B_systolic (M1/M2/M3 tie with C; M7 LUT)
Top-8_law: MATCH F671FCB1…
unit: 64 queries
BOARD_PASS: not declared
LOOP_STATE: not modified
```
