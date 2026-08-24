# A0.1-T attempt: pacc/MAC + registered EUPD

**Not BOARD_PASS. Timing not closed.**

| Item | Value |
|------|--------|
| Bit | `arty_a7_eam03e_a01t_eupd.bit` (copy of `build/out/arty_a7_eam03e.bit`) |
| SHA256 | `ADD9E46280A697FD40C46911F5E477EF5B3A02EF36FE8054F9642216951C2262` |
| WNS / TNS | **−0.119 / −0.407** ns @ 100 MHz |
| WHS / THS | +0.064 / 0 |
| LUT / FF / BRAM / DSP | 7653 / 7157 / 3 / **0** |
| xsim | `A7EAM03EA01T_XSIM_PASS` golden 3930/5362 → 1093/2012 → reset 3930 → swap 451/1574 |
| Frozen RTL snapshot | `eam03e_core.sv` in this folder |

Worst path: `i_reg → d1_acc` (S_DIST abs+add, 10.135 ns). EUPD path is no longer the limiter.

Do not overwrite frozen 02M/01R/LM bits. Do not use BOARD_PASS.
