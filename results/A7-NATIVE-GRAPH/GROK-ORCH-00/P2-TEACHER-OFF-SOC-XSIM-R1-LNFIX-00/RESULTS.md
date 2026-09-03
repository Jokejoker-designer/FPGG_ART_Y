# P2-TEACHER-OFF-SOC-XSIM-R1-LNFIX-00 — RESULTS

**PROGRAM=NO.** Fast / no-MIG. No COM12 / JTAG / bit / full-chip / Gate14 / BOARD_PASS.  
XSim ≠ board. **NOT** Teacher-Off. **NOT** HS-02. **NOT** §14. **NOT** cofit.

Parent G5 bag `P2-TEACHER-OFF-SOC-XSIM-00/` **not overwritten**.  
G1–G4 / glue / wrapper / bind / WMEM SHA **unchanged**. Core is LN-FIX `75706E2C…E8EFB5FB`.

Oracle frozen **before** this XSim (copied G5 packs/OUT, python re-verified): HOLD_A **549**, UNREL **861**, CONTRA **549**, HOLD_B **237**. Sanity `forward([1])=744`.

## Verdict

**G5_XSIM_FUNCTIONAL** — nine cells, four unique LMST→LMDN, C9 pack match, OUT bit-exact vs frozen oracle, consumed `x_unknown=0`.

Do **not** call Teacher-Off. Do **not** call PASS_PHYSICAL. Glue OOC from G5 is glue-only and was **not** re-run.

## Parent FAIL (preserved)

G5 attempt5 `unit_xsim_attempt5_oracle_mismatch.log` SHA `47B3EADA…707EDC`  
OUT **60 / 22 / 60 / 155** vs 549 / 861 / 549 / 237. `x_ard=8196` (any). Unique LMST, C9 match, MODE 5→8 — framing only.

Cause: H1 LN token-boundary (`LM06-LN-MU-TOKENBOUNDARY-01`). Attempt4 `OUT=0` under X remains **PASS_NARROW_FRAMING / FAIL_LM_KNOWNNESS**.

## This XSim

`unit_xsim.log` SHA `0EE06C9A…95A1AF5D`  
Marker: `TEACHER_OFF_SOC_XSIM_PASS fails=0 CELLS=9 LM_KNOWN`  
Vivado 2026.1 snapshot `g5r1_s00`. Wall ~4 min 14 s sim. `$finish` 7369785160 ns.

```text
WMEM_INIT ok n=802816 readback0=-6
CELL_LIVE_MODE PASS MODE=8 DROP=5
X_UNKNOWN wrd=0 ard_any=8196 ard_consumed=0 acc=0 logit=0 pred=0 lmst_rise=5
```

| Query | C9 pack | C10 LMST LMDN | FPGA OUT | oracle | LMST rise |
|-------|---------|---------------|----------|--------|-----------|
| HELD_A | `0706050403010002` MATCH | 1 1 | **549** | 549 | 1 unique |
| UNREL | `0f0e0d0c0b0a0908` MATCH | 1 1 | **861** | 861 | 2 unique |
| CONTRA | `0706050403010002` MATCH | 1 1 | **549** | 549 | 3 unique |
| HELD_B | `0f0e0d0c090b080a` MATCH | 1 1 | **237** | 237 | 4 unique |

Same pack → same OUT (A=CONTRA=549). Different pack → different OUT. Not sticky. Not default 0. L0 N1 tok1 now μ=0 q=−20 (was −16 / μ=−1 on G5).

`lmst_rise=5` includes the extra `T_HOLD_A` fire after B exam (not an oracle cell). Four exam queries each rose once.

## Knownness

| Counter | Value | Gate |
|---------|------:|------|
| wrd / acc / logit / pred X | **0** | PASS |
| `ard_consumed` | **0** | PASS |
| `ard_any` | 8196 | NOTE only — vacuous unread, act RAM has no reset (same count as G5 attempt5) |

G5 FAIL_LM_KNOWNNESS used `ard_any`. This gate fails only **consumed** X, per NTOK8 / Codex.

## Nine cells

| Cell | Result |
|------|--------|
| LIVE_MODE 5→8 DROP=5 | PASS |
| UPDATED_EVIDENCE (held A rank/score, R1R) | PASS |
| LM_ACTIVE OUT=oracle | PASS |
| NATIVE_ANCHOR A≠U | PASS |
| HELD_OUT_EXAM_A | PASS |
| HOST_INGRESS_ZERO (cue/win/addr/tok/w/mode=0, mem_we_exam=0) | PASS |
| STUB_NOT_PASS (`D65F3524` cited, TinyGPT used) | PASS |
| BLIND_EXAM_B | PASS |
| SCALE_20_THEN_40 `ran_40=0` | PASS |

## Source SHA (abbrev)

| Item | SHA256 |
|------|--------|
| core AFTER LN-FIX | `75706E2C…E8EFB5FB` |
| WMEM | `C204E559…3001E0` |
| G1 G2 G3 G4 | `2219DA29` / `06143862` / `2177073D` / `D1BF0340` **unchanged** |
| glue / wrapper / bind | `7FECB8B8` / `91BA26AE` / `C5F57AD1` **unchanged** |
| G5 core BEFORE | `29D230FC…` (cite) |

## Synth / resource / timing

**Not this gate.** Glue OOC LUT123/FF231 remains G5 bag, glue-only, not re-measured. SIM_FULL=1 core is not silicon. No full-chip.

## STOP

**G5_XSIM_FUNCTIONAL.** Teacher-Off / HS-02 / BOARD_PASS / physical / cofit **not** opened.  
PROGRAM=NO.
