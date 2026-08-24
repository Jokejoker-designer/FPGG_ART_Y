# A7-LM-04 R4 — development (not confirmation)

R3 is `FAILED_CONFIRMATION_ORACLE`. This directory is for schedule development only.

- Tune on R2 + DEV_A/DEV_B.
- Do not read HELDOUT-R3 to choose a recipe.
- Do not create HELDOUT-R4 until `can_freeze=true`.
- `law_id` remains `lm05-signsgd-v1`.
- UART-mappable only (0x3A + host 0x34 order). Reuse `arty_a7_lm04r3.bit` if frozen.
- Do not program the board until R4 oracle PASSes once.

**Sealed 2026-08-18:** `NEGATIVE_RESULT.md`. No further schedule search. HELDOUT-R4 was not generated.
