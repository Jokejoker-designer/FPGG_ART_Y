# EXT-REPO-STUDY-ESP32-PLE-00

**Gate type:** Documentation-only external architecture research  
**Status:** PASS (research complete)  
**Date:** 2026-08-22  
**Parent:** a7-ng-orchestrator  
**Subagent:** [external-memory-architecture-researcher](bc583830-095c-47f5-8eef-6028cb030c01)

## Purpose

Study [chilly23/RP2040-and-ESP32-AI](https://github.com/chilly23/RP2040-and-ESP32-AI) as an
external architectural case study. Identify which implementation principles, measurement methods,
memory-hierarchy methods, verification methods, and workload-partitioning methods are technically
transferable to A7 Native AI.

**This is NOT a code-porting task.**

## External repository

| Field | Value |
|-------|-------|
| URL | https://github.com/chilly23/RP2040-and-ESP32-AI |
| Commit inspected | `0b6cc1ba76b31fb77ffcecf2d112d17729b53c7a` |
| Local read-only clone | `_external/` (gitignored from Native AI implementation) |

## Authority order (unchanged)

1. Native AI raw evidence  
2. Frozen Native AI contracts  
3. `LOOP_STATE.json`  
4. Audited Native AI closeouts  
5. Master Blueprint V2  
6. **This external research**  
7. Engineering inference  

**Master Blueprint wins** on any conflict. External findings do not override items 1–5.

## What this gate did

- Deep read of external repo (README cross-checked against code)
- Similarity / non-transferable classification
- Memory-pattern mapping to Native AI doctrine (interpretation only)
- Master Blueprint compliance matrix
- Post-Native-V1 PLE research section (RESEARCH_ONLY)

## What this gate did NOT do

- Copy external source code  
- Import RTL/C/Python  
- Modify Native AI algorithms or Master Blueprint  
- Modify `LOOP_STATE.json`  
- Start DDR-WAVEFRONT, LM06-WM, or any hardware gate  
- Approve PLE for Native V1  
- Declare Native V1 BOARD_PASS  

## Artifact index

| File | Role |
|------|------|
| `SUBAGENT_REPORT.md` | Preserved subagent handoff (raw technical report) |
| `REPO_TECHNICAL_AUDIT.md` | Structured audit (sections A–H, Q1–Q9) |
| `SIMILARITY_MATRIX.md` | Required similarity table |
| `MEMORY_PATTERN_MAPPING.md` | DDR_STREAM / DDR_SPARSE_RANDOM / BRAM / LUTRAM interpretation |
| `VERIFICATION_METHOD_MAPPING.md` | Golden export vs Native twin/oracle |
| `NON_TRANSFERABLE.md` | Explicit do-not-copy list |
| `MASTER_BLUEPRINT_COMPLIANCE.md` | Lesson → blueprint mapping |
| `FUTURE_RESEARCH_ONLY.md` | Post-Native-V1 PLE hypotheses |
| `SOURCE_MAP.md` | Claim → file → evidence classification |
| `CLOSEOUT.md` | Gate closeout |

## NEXT

**STOP.** No `LOOP_STATE` tick. No implementation follows automatically.
