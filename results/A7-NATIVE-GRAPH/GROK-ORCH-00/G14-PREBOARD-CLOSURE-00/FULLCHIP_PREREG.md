# PREREG — full-chip SoC XSim after epoch law

```text
PROGRAM = NO
GATE14_PASS = NO
```

Human approved epoch object + wrap REBIRTH (PR #8 merged `c773dc44`).

Hypothesis (one unknown = epoch law on frozen BIT-07 DUT/TB):

```text
H_FC  Clean-DDR full-chip Gate14 exam still matches frozen oracle:
      HOLD_A C9=8382238122802120 OUT=653
      UNREL  OUT=689
      CONTRA OUT=237
      HOLD_B OUT=60
      GEN after one TRESET = 2 (BUMP, not REBIRTH)
```

TB: `P2-GATE14-C9-SOC-IO-SAFE-BIT-07/tb_a7ng_gate14_c9_soc_cofit.sv`
DUT DDR model initial = 0 → P_BOOT illegal cookie → REBIRTH gen=1.

If H_FC fails, first divergence in the log is the next defect. Do not retarget oracle.
Do not program the FPGA.

First attempt (cwd = bag) is **not** a law fail: C9 matched oracle, OUT=0 because
`a7lm06_wmem.hex` was missing. Replay from `tests/xsim`.
