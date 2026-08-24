# Authority ingest — BRAM_RESET_RETRAIN_PLAN.md

**Ingested:** 2026-08-22  
**Source:** `BRAM_RESET_RETRAIN_PLAN.md` (`A7-NATIVE-BRAM-RESET-v1`, DESIGN SPEC / NOT BOARD AUTHORITY)

## Why this exists (Anh’s concern)

If BRAM is truly too tight, the wrong reaction is:

```text
wipe everything / rebuild from zero / overwrite frozen bits / lose NG-* archives
```

The correct reaction is:

```text
logical invalidation + DDR as long-term store + phase-share BRAM + preserve frozen law
```

**Physical remnants do not matter if they have no authority.**  
**Do not sacrifice project evidence or LM-06 backbone to free a few tiles.**

## Central rule (memorize)

```text
FAST RESET  = epoch + generation + pointer invalidation
SLOW RESET  = parallel BRAM scrub + DDR learned scrub + VERIFY
```

Do **not** physically zero all BRAM on every query/session reset.

## Four reset levels (do not conflate)

| Level | Name | What goes | What STAYS |
|------:|------|-----------|------------|
| 0 | QUERY | current working set via `query_epoch++` | graph, episodes, LM-06, frozen RTL |
| 1 | SESSION | context/frontier/Top-K/queues | persistent learned knowledge, LM-06 |
| 2 | TRAINING | `training_generation++` → old gen invisible | frozen LM-06 backbone; physical DDR may linger |
| 3 | HARD | scrub trainable BRAM + learned DDR + VERIFY | **LM-06 frozen weights MUST keep** |

## Fields every work item must carry

```text
query_epoch (>=16b)
path_epoch (>=16b)
training_generation (>=32b)
logical_agent_id
```

Valid only if `valid && epoch match && generation match`.

## What must NEVER be lost when BRAM is tight

1. **Frozen bitstreams / SHA locks:** LM-06, 01R, 02M, A0.3 — never overwrite.  
2. **Archived NG evidence trees:** NG-02, NG-02R-TOPK, NG-02R-FLOW, …  
3. **Law IDs already proven:** e.g. `a7ng-topk-global-v1`.  
4. **DDR map regions** once frozen in a versioned memory map.  
5. **Trainable vs immutable split:** knowledge reset ≠ backbone erase.

Tight BRAM → use WM phase-share / DDR spill / smaller working sets (`A7-BRAM-WM-*`), **not** project amnesia.

## Ownership during reset

```text
BRAM_OWNER_GRAPH | BRAM_OWNER_LM | BRAM_OWNER_RESET
exactly one writer authority per bank per cycle
```

## Implementation sequence (after correctness)

```text
PHASE1 Top-K+flow (DONE_ENG)
PHASE2 query/path epoch          ← aligns ng06_epoch / ng04_stale_event
PHASE3 training_generation
PHASE4..6 Query/Session/Train reset
PHASE7 BRAM Reset Owner FSM
PHASE8..10 parallel scrub + DDR scrub + VERIFY
PHASE11 A→reset→B board proof (A7-NATIVE-RESET-00)
```

Do **not** start with a giant physical wipe.

## Milestone when unblocked

```text
A7-NATIVE-RESET-00
TRAIN A → teacher-off retrieve A
HARD RESET → RESET_VERIFY_PASS
teacher-off: A must NOT retrieve
TRAIN B → retrieve B; A must not leak
```

Plus mapping-swap: `X→A` then hard reset then `X→B` → query X yields B only.

## Hard stops (instant FAIL / DESIGN ERROR)

- Reset with outstanding DDR write and no commit/abort policy  
- PE still mutating learned state during reset  
- Old generation visible after reset  
- Query N pollutes N+1  
- `RESET_DONE` before verify  
- Hard reset PASS but stale fact still retrievable  
- **Reset wipes frozen LM-06 backbone → DESIGN ERROR**  
- Dual BRAM bank writers same cycle  

## Loop placement

- Gate id: `reset_00` (BLOCKED until epochs land)  
- Owner: `a7-ng-memory-arch` (+ scientific for matrix)  
- Does **not** replace current OPEN `ng06_wide_dispatch`  
- Complements `BRAM_WORKING_MEMORY_SPEC.md` and `feedback.md` R6/R8
