# CLOSEOUT — U7A-ROOT-B-FINAL-00

```text
GATE                     = U7A-ROOT-B-FINAL-00
RESULT                   = PASS
SCOPE                    = close-path learned_prior_store
EVIDENCE_CLASS           = RTL_FACT + XSIM
RTL_EDIT                 = NO
U7A                      = FAIL immutable (not un-failed)
U7A_R1                   = PASS (store-full NAK law)
U7A_R2                   = PASS (baseline Root-B matrix)
U7_E8                    = PERSIST_RELOAD_MATCH=1 (this session)
SOC_WDMA_ROOT_B          = OPEN_AUDIT
PERSIST_GEN_FAST         = DISCONNECTED
C7_ADDR                  = OBSERVE_ONLY
BIT                      = NO
PROGRAM                  = NO
GATE14_PASS              = NO
```

## Allowed claim

Close-path store completion obeys wrote ⇔ persist_done; store-full is NAK;
FLUSH/RELOAD ranking match holds after latest QSE/heap RTL. That is the
Root-B object for Native V1 close **learn/persist**.

## Not closed (recorded, not hidden)

- SoC WDMA has no single host-visible txn identity; ACK≠commit by
  construction (`G14-ROOT-B-TXN-AUDIT-00` CLASS=`ROOT_B_PARTIALLY_CONFIRMED`).
- `persist_gen_fast` remains DISCONNECTED.
- This PASS is not a PROGRAM license and not Gate14.

## NEXT

`U8-R3B-PRODUCTION-GLUE-00` — promote `a7ng_lm_ctx_fwd_v1` into
`rtl/native_graph/lm/`. Not U8R. Not U9. Dirty MIG tree: do not start
full-chip SoC XSim until MIG is frozen.
