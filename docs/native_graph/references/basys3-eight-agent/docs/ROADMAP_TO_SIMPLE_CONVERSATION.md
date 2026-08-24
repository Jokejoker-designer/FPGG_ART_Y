# Roadmap to simple learned conversation

Conversation remains a **later** milestone. The boarded default is an
8-agent cyclic route-gate SNN. Do not treat this file as the implemented
board top.

## M8-HW-01 — cyclic hardware scale-up (CLOSED 2026-08-14)

`8_AGENT_CYCLIC_LEARNING_CONVERGENCE_DEMONSTRATED`.
See `results/M8-HW-01_CLOSEOUT.md`. Stop cyclic rings.

## M8-HW-02 — anti-hardcode remapping (CLOSED 2026-08-14)

Board PASS, two host seeds. Frozen at `results/M8-HW-02/IMMUTABLE_20260814/`.
Do not overwrite `74F98993…`. Next is **M8-HW-03** dense 64-cell same-transaction.

## M8-HW-03 — dense full-parallel (NOW)

Contract: `docs/M8-HW-03_DENSE_CONTRACT.md`.
One dense TRAIN must report `changed_cell_count==64` and match Python.
New bitstream name only: `basys3_eight_agent_m8hw03.bit`.

## M8-0 — Full-parallel associative learner (legacy research RTL)
Legacy bipolar core (`rtl/legacy_bipolar/`). Not the board top.

Goal:
- 8 identical agents;
- 64 fully parallel plastic weights;
- arbitrary 8-bit distributed stimulus→response association learned from examples.

## M8-1 — Basys 3 physical bring-up

Superseded by the HW series:

- wrapper + cyclic UART + supervisor: **done** as M8-HW-01
- 64-weight dump + random remap + reset-forget: **M8-HW-02** (not boarded)

## M8-2 — Learned phrase prototypes (CLOSED as M8-HW-05 2026-08-14)

`PHRASE_BASIN_ASSOCIATION_BOARD_VALIDATED` on frozen `m8hw04.bit`.
Host encoder; two phrases → one basin; distractor / reset / remap. Not conversation.

Training corpus contains multiple utterances per response family.

Example training data may contain:

```text
"xin chào"
"chào bạn"
"hello"
```

but the FPGA is not told a HELLO intent ID.

The encoder supplies temporal/distributed spike patterns. Plastic weights must make
the examples converge toward the same learned response basin.

## M8-2b — Teacher-free single-turn (CLOSED as M8-HW-06A 2026-08-16)

`TEACHER_FREE_AFTER_TRAIN_SIMPLE_INTERACTION_BOARD_VALIDATED`.
AFTER: Teacher OFF, LLM 0, Learn OFF, Freeze ON, W SHA frozen.
Not conversation. Multi-turn is M8-HW-06B / M8-3 below.

## M8-3 — Context memory (CLOSED as M8-HW-06B 2026-08-16)

`SIMPLE_LEARNED_MULTI_TURN_CONVERSATION_BOARD_VALIDATED` on `m8hw06b.bit`.
FPGA holds ctx across turns. AFTER teacher-free. Name change / RESET / order negatives pass.

Add recurrent state/history so:

```text
"Tên tôi là Quân"
...
"Tôi tên gì?"
```

requires learned short-term state, not a fixed prompt table.

## M8-4 — Token sequence output (NOW M8-LM-01)

Contract: `docs/M8-LM-01_TOKEN_AR_CONTRACT.md`.
FPGA-held feedback until EOS. Host labels only. New bit `m8lm01.bit`.
Does not overwrite 06B. Board claim still open until XSim+COM8 PASS.

Teacher forcing is legal only in TRAIN.

## M8-5 — TSEC
Replace session code basis with learned temporal semantic event prototypes.
