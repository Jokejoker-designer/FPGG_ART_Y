# SILICON READOUT — G14-EPOCH-REBIRTH-BIT-00

```text
READY_TO_PROGRAM = YES
PROGRAM          = NO
GATE14_PASS      = NO
REBUILD          = NO
RTL_EDIT         = NO
```

Board run 2026-09-03: E0–E5 **all exact**. CLASS=`EPOCH_CHAIN_CLOSED_ON_BOARD`.
`GATE14_PASS` remains **NO**. Program count = 1. Do not reprogram.

See `BOARD/RESULTS.md`.

---

## What this experiment is (and is not)

**Not:**

```text
same physical placement
+ one RTL file changed
```

**Exactly:**

```text
same frozen functional graph / LM / data path
+ one intended functional law change: epoch object
+ observability-only TOP delta
+ new physical implementation
```

TOP `F395B1BB` → `31EEE943` (`df16ff1`) adds RST UART LUT/FF, so placement
is **not** identical to fail bit `3A7EF204`. That does **not** break the
causal experiment. It does forbid this inference:

> GEN is now legal, therefore every later failure is caused by epoch.

If GEN is repaired and a **new unrelated** failure appears, stop at first
divergence. Do not auto-blame epoch. See `DELTA_FROM_3A7EF204.md`.

This run tests a **specific causal hypothesis**. It is not
“program and see whether the AI runs.”

---

## Hypothesis under test

Historical silicon `3A7EF204`:

```text
dirty DDR
   ↓
illegal epoch FFFFFFFF
   ↓
wrong visibility / incomplete semantic commits
   ↓
wrong C9
   ↓
OUT 748
```

This bit `1F0F2ABB`:

```text
epoch verify / REBIRTH
   ↓
legal GEN
   ↓
20 intended architectural commits
   ↓
correct learned-state visibility
   ↓
C9 oracle
   ↓
OUT 653
```

---

## Five checkpoints (stop at first fail)

```text
E0  BOOT
 ↓
E1  GEN legal
 ↓
E2  semantic commit state correct
 ↓
E3  HOLD_A C9 = 8382238122802120
 ↓
E4  OUT = 653
 ↓
E5  U/C/B = 689 / 237 / 60
```

| Fail at | Boundary opened | Do not conclude |
|---------|-----------------|-----------------|
| E1 GEN = `FFFFFFFF` / illegal | epoch object **NOT** closed on silicon | nothing downstream |
| E1 legal, E2 commit state wrong | learning / commit theorem | “epoch is fine, keep going” |
| E2 exact, E3 C9 wrong | query-visible state / retrieval | bind/LM |
| E3 exact, E4 OUT ≠ 653 | bind / LM path | retarget oracle |
| E0–E5 all exact | historical P_BOOT/epoch causal chain **CLOSED ON BOARD** | `GATE14_PASS` |

E5 is scored only after E4. Full E0–E5 match still leaves Gate14 teacher-off,
reset/retrain, persistence identity, LM active-chain, and the rest of the
acceptance checklist **open**. `GATE14_PASS` stays `NO`.

---

## Forbidden after program if the UART looks strange

Do **not**:

- program a second time
- reset and retry
- change command spacing
- add delay
- regenerate the bit
- patch the UART decoder and treat the old capture as a new run

Keep the raw capture. SHA256 it. Name the first divergence **before**
any follow-up.

---

## Non-blocker (do not touch before board)

PR #9 GitHub **body** still contains the historical
“Unique bitstream not closed / PHYS blocked” prose. Title, head commit
`1710295`, and archived `BLOCKER.md` already supersede that. Leave the
body until after this program.
