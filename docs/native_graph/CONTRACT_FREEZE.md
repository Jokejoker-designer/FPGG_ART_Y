# A7-NATIVE-GRAPH — Contract Freeze (NG-00)

**Status:** FROZEN for NG-00 schemas  
**Date:** 2026-08-21  
**Board:** Arty A7-100T only (not Basys3, not PYNQ)

## Frozen schemas

| Contract | Path |
|----------|------|
| Teacher lesson | `docs/contracts/native_graph/teacher_lesson.schema.json` |
| Telemetry | `docs/contracts/native_graph/telemetry.schema.json` |
| Hard stops | `docs/NATIVE_AI_ARTY_A7_BLUEPRINT/04_HARDSTOPS.md` |
| Blueprint system | `docs/NATIVE_AI_ARTY_A7_BLUEPRINT/01_SYSTEM_BLUEPRINT.md` |
| TRAIN-V2 retrain | `docs/contracts/native_graph/A7-NATIVE-GRAPH-TRAIN-V2.md` (`law_id=a7ng-train-v2`; harness archive `results/A7-NATIVE-GRAPH/TRAIN-V2/`) |

## Train / Eval state machine

```text
IDLE → TRAIN → AUDIT → BLIND_EXAM → FREEZE
                 ↑______________|
```

| Phase | teacher | learn | freeze | Host may send |
|-------|---------|-------|--------|---------------|
| TRAIN | 1 | 1 | 0 | query + supervision rewards (−3…+3) |
| AUDIT | 1 | 0 | 0 | query + optional reward (no attention hint) |
| BLIND_EXAM | 0 | 0 | 1 | query text / tokens only |
| FREEZE | 0 | 0 | 1 | nothing that mutates state |

## Forbidden native fields (all phases → host must never send)

```text
gradient, delta_weight, winner, address, hash, next_token, final_answer
```

In BLIND_EXAM additionally forbid:

```text
entity, intent, context, candidate_ranking, relation_path
```

## Score law (observable integer terms)

```text
Score = EntityMatch + IntentMatch + RelationMatch
      + ContextMatch + PathConfidence + LearnedPrior
      - ContradictionPenalty
```

Saturation arithmetic. No float in NG-01.

## Lane claim language (HS-09)

Allowed after NG-01 post-route:

> 16 physically parallel scorer lanes

Forbidden until measured:

> 256 / 8000 physically parallel AI cores

## Anti-leak tests

Location: `tests/native_graph/test_ng00_anti_leak.py`  
PASS criteria listed in `TEST_MATRIX.md`.

## Frozen artifact protection

Do not overwrite SHA-locked bits for A0.3 / 01R / 02M / LM-06. Graph RTL lives under `rtl/native_graph/` only.
