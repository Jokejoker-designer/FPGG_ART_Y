# HANDOFF — paused 2026-08-19 (đi về làm tiếp)

**Bản bàn giao đầy đủ:** `results/A7-EAM-03E/BAN_GIAO_2026-08-19.md`

## Locked now

```
A7-EAM-02M          FROZEN / BOARD_PASS
A7-EAM-03E-A0       XSIM_PASS
                    SILICON_FUNCTIONAL_PASS_WITH_NOTES
                    TIMING_FAIL
                    SEED_ROBUSTNESS_FAIL
                    A1 CLOSED

A0.1-T              XSIM_PASS (goldens frozen)
                    TIMING_FAIL   WNS −0.119  TNS −0.407
                    not BOARD_PASS
```

## Bits to keep (do not overwrite 02M / 01R / LM)

| What | Path | SHA256 |
|------|------|--------|
| 02M frozen | `build/out/arty_a7_eam02m.bit` | `DB3BC58A6CC697FD0C290F97B5D6AD171AE7721A6C8A1E2DB2E87C5A84CFE696` |
| A0 (old, timing −1.891) | overwritten in `build/out`; SHA only | `12DD690C…8059783` |
| A0.1-T pacc | `results/A7-EAM-03E/a01t_pacc/` | `7E13CA749FC9189EBC9DACD0D73DEC43AA3B12F4B4D9CA50E7A749F3E9648421` |
| A0.1-T eupd **current** | `results/A7-EAM-03E/a01t_eupd/` **and** `build/out/arty_a7_eam03e.bit` | `ADD9E46280A697FD40C46911F5E477EF5B3A02EF36FE8054F9642216951C2262` |
| T RTL snapshot | `results/A7-EAM-03E/a01t_eupd/eam03e_core.sv` | — |

Board: Arty A7-100, Digilent `210319BE776EA`, COM12 115200.  
Goldens (seed `0x11111111`, 32 steps): 3930/5362 → **1093/2012** → reset 3930 → swap 451/1574.  
Seed `0x22222222`: `M = 229−1487 = −1258` (DIFF collapse).

## Plan locked (do not mix into T)

1. **A0.1-T** = timing only. Law `eam03e-a0-signsgd-v1`. If d1 moves = regression.
2. **Cosine** = EVAL telemetry only. TRAIN stays L1. Host may finish `cos` from `dot` + `n2sq`.
3. **A0.2-L** = new version (`docs/contracts/A7-EAM-03E-A02.md`). Combined triplet hinge  
   `L = max(0, d(A,P)−d(A,N)+m)` — not two independent PAIR updates.
4. Ablation: L0 baseline → L1 triplet → L2 cheap norm only if norms collapse → L3 cosine TRAIN only if needed.
5. Gate: `M_L1>0` **and** `M_cos>0`, worst-seed ≥ 0, no inversion. A1 stays closed.

## Resume next (in order)

1. Optional: program `a01t_eupd` bit, silicon-check goldens (32 steps, not STEPS=24). Still not BOARD_PASS.
2. Optional T close: pipeline `S_DIST` (`ad` registered then add) — path is now `i → d1_acc`. Do **not** change law.
3. Then A0.2: EVAL fields `d1,dH,n1,max_abs,mean_abs,dot,n2sq` on PAIR; then CMD `0x25` one-transaction triplet.
4. Do not glue 01R/02M. Do not open A1.

Contract already written: `docs/contracts/A7-EAM-03E-A02.md`.  
RTL for A0.2 **not started**. T source is the live `rtl/eam/eam03e_core.sv` (same as snapshot).
