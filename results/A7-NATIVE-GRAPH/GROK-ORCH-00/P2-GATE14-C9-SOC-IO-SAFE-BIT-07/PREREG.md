# P2-GATE14-C9-SOC-IO-SAFE-BIT-07 — preregistration

**PROGRAM=NO. No COM12 program. No JTAG program.**

Parent `P2-GATE14-C9-SOC-COFIT-BIT-06` XSim/timing/CDC accepted. Bit `B0F64E6C` **rejected for programming** because `ja[7:0]` had NSTD-1 and UCIO-1 and the build waived those checks.

Frozen oracle SHA `062932B3853144526B1C9A42C2076966C45EF108C707546C68C9BC89754C912B`.
HOLD_A=653 UNREL=689 CONTRA=237 HOLD_B=60.

## Unknown (one)

If production SoC top has **no** `ja[7:0]` port (Pmod LA was E2R debug, not Gate14 UART acceptance) and write_bitstream runs **without** NSTD-1/UCIO-1 severity downgrade, do NSTD-1 and UCIO-1 both equal 0 while C9 learned packs/OUT stay 653/689/237/60?

## JA decision

JA is **not** required for Gate14 acceptance (UART CFRAME + TinyGPT). Resolution: **remove** from production top. Do not add unconstrained debug replacement. Do not apply `e2r_la_pmod_ja.xdc`. Known official mapping (unused): Digilent Arty A7-100T Pmod JA in `constraints/e2r_la_pmod_ja.xdc` (G13/B11/A11/D12/D13/B18/A18/K16 LVCMOS33).

## Must not

Program. COM12 substitute. Reuse B0F64E6C / A0B338E0. Waive NSTD-1/UCIO-1. Second scorer/TopK/LM. Edit ORACLE. 40 facts. Self GATE14_PASS / BOARD_PASS.
