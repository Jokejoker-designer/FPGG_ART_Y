# P2-TEACHER-OFF-SOC-XSIM-R1-LNFIX-00 — preregistration (before data)

**PROGRAM=NO.** Fast / no-MIG. No COM12 / JTAG / bit / full-chip / Gate14 / BOARD_PASS.  
Do **not** overwrite `P2-TEACHER-OFF-SOC-XSIM-00/` (G5 FAIL kept).  
Do **not** claim Teacher-Off / HS-02 / physical even if this XSim PASSes.

Parent G5: **FAIL_LM_ORACLE_MISMATCH** + **FAIL_LM_KNOWNNESS** (`OUT` 60/22/60/155 vs oracle 549/861/549/237; `x_ard=8196`).  
Cause closed later as **H1 LN token-boundary** (`LM06-LN-MU-TOKENBOUNDARY-01`): `ST_LN_O` skipped `ST_LN_S` for tok1–7.

## One unknown

With G1–G4 SHA unchanged, WMEM `C204E559…3001E0`, and patched core `75706E2C…E8EFB5FB`, does the **same** nine-cell Teacher-Off SoC XSim now produce unique LMST→LMDN, C9 pack match, OUT bit-exact **549 / 861 / 549 / 237**, and **consumed** `x_unknown=0`?

## Frozen oracle (copied, not reinvented)

| Query | pack | tokens | oracle OUT |
|-------|------|--------|------------|
| HOLD_A / HELD_A | `0706050403010002` | 2,0,1,3,4,5,6,7 | **549** |
| UNREL | `0f0e0d0c0b0a0908` | 8..15 | **861** |
| CONTRA | same as A | same | **549** |
| HOLD_B / HELD_B | `0f0e0d0c090b080a` | 10,8,11,9,12..15 | **237** |

Sanity `forward([1])=744` (CONTROL, not mixed with Native-V1 664).

## Knownness

Fail on **consumed** act-read X (NTOK8 `consume()`: states that sample `ard`).  
Print `ard_any` for honesty. Vacuous unread (no act reset, EMB_POS wait) is **not** FAIL. G5 attempt5 counted `ard_any`.

## If PASS

Call **`G5_XSIM_FUNCTIONAL` only**. Not Teacher-Off. Not HS-02. Not PASS_PHYSICAL. Not full-chip. Not cofit.

## If FAIL

Keep raw log. Do not patch law/weights/other stages in this gate.
