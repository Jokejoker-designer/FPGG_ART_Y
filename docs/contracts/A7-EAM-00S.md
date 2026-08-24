# A7-EAM-00S — synthesis / implementation close

**Status:** PASS (2026-08-19). Evidence: `results/A7-EAM-00/gates_00s.json` (`pass:true`). Setup WNS +0.800 ns, TNS 0. Residual OOC hold WHS −0.002 ns is clock-skew (no `HD.CLK_SRC`); not a gate-5 fail.  
**Parent:** `A7-EAM-00.md` (`eam00-hamming-ema-v1`)  
**Part:** `xc7a100tcsg324-1`  
**Clock:** 100 MHz (`create_clock -period 10.000` on `clk`)  
**Mode:** out-of-context (no board pins, no bitstream, no LM-06 overwrite)

`A7-EAM-00S PASS` iff **all** of:

| # | Gate | Fail if |
|---|------|---------|
| 1 | `synth_design` PASS | synth errors |
| 2 | EAM store is mostly BRAM | RAMB36 + RAMB18/2 < 28 |
| 3 | no LUTRAM/FF explode | LUTRAM primitives > 32 **or** FF ≥ 12000 |
| 4 | large util margin | LUT ≥ 8000 **or** FF ≥ 8000 **or** BRAM36 ≥ 50 (of 135) |
| 5 | impl timing | WNS < 0 **or** TNS ≠ 0 |
| 6 | 100 MHz interface | clock period ≠ 10 ns **or** setup on `clk` fails |
| 7 | no relevant CWs | CRITICAL WARNING matching RAM collision / multiple drivers / clocking |
| 8 | post-synth funcsim | missing `A7EAM00_XSIM_PASS` (48 miss, 48 exact hit, eviction, AXI, epoch) |

Evidence: `results/A7-EAM-00/gates_00s.json` + util/timing rpts under `build/out/a7eam00s_*`.

Do not program the board. Do not write `arty_a7_lm*.bit`.
