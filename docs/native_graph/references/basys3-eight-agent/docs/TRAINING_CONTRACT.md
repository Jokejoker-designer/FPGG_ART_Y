# Training contract — no prewired answers

## Legal

- Random/session-remapped stimulus codes.
- Teacher output codes during TRAIN.
- Repeated examples from a user-defined corpus.
- Reward/error signals.
- Plasticity hyperparameters.
- Neutral signal bases / encodings.
- Host-side display strings for human-readable I/O.

## Illegal

- `if input == HELLO: output = HELLO_REPLY`
- initialized route weights encoding desired responses;
- Agent 0 permanently designated "greeting";
- response ROM indexed by prompt intent;
- enabling teacher during EVAL_AFTER;
- preserving learned weights across a claimed "from scratch" reset test.

## Required proof (M8-HW-02 — not yet boarded)

A **genuine associative** release must include at least:

1. BEFORE: mapping not already solved.
2. TRAIN: updates > 0.
3. FREEZE: weights stop changing.
4. EVAL_AFTER: target mapping succeeds with teacher disabled.
5. RESET: behavior disappears.
6. RETRAIN: a different randomized mapping succeeds.
7. UART dump of all 64 `W[d][s]` at A-HOLD, post-reset, and B-HOLD.

M8-HW-01 only satisfied a **fixed cyclic** subset of 1–4.
It does **not** satisfy 5–7.
