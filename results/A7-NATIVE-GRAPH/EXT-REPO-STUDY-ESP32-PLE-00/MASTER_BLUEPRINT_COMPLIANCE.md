# MASTER_BLUEPRINT_COMPLIANCE — EXT-REPO-STUDY-ESP32-PLE-00

Maps each external lesson to Master Blueprint sections. Tags:

- **ALREADY_SUPPORTED** — doctrine already states this  
- **SUPPORTS_EXISTING_DOCTRINE** — external evidence reinforces  
- **POTENTIAL_EXTENSION** — future doc/gate idea; requires separate approval  
- **CONFLICT** — must not adopt without blueprint change  
- **OUT_OF_SCOPE** — not applicable to Native V1  

**Master Blueprint unchanged by this gate.**

---

## Compliance matrix

| Lesson from external repo | 01_SYSTEM | 08_MEMORY | 09_LM06 | 11_RESOURCE | 12_FAILURE | 14_CHECKLIST | Tag |
|---------------------------|-----------|-----------|---------|-------------|------------|--------------|-----|
| Partition memory by access pattern, not capacity alone | ✓ | ✓ | — | ✓ | — | ✓ | **ALREADY_SUPPORTED** |
| Stored params ≠ bytes touched per query | — | ✓ | ✓ | ✓ | — | ✓ | **ALREADY_SUPPORTED** |
| DDR_STREAM vs DDR_SPARSE_RANDOM subclass | — | ✓ | — | ✓ | — | — | **SUPPORTS_EXISTING_DOCTRINE** |
| Hot staging / ping-pong working set | ✓ | ✓ | — | ✓ | — | — | **ALREADY_SUPPORTED** |
| Decompose benchmarks (seq vs random) | — | ✓ | — | ✓ | ✓ | — | **ALREADY_SUPPORTED** (partial Native measure) |
| Bottleneck migration tracking | — | — | — | ✓ | ✓ | — | **SUPPORTS_EXISTING_DOCTRINE** |
| Golden on deployed representation | ✓ | — | — | — | ✓ | ✓ | **ALREADY_SUPPORTED** |
| MODEL-LAW vs PACKING test split | — | — | — | — | ✓ | ✓ | **POTENTIAL_EXTENSION** (doc only) |
| Core-matched ablation | ✓ | — | — | — | ✓ | — | **SUPPORTS_EXISTING_DOCTRINE** |
| Reduce movement before compute when DDR-bound | — | ✓ | — | ✓ | ✓ | — | **SUPPORTS_EXISTING_DOCTRINE** |
| PLE table for LM quality | — | — | ✓ | — | — | — | **CONFLICT** (Native V1) |
| PLE as post-V1 research | — | ✓ | — | — | — | — | **POTENTIAL_EXTENSION** |
| ESP32 tok/s as acceptance evidence | — | — | — | ✓ | ✓ | ✓ | **CONFLICT** |
| Flash XIP weight store | — | ✓ | — | — | — | — | **CONFLICT** |
| TinyStories / RP2040 display | — | — | — | — | — | — | **OUT_OF_SCOPE** |
| HNSW from PLE pattern | ✓ | ✓ | — | — | — | — | **POTENTIAL_EXTENSION** (research only) |

---

## Documented conflicts (not reconciled)

### CONFLICT-1: PLE model law in Native V1

- **External:** PLE is central to quality gains (RESULTS.md).  
- **Native:** LM-06 frozen; graph 01R/02M frozen.  
- **Resolution:** Master Blueprint wins. PLE → `FUTURE_RESEARCH_ONLY.md`.

### CONFLICT-2: Core in SRAM (planning) vs core in flash (deploy)

- **External:** `budget.py` vs RESULTS deployment tradeoff.  
- **Native:** LM weights DDR-resident; BRAM is working machinery — different hierarchy.  
- **Resolution:** Do not import flash-XIP core placement. Document as external-only tradeoff.

### CONFLICT-3: ESP32 performance as sign-off

- **External:** ~9.5 tok/s cited as achievement.  
- **Native:** §14 requires Native board evidence; human BOARD_PASS.  
- **Resolution:** OUT_OF_SCOPE for acceptance.

---

## Native facts preserved (unchanged)

| Fact | Authority |
|------|-----------|
| LM-06 weights DDR-resident | `00_CURRENT_AUTHORITY.md` §3 |
| ~132 BRAM working machinery | MEM-00 audit |
| 01R / 02M frozen | AGENTS.md |
| MIG-METRIC-00 XSim PASS | LOOP_STATE |
| mig_board_r2 BOARD_MIG PASS | CLOSEOUT_mig_board_r2 |
| ddr_wavefront_00 PASS_NARROW | LOOP_STATE |
| lm06_wm_00 PASS_NARROW | LOOP_STATE |
| HNSW research only | AGENTS.md |
| Native V1 NOT BOARD_PASS | LOOP_STATE goal |

---

## Blueprint modification policy

Any **POTENTIAL_EXTENSION** that changes doctrine requires a **separate future approval task**.
This research gate does not authorize blueprint edits.
