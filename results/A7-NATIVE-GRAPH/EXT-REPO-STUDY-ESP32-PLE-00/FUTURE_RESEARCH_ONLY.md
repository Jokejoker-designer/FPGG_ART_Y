# FUTURE_RESEARCH_ONLY — POST-NATIVE-V1: SPARSE LEARNED ADAPTER RESEARCH

**Status flags (required):**

```text
RESEARCH_ONLY
NOT_NATIVE_V1
MODEL_LAW_CHANGE_REQUIRED
TRAINING_LAW_CHANGE_LIKELY
```

**This section does NOT approve any architecture. It preserves hypotheses.**

---

## 1. Conceptual question (from external PLE study)

Could a future Native AI architecture use a **large sparse DDR-resident learned table** keyed by
entity / topic / fact / evidence ID / relation type to inject small learned vectors into a
**fixed compute core**?

External repo demonstrates:

- Large table in cold store (flash)  
- O(1) row touch per token  
- Quality gain at matched dense core budget (RESULTS.md ablation)  

**Classification:** FUTURE_RESEARCH — not Native V1 evidence.

---

## 2. Native V1 boundaries (hard)

| Boundary | Rule |
|----------|------|
| LM-06 | Frozen semantics — do not modify |
| TRAIN-V2 | No silent law change |
| 01R / 02M | Frozen retrieval / episodic law |
| HLB | No host winner/answer/gradient |
| Native V1 scope | No PLE port |

---

## 3. Hypothetical research arms (not scheduled)

Mirror external ablation structure **only as methodology**:

| Arm | Purpose |
|-----|---------|
| baseline | Frozen core only |
| sparse_table | DDR table row per query key |
| table_notable | Isolate table plumbing |
| alt_injection | Bottom vs per-layer injection |
| bigcore | Spend table budget on wider dense core |

**Scarce resource held constant:** dense core budget, query set, PE count, Top-K, graph law.

---

## 4. Prerequisites before any experiment

1. Separate `law_id` — no LM-06 overwrite  
2. Teacher-off blind exam unchanged  
3. Measure `ddr_bytes_per_token` for table row vs baseline  
4. XSim golden before board  
5. HLB audit on host path  
6. Human approval of research branch  

---

## 5. Relationship to graph architecture

PLE pattern **rhymes with** sparse DDR Class B (random row fetch) but is **not** equivalent to:

- NodeRecord survivor fetch  
- Episode fetch  
- HNSW frontier (research-only datapath)  

Do not conflate PLE model law with graph record schema.

---

## 6. Low-bit LM staging (related, separate)

External int4 storage + int8 staged compute is **FUTURE_RESEARCH** for LM-06.

Native V1: `09_LM06_LOWBIT_OPTIMIZATION.md` remains authority; no active retune task from this gate.

---

## 7. Q8 answer

**Does this study justify adding PLE to Native V1?**

**NO.**

---

## 8. Preserved hypotheses (documentation only)

| ID | Hypothesis | Classification |
|----|------------|----------------|
| H-FR-01 | Access-pattern DDR subclasses improve experiment design | TRANSFERABLE_PATTERN |
| H-FR-02 | Random metadata DDR latency needs dedicated synthetic gate | ENGINEERING_INFERENCE |
| H-FR-03 | Post-V1 sparse adapter table may augment frozen core | FUTURE_RESEARCH |
| H-FR-04 | MODEL-LAW vs PACKING verification split reduces false failures | TRANSFERABLE_PATTERN |
| H-FR-05 | Core-matched ablation should be standard for memory architecture gates | SUPPORTS_EXISTING_DOCTRINE |

**Not scheduled. Not in LOOP_STATE.**
