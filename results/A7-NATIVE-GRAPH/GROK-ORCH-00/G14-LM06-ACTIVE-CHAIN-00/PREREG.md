# PREREG — G14-LM06-ACTIVE-CHAIN-00 (Gate L)

```text
PROGRAM          = NO
GATE14_PASS      = NO
RTL_EDIT         = NO
HS-25            = Gate L (C9 exact → LM-06 actual compute → OUT)
UNKNOWN          = Is FPGA OUT the result of this request's TinyGPT compute on bound C9, not a sticky flag or bypass?
FALSIFIER        = C9 exact but no start; start without FSM advance; OUT != core_pred; host token/weight write
EXPECTED         = LM_ACTIVE_CHAIN_PROVEN on XSim SIM_FULL=1
REGRESSION       = frozen HOLD_A C9/OUT 8382238122802120 / 653; UNREL 8786858483828180 / 689 as perturbation
```
