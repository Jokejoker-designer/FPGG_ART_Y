# A7-EAM-03E-A0 silicon

**Functional verdict:** `A7EAM03EA0_PASS_WITH_NOTES`  
**Timing:** **FAIL** WNS **−1.891** ns / TNS −990.6 ns @ 100 MHz. Not BOARD_PASS.  
**Bit:** `arty_a7_eam03e.bit` SHA `12DD690C9DE6175E9C7E807666ADAC09046C65CDAE97CA6C974D803CB8059783`  
**Util:** LUT 11010, BRAM 2.5, **DSP 0**  
**Device:** Digilent `210319BE776EA` COM12

Integer distances on board **match xsim** on seed `0x11111111` (d1 AB 1093 / AC 2012 / reset 3930). The 100 MHz violation did not scramble this FSM, but the bit is **not** timing-closed.

## Gates

| Check | Result |
|-------|--------|
| SAME d1 shrinks (seed 0x11111111) | 3930 → **1093** |
| After train, DIFF d1 > SAME | AC **2012** > 1093 |
| RESEED erases | AB back to **3930** |
| Swapped labels (OMEGA=SAME) | AC **983** < AB **1986** |
| Second seed SAME shrinks | 2135 → 1487 |

## Notes (why not clean PASS / why A1 stays closed)

1. Seed `0x22222222`: SAME shrinks, but DIFF (AC) collapses to **229** < SAME 1487. Encoder can move distances; it does **not** keep DIFF far on every seed.
2. Train-pair `dH` on map0 went 5→3. That is **not** unseen-cue retrieval.
3. WNS −1.891. Next A0.1 must pipeline the 64-wide `pacc` / MAC before any BOARD_PASS language.
4. Host sent only bytes + SAME/DIFF. No hash, gradient, weight, or 01R winner.

**A1 not opened.** Stop rule: do not glue 01R/02M to hide a seed that inverts DIFF.
