---
name: a7-native-graph-gate
description: >-
  Operating gate for A7-NATIVE-GRAPH on Digilent Arty A7-100T. Read before any
  native_graph RTL, NG-00..NG-03 work, Vivado/Vitis MCP use on this lane, or
  Hugging Face low-bit inspiration. Trigger: native graph, NG-00, NG-01, 16-lane
  scorer, sparse relational attention, minesweeper prune, A7-NATIVE-GRAPH.
---

# A7 Native Graph — gate skill

## MUST READ FIRST

1. `MUST_READ_UNBLOCK_H5.md` (encoder lane still open — do not glue failed encoder)
2. `docs/NATIVE_AI_ARTY_A7_BLUEPRINT/04_HARDSTOPS.md`
3. `docs/native_graph/CONTRACT_FREEZE.md`
4. `docs/native_graph/AGENT_PLAN.md`

## Scope

New branch only: `rtl/native_graph/`, `docs/native_graph/`, `results/A7-NATIVE-GRAPH/`.

Do **not** overwrite frozen 01R / 02M / LM-06 / A0.3.

## First window

Historical: NG-00 → NG-03. **Live:** `15_CURSOR_BLUEPRINT_LOOP.md` + `LOOP_STATE.json`. Next = `ng05_persist` then NG-06. Do not stop at NG-05 XSim. GOAL = §14 `NATIVE_V1_MINI_AI_BOARD_PASS` (human).

## MCP

- Vivado: timing / util / bitstream readiness
- Vitis: host/UART only after silicon exists
- Hugging Face: inspiration tables only — never host EVAL answer path

## Dispatch (parent chat)

Parent is orchestrator. Implement via Cursor Task `subagent_type` = pipeline `character_id`.

```powershell
python .agents/workflows/native-graph/run_blueprint_loop.py --dispatch
```

Do not solo-edit `rtl/native_graph` in the parent. Verify agents may run in parallel after implement freeze.

## TRAIN-V2

If the change is a new learning law / representation / promotion / prune-that-learns:  
`docs/contracts/native_graph/A7-NATIVE-GRAPH-TRAIN-V2.md` — reset **learned state only**, freeze old model as control, **same** 20/40 facts first, two from-zero mappings.  
Plumbing-only (BRAM ping-pong, bit-exact Top-K, scheduler without learning-order change) = **no** retrain.

## Pass language

Physical lanes measured post-route. Logical agents reported separately.
Teacher-off exam: `teacher=0 external_LLM=0 learn=0 freeze=1`.
