# ORACLE_COMPATIBILITY — U9R R7

```text
LEGACY_HOLD_A_OUT        = 653 (frozen; not retargeted)
TYPE_CLASS_PRED_OBS      = 861 (U8-UNIFIED-SOC-XSIM-00 xsim.log; source hash MATCH)
CLASS                    = LM_CHECKPOINT_CONTEXT_MISMATCH
QHEAD                    = NO
HOLD_A_ORACLE_RETARGET   = NO
STRUCTURAL_ENCODER       = PASS (R7: 12 tokens {eid,iid,rid,xid}; CLASS_ID not serialized)
```

R7 re-ran encoder only (not 110s LM full-forward). Weights/encoder/fwd/chain SHA256 match U9 freeze. Arithmetic of pred=861 is archived, not re-seated as HOLD_A.

Gap: Master still requires HOLD_A 653 on the final path. TYPE_CLASS context/checkpoint is a different law. Not AUTHORITY to retarget 861→653.
