# RESULTS — `descriptor_contract_00`

**Agent:** `a7-hlb-auditor`  
**Date:** 2026-08-22  
**Evidence class:** LAW_AUDIT  
**Marker:** `A7NG_DESCRIPTOR_CONTRACT_104B_FROZEN`

---

## ONE UNKNOWN

**Which per-candidate fields does lawful stage-1 scoring actually consume?**

## ACTUAL

| Field | Bits | Lawful stage-1? |
|-------|-----:|:---------------:|
| `node_id` | 32 | YES |
| `node_cue` | 64 | YES |
| `learned_prior` | 8 | YES |
| `node_type`, `topic_id` | 32 | NO |
| `confidence` | 16 | NO (not prior alias) |
| `degree_sat`, `version` | 16 | NO |
| Query cue bags (5×64) | 320 | QUERY-CONTEXT, not per-cand DDR |

**Frozen width:** **104 bits** (not 96).

## TESTS

RTL trace: `a7ng_termgen_lane.sv`, `a7ng_scorer_lane.sv`, `a7ng_pkg.sv`  
Oracle: `tests/xsim/termgen_oracle.py`, `golden_termgen.json` (32 vectors, varying priors)  
Contract: `docs/native_graph/CONTRACT_FREEZE.md` score law  
Schema: `rtl/native_graph/memory/MEM_SCHEMA_V1.md`  
Wiring cross-check: `a7ng_ddr_wavefront_top.sv`, `a7ng_wavefront_mig_top.sv`  
HLB: host grep `python/native_graph/`, TB preload classification

## PASS / FAIL

**PASS** — 104-bit descriptor frozen in `DESCRIPTOR_CONTRACT_FREEZE.md`.

## ARTIFACTS

| File | Purpose |
|------|---------|
| `DESCRIPTOR_CONTRACT_FREEZE.md` | Frozen authority |
| `AUDIT_descriptor_contract_00_hlb.md` | HLB audit |
| `RESULTS.md` | This summary |

## LIMITS

- No SOA RTL, no DDR byte measurement, no silicon  
- Cue 32→64 widen rule not unified (two delivery artifacts documented)  
- `ddr_cue_soa_00` must prove packed layout without dropping lawful fields  
- AI does not declare BOARD_PASS

## NEXT

Parent may queue `ddr_cue_soa_00` per `LOOP_STATE.json`.
