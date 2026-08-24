# M8-HW-02 — anti-hardcode remapping (next board proof)

**Status:** BOARD PASS 2026-08-14 (`results/M8-HW-02/run_003`).  
Two host sessions A→reset→B on `basys3_eight_agent_m8hw02.bit`. Still not conversation.  
**Depends on:** M8-HW-01 closed (`8_AGENT_CYCLIC_LEARNING_CONVERGENCE_DEMONSTRATED`).  
**Do not** run more cyclic TRAIN rings to satisfy this file.

Cyclic `0→1→2→…→7→0` is finished as a hardware scale-up. This milestone is
the first experiment that may claim **genuine associative learning**.

---

## Goal

On the **same** Basys 3, prove the 64-synapse matrix can:

1. learn a **random** session mapping A to 100% frozen accuracy;
2. **forget** A on reset (weights back to neutral, A behavior gone);
3. learn a **different** session mapping B to 100%;
4. dump **all 64** `W[d][s]` so the claim is not a single muxed cell.

Only then:

```text
8_AGENT_FULL_PARALLEL
GENUINE_ASSOCIATIVE_LEARNING
BOARD_VALIDATED
```

Still **not** conversation. Conversation stays a later host-side milestone
(`docs/ROADMAP_TO_SIMPLE_CONVERSATION.md` M8-2+).

---

## Protocol (must match UART evidence)

```text
SESSION A
  random mapping A  (permutation of 8 one-hot codes, not the cyclic +1)
        ↓
  EVAL_BEFORE       teacher off, learn=0  → accuracy near chance
        ↓
  TRAIN             teacher = A(source), learn=1
        ↓
  100% mapping A    EVAL_AFTER, teacher off
        ↓
  FREEZE            weights stop; dump all 64 W[d][s]
        ↓
  RESET             weights → diagonal 0, others 64
        ↓
  mapping A gone    EVAL: A targets fail / no leftover route
        ↓
SESSION B
  mapping B         permutation ≠ A and ≠ cyclic +1
        ↓
  RETRAIN
        ↓
  100% mapping B    EVAL_AFTER + freeze + dump 64 weights
```

### Mapping rules

- Mapping is a **session permutation** `dest = P[src]`, `P[i] ≠ i` preferred.
- Seed / permutation bytes must appear in UART so the host did not hard-code
  the teacher inside the bitstream as a ROM of answers.
- Illegal: `P = (i+1) mod 8` as the *only* on-board teacher (that is M8-HW-01).
- Illegal: initializing `W[P[s]][s]` to the target before TRAIN.
- Teacher legal **only** in TRAIN.

### Pass gates

| Gate | Pass if |
|------|---------|
| A EVAL_BEFORE | exact-match accuracy ≤ 25% (not already solved) |
| A EVAL_AFTER | 8/8 sources match `P_A` for a full frozen cycle |
| A freeze | `updates` and all 64 weights constant across ≥ 32 HOLD ticks |
| Reset forget | after reset, A-cycle exact-match ≤ 25% and no `W` remains at A’s trained rail |
| B EVAL_AFTER | 8/8 sources match `P_B` |
| A ≠ B | Hamming / permutation distance documented; B is not A and not cyclic +1 |
| 64-weight dump | every `W[d][s]` observed at A-HOLD, post-reset, and B-HOLD |

One failing gate ⇒ **not** `GENUINE_ASSOCIATIVE_LEARNING`.

---

## Required hardware / telemetry changes

Current board is insufficient for this proof:

| Gap | M8-HW-01 | M8-HW-02 need |
|-----|----------|----------------|
| Teacher | fixed cyclic +1 in `auto_trainer8` | session permutation register, loaded/seeded, not a semantic ROM |
| Inspect | one `W[dest][src]` via SW15:13 / SW8:6 | automatic dump of all 64 signed 16-bit weights |
| Reset | BTNU resets weights **and** restarts the same cyclic experiment | explicit RESET that forgets weights, then a **new** session seed |
| UART | `A5 5A` live + `A5 5C` result | add matrix dump, e.g. `A5 5D` pages |

### Suggested `A5 5D` dump (15-byte pages, same UART law)

Keep 15-byte frames so `tools/uart_monitor.py` stays simple:

```text
A5 5D page chkpayload...
page 0..15: four weights per frame (4 × int16 LE) + page index
16 frames × 4 = 64 cells, row-major W[d][s]
```

HOLD must emit a full dump at least once after A, after RESET, and after B.

7-seg may still show one inspect cell. Science is the 64-cell dump, not the mux.

---

## Software / host

- Python reference: random permutation sessions, reset-erases, retrain-B.
- Pytest **before** bitstream: Session A 100%, reset forgets, Session B 100%.
- Board scorer: parse `A5 5D`, print 8×8 matrix, compare to `P_A` / `P_B`.
- Do not accept “SW scan of 64 cells by hand” as the release evidence.

---

## Claim discipline

Until every pass gate has a COM8 log:

- Say **SPEC** or **RTL_PARSED** / **PYTEST**, never BOARD_VALIDATED
  for associative learning.
- Keep M8-HW-01 wording: cyclic convergence only.
- Do not mention conversation, Transformer, or LLM in the board verdict.
