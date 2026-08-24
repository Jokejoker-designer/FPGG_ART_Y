# 15 — Cursor Blueprint Loop (until GOAL)

This file is **authority** for how Cursor must work on this repo.  
It does **not** replace `01`–`14`. It forces those files to be re-read every session.

**Product GOAL** is only:

```text
NATIVE_V1_MINI_AI_BOARD_PASS
```

defined in `14_FINAL_ACCEPTANCE_CHECKLIST.md`.  
Human declares BOARD_PASS. AI archives evidence. AI does not self-award the stamp.

## 1. Re-read pack (every session, before any edit)

Read **in full**, not a remembered summary:

```text
docs/NATIVE_AI_ARTY_A7_BLUEPRINT/README.md
docs/NATIVE_AI_ARTY_A7_BLUEPRINT/01_SYSTEM_BLUEPRINT.md
docs/NATIVE_AI_ARTY_A7_BLUEPRINT/02_IMPLEMENTATION_ROADMAP.md
docs/NATIVE_AI_ARTY_A7_BLUEPRINT/04_HARDSTOPS.md
docs/NATIVE_AI_ARTY_A7_BLUEPRINT/13_CURSOR_MASTER_PROMPT.md
docs/NATIVE_AI_ARTY_A7_BLUEPRINT/14_FINAL_ACCEPTANCE_CHECKLIST.md
docs/native_graph/CONTRACT_FREEZE.md
results/A7-NATIVE-GRAPH/STATUS/LOOP_STATE.json
results/A7-NATIVE-GRAPH/STATUS/RECONCILIATION_FEEDBACK_SPEC_vs_MASTERPLAN_V2.md
results/A7-NATIVE-GRAPH/STATUS/FEEDBACK_MD_COMPLIANCE.md
results/A7-NATIVE-GRAPH/STATUS/BRAM_WORKING_MEMORY_SPEC_COMPLIANCE.md
feedback.md
BRAM_WORKING_MEMORY_SPEC.md
```

Historical snapshot only (superseded): `results/A7-NATIVE-GRAPH/STATUS/RECONCILIATION.md`

First output line of every Native Graph session:

```text
BLUEPRINT_LOOP: read. Goal=NATIVE_V1_MINI_AI_BOARD_PASS. Next=<id from LOOP_STATE.json>
```

If `LOOP_STATE.json` is missing, Next = first unresolved stage in `02_IMPLEMENTATION_ROADMAP.md` (currently NG-05 persist, then NG-06). Do not invent a new goal.

## 2. Loop (non-optional)

```text
WHILE NATIVE_V1_MINI_AI_BOARD_PASS is not evidenced in 14_*:

  0. Re-read pack in §1 (do not skip because "I already know").
  1. Take FIRST unresolved gate from LOOP_STATE.queue (skip only DONE with archived SHA).
  2. One unknown. Smallest patch. No glue of two stages.
  3. Run that stage's tests. Archive results/A7-NATIVE-GRAPH/<STAGE>/.
  4. Log: GATE / CHANGED / WHY / TESTS / EXPECTED / ACTUAL / PASS|FAIL / ARTIFACT / SHA256 / NEXT.
  5. PASS → start NEXT queue item in the SAME session. Do not stop for applause.
  6. FAIL → STOP DOWNSTREAM, DO NOT STOP WORK:
       reproduce → freeze evidence → isolate → one falsifying experiment
       → justified fix → regress → retest
       until A or B or C:
         A. gate PASSES
         B. hypothesis FALSIFIED with archived numbers
         C. physical/tool LIMIT proven and written
  7. Do not wait for the user. Do not end the turn after a status table.

END WHILE
```

Then write `results/A7-NATIVE-GRAPH/PROJECT_COMPLETE.md` with the §14 table filled from **files**, and stop. Human may then declare `NATIVE_V1_MINI_AI_BOARD_PASS`.

## 3. Illegal stops (cheat, not GOAL)

- Ending after NG-05 XSim / NG-03 bit / “pipeline PASS”
- Ending after writing agents, skills, or this loop file
- Ending because `13_CURSOR_MASTER_PROMPT.md` said “NG-00..NG-03 only” — that **window is over**
- Ending to ask which next stage — the queue is `02` + `LOOP_STATE.json`
- Calling a report, screenshot, or GlassBox the deliverable
- Glue encoder H5 failure into graph PASS by renaming
- Continue TRAIN on old learned graph after a **Yes** row in `A7-NATIVE-GRAPH-TRAIN-V2.md`
- Delete the old model instead of freezing it as control
- Change learning law and curriculum in one experiment
- Jump to 800k before 20- and 40-fact teacher-off PASS
- Declaring BOARD_PASS

## 4. Legal yield (pause, then resume **this** loop)

- Board unplugged — after XSim + impl + archive; write `WAITING_BOARD.md` with exact program command
- License / Vivado crash you cannot repair
- Two irreconcilable **authorities** (file/line), not two opinions

Hardware absence does **not** pause host tests, XSim, twin, schemas, or MEM audits.

## 5. Encoder lane (parked, not the loop exit)

`MUST_READ_UNBLOCK_H5.md` applies when editing `rtl/eam`, `python/eam`, `A7-EAM-03E`.  
It does **not** redefine Native V1 GOAL. It does **not** authorize stopping the graph loop.  
Do not overwrite frozen 03E / 01R / 02M / LM-06 bits. Do not glue a collapsed encoder into NG.

## 6. Queue authority

Order comes from `02_IMPLEMENTATION_ROADMAP.md`:

```text
NG-00 … NG-09 → MEM-00…02 → LM-Q0… → integrate → teacher-off exam → §14
```

`13_CURSOR_MASTER_PROMPT.md` first window (NG-00..03) is **historical**. After NG-05 XSim, the live Next is whatever `LOOP_STATE.json` says.

## 7. Dispatch law (parent ≠ implementer)

Cursor **parent** chat is `a7-ng-orchestrator`. It does **not** write RTL.

```text
python .agents/workflows/native-graph/run_blueprint_loop.py --dispatch
→ Task subagent_type=<pipeline character_id>   # implementer
→ Task subagent_type=a7-ng-xsim-verify         # parallel after RTL freeze
→ Task subagent_type=a7-vivado-gate
→ Task subagent_type=a7-evidence-auditor
→ if PASS: --dispatch next OPEN item, same session
```

`character_id` comes from `.agents/workflows/native-graph/pipeline.json`, crew from `registry.yaml`.  
Do not invent agents. Do not skip Task. Two implementers on two gates at once = illegal (one unknown).  
Verify agents **may** run concurrent **after** the implementer freeze. GlassBox agents stay out.

Each implementer appends one line to `results/A7-NATIVE-GRAPH/STATUS/DISPATCH_LOG.jsonl`.  
Auditor rejects PASS if that line’s `gate`/`agent` mismatch the queue.

## 8. Session output shape

Lead with **work**, not a 6-section essay.

```text
BLUEPRINT_LOOP: read. Goal=NATIVE_V1_MINI_AI_BOARD_PASS. Next=<id>

GATE:
CHANGED:
WHY:
TESTS:
EXPECTED:
ACTUAL:
PASS/FAIL:
ARTIFACT:
SHA256:
NEXT GATE:   (already started unless legal yield)
```
