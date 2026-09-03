# RESULTS — G14-TEACHER-OFF-NATIVE-CAUSALITY-00 (Gate T)

```text
TEACHER_OFF_XSIM             = PASS
FIRST_DIVERGENCE             = NONE
ROOT_CAUSE                   = n-a
C9_SCORED                    = PASS  HOLD_A = 8382238122802120
OUT_SCORED                   = NO    (observed 653; Gate L)
READY_TO_PROGRAM             = NO
PROGRAM                      = NO
GATE14_PASS                  = NO
BOARD_PASS                   = not_claimed
TEACHER_OFF_BOARD            = not_claimed
RESET_RETRAIN_XSIM           = PASS
RESET_RETRAIN_BOARD          = not_claimed
```

No FPGA program. No new bit.

---

## Audit (`RTL_FACT`)

C9 SoC glue host ports are tied to 0 in `a7ng_g1g5_cofit`. C9 is graph TopK,
not host winner/cue. `query_anchor` teacher_override is **not** in this fileset.

UART exam token `0xA2` selects query id HOLD_A. That is not a teacher label
of the answer.

---

## Graph XSim

```text
learn=0 freeze=1 HOLD_A C9=8382238122802120
TEACHER_OFF_GRAPH_XSIM_PASS
```

---

## Full-chip XSim (Gate T)

```text
GATE_T_PRE_EXAM mode=8 learn=0 freeze=1
n_host cue/win/addr/tok/w/mode = 0/0/0/0/0/0
HOLD_A C9=8382238122802120
OUT_OBSERVED=653   (not scored)
TEACHER_OFF_SOC_XSIM_PASS
```

Answer: **yes** — with host semantic assistance cut, the FPGA emits oracle
HOLD_A C9 from learned state + native candidate/TopK.

HS-25 Gate L (LM-06 active chain → OUT) remains **OPEN**.
