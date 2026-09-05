# RESULTS — U8 Phase A

```text
RESULT         = OWNER_DECISION_REQUIRED
CLASS          = ARCHITECTURAL_DECISION_REQUIRED
STATUS         = IDENTITY_DOMAIN_MISMATCH
RTL_EDIT       = NO
XSIM           = NOT RUN (not authorized)
BIT            = NO
PROGRAM        = NO
QHEAD          = NO
```

Measured, not guessed:

1. U6/U7 production Top-K identity = CLASS_ID (16-bit, can be >255).
2. LM-06 `ctx_pack` identity = 8-bit embedding tokens.
3. C9 HOLD_A pack `8382238122802120` / OUT 653 is NID-era silicon.
4. No RTL function maps CLASS_ID → `lm_tok` without low8 alias.
5. Legacy C9+LM wrapper exists; TYPE_CLASS tops do not instantiate bind/LM.

No first divergence in RTL because no RTL was patched.
