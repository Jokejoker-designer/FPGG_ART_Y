# PREREG — U8-R3B-PRODUCTION-GLUE-00

```text
GATE              = U8-R3B-PRODUCTION-GLUE-00
MOVE              = bag a7ng_lm_ctx_fwd_v1.sv → rtl/native_graph/lm/
SHA256            = 63E32A9BE0A9AA5BCC0679F6D2A78218CA5B11900872636A1DC2716AC52ABF4C
ENCODER_EDIT      = NO
BIND              = not a7ng_native_ctx_bind
CLASS_ID_AS_TOKEN = NO
BIT               = NO
PROGRAM           = NO
QHEAD             = NO
SEMANTIC_LM       = MISMATCH
```

Byte-identical promote. U8-R3 run_xsim.tcl now xvlogs the rtl copy.
Re-run U8-R3 XSim as the production-glue check. Not U8R. Not SoC MIG.
