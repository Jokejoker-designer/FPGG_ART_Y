# A0.1-T attempt: pacc/MAC pipeline only

**Not BOARD_PASS.**

| Item | Value |
|------|--------|
| Bit | `arty_a7_eam03e_a01t_pacc.bit` |
| SHA256 | `7E13CA749FC9189EBC9DACD0D73DEC43AA3B12F4B4D9CA50E7A749F3E9648421` |
| WNS / TNS | **−0.563 / −5.218** ns @ 100 MHz |
| WHS / THS | +0.062 / 0 |
| LUT / FF / BRAM / DSP | 7692 / 7174 / 3 / **0** |
| xsim | `A7EAM03EA01T_XSIM_PASS` golden 3930/5362 → 1093/2012 → reset 3930 → swap 451/1574 |

A0 was WNS −1.891 / TNS −990.6 (LUT 11010). Serializing 64-wide `pacc` and registering the MAC product improved TNS a lot; setup still fails.

Post-route worst path: `i_reg → gA/gB mux → sat8 → e_wd` (data 10.458 ns, 12 logic levels). Not projection. Next attempt registers `sgn_r` / `wdelta_r` before the write.
