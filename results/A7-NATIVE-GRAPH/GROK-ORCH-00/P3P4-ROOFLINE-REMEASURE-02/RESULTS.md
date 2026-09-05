# RESULTS — P3P4-ROOFLINE-REMEASURE-02

Measurement-only. No RTL. Source: CUE-OVERLAP-READY-00 `P3P4_REPAIR_DONE` (MIG_XSIM).

```text
T_QUERY     = 628
T_IDEAL_PIPE= 527
S_TAX       = 101
II_PRED     = max(C_D,C_T,C_L,C_G) = 96
II_WAVE_OBS = 153

C_D_MAX = 45
C_T_MAX = 33
C_L_MAX = 96   ← dominant
C_G_MAX = 65
```

Authority decision:

```text
C_L dominant → LOCAL-CORE-LATENCY-AUDIT-00
not C_T → do not start TERMGEN-II6-00
not C_G → do not start GLOBAL-VALID-CONTRACT-AUDIT-00
not C_D_EXPOSED-as-II → no DDR prefetch/outstanding research
PHYS stays 4
```

C_D_EXPOSED occupancy is 182 cycles but C_D_MAX=45 < C_L. Exposed II is Local NG02, not DDR.

NEXT = `LOCAL-CORE-LATENCY-AUDIT-00`.
