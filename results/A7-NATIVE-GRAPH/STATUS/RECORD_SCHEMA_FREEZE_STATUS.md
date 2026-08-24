# RECORD_SCHEMA_FREEZE — status vs feedback §12 and SPEC §6.4

**feedback:** §12 — memory record schemas must be frozen  
**SPEC:** §6.4 — one authoritative layout; no magic strides in RTL/Python/frontend/TB  
**Gate `mem_schema_v1`:** **DONE_ENG** (PYTEST + XSIM)  
**Queue id `record_schema_freeze`:** **QUEUED** — repo-wide enforcement pass  
**Date:** 2026-08-22  

---

## 1. What is already frozen (evidence)

| Artifact | Role | Evidence class |
|----------|------|----------------|
| `rtl/native_graph/pkg/a7ng_mem_schema_v1_pkg.sv` | canonical sizes + `a7ng_*_byte_addr` | XSIM |
| `rtl/native_graph/include/a7ng_mem_schema_v1.h` | C header mirror | pytest text |
| `python/native_graph/mem_schema_v1.py` | Python serdes + goldens | PYTEST |
| `tests/native_graph/test_mem_schema_v1.py` | 10 round-trip tests | PYTEST |
| `tests/xsim/tb_a7ng_mem_schema_v1.sv` | SV size/addr golden | XSIM |

**Pinned layout:**

| Record | Bytes | version |
|--------|------:|---------|
| NodeRecordV1 | 16 | 1 |
| EdgeRecordV1 | 32 | 1 |
| EpisodeRecordV1 | 32 | 1 |

Primary SHA: `F0FE426EB7B6968392458F7377BB86D579F768FFE66ABE2A4D8E8FD8D57DEB85`  
Audit: `results/A7-NATIVE-GRAPH/MEM_SCHEMA_V1/AUDIT_mem_schema_v1.md`

---

## 2. feedback §12 checklist

| §12 requirement | Status | Note |
|-----------------|--------|------|
| NodeRecordV1 authoritative | **MET** | mem_schema_v1 |
| EdgeRecordV1 authoritative | **MET** | same |
| EpisodeRecordV1 authoritative | **MET** | same |
| exact byte size | **MET** | 16/32/32 |
| field offsets | **MET** | pkg + pytest goldens |
| endianness | **MET** | LE documented |
| alignment | **MET** | natural LE pack |
| version | **MET** | SCHEMA_VERSION=1 |
| golden serialize/deserialize tests | **MET** | pytest + XSim |
| no independent magic strides repo-wide | **PARTIAL** | see §3 |

**§12 verdict:** **PARTIAL** — core schema frozen; repo-wide consumer unification still QUEUED.

---

## 3. SPEC §6.4 — remaining gaps (why `record_schema_freeze` stays QUEUED)

| Gap ID | Location | Issue | Severity | Fix class |
|--------|----------|-------|----------|-----------|
| RS-01 | `a7ng_bram_hotset.sv` | inline `<<4` vs `a7ng_node_byte_addr()` | MINOR | follow-up RTL (not re-open mem_schema_v1) |
| RS-02 | `a7ng_pkg.sv` | duplicates 16/32/32 literals vs schema pkg | MINOR | import from `a7ng_mem_schema_v1_pkg` |
| RS-03 | repo-wide | no CI gate that fails on new magic stride | OPEN | `record_schema_freeze` gate |
| RS-04 | frontend / loader | not audited in mem_schema_v1 | OPEN | grep + tests in freeze gate |
| RS-05 | MIG/wavefront path | uses NodeRecordV1 16 B consistently | **MET** | MIG-METRIC-00 / wavefront TB |

Auditor: **allow_loop_done_eng=true** for `mem_schema_v1` — MINOR items do not falsify freeze.

---

## 4. Relationship to other gates

| Gate | Schema role |
|------|-------------|
| MIG-METRIC-00 | 16 B stride self-consistent RTL↔TB |
| ddr_wavefront_00 | cue offsets from schema pkg in `a7ng_cue_wave_stage.sv` |
| lm06_wm_00 | orthogonal (LM tile law) |
| record_schema_freeze | close RS-01..RS-04 without changing sizes |

---

## 5. `record_schema_freeze` gate scope (when dispatched)

**ONE unknown:** Are all production paths consuming `a7ng_mem_schema_v1` helpers with zero drift?

**In scope:**

- grep audit RTL/Python/TB/loader for orphan strides  
- wire hotset to `a7ng_node_byte_addr`  
- unify `a7ng_pkg` with schema pkg  
- optional CI script  

**Out of scope:**

- changing record sizes or field layout (law change)  
- BOARD_PASS claim  

---

## 6. Masterplan alignment

| Doc | Alignment |
|-----|-----------|
| `08_MEMORY_ARCHITECTURE.md` | DDR records — sizes consistent |
| `14_FINAL_ACCEPTANCE_CHECKLIST.md` | persistent graph DDR-backed — needs schema authority |
| `02_IMPLEMENTATION_ROADMAP.md` | mem_schema_v1 DONE_ENG; freeze QUEUED |

---

## 7. NEXT

**STOP** — documentation only. Queue remains `QUEUED` in `LOOP_STATE.json`.

Update `COMPLIANCE_GAP_REGISTER.md` G-P2-05 when freeze gate closes.
