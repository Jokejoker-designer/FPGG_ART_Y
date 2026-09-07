# CLOSEOUT — U9R-FINAL-REGRESSION-00

```text
GATE                     = U9R-FINAL-REGRESSION-00
BASE                     = bdddbd68b048054dc0c52e87685829a590f25270
SOURCE_COMMIT            = bdddbd68b048054dc0c52e87685829a590f25270
FINAL_SOURCE_COMMIT      = bdddbd68b048054dc0c52e87685829a590f25270
HEAD                     = 40e246db922ce3d6fe35815988168c5bce9aa193
RTL_EDIT                 = NO
SOC_TOP_EDIT             = NO
FILES_CHANGED            = results/A7-NATIVE-GRAPH/GROK-ORCH-00/U9R-FINAL-REGRESSION-00/*
BIT_BUILD                = NO
PROGRAM                  = NO
QHEAD                    = NO
HOLD_A_ORACLE_RETARGET   = NO
GATE14_PASS              = NO
BOARD_PASS               = NO
REGRESSION_RESULT        = FAIL
FULL_SOC_RESULT          = INTEGRATION_GAP
M10_SCOPE                = CLASS_PREDICATE_CAP_ONLY
ROOT_B_SCOPE             = PRODUCTION_DEST_UNWIRED
LM_ORACLE_COMPATIBILITY  = ORACLE_COMPATIBILITY_GAP
READY_FOR_FINAL_SYNTH    = NO
RESULT                   = FAIL
EVIDENCE_CLASS           = XSIM + RTL_FACT + HOST_MODEL
FIRST_DIVERGENCE         = QUERY_NO_SNAPSHOT
VIOLATED_INVARIANT       = SYNTHETIC_CAND_GEN=0 query must produce snapshot/pending from parent Top-K, not from disabled cand graph
AFFECTED_STAGE           = g1g5 qv_to_graph / glue S_QWAIT
SMALLEST_NEXT_EXPERIMENT = C03: source pending/snapshot from parent completion when SYNTH=0 (do not patch this bag)
SEMANTIC_LM_CLAIM        = NO
CLASS                    = LM_CHECKPOINT_CONTEXT_MISMATCH
MARKER                   = (none; FAIL)
TOP                      = arty_a7_ng_native_v1_ab_soc_top (not instantiated; MIG)
PART                     = xc7a100tcsg324-1
VIVADO                   = 2026.1 SW Build 6511674
NEXT                     = C03_QUERY_PENDING_SNAPSHOT_SOURCE
```

## Allowed claim

Frozen `bdddbd68` is uniquely hashed (R0 MATCH). R1 route-valid and U8R C9 mux still PASS on that source.
R2 on `SYNTHETIC_CAND_GEN=0` issues C_FIRE, glue enters S_QWAIT, `qv_to_graph=0`, snapshot never rises, pending stays 0 (`xsim.log` / `xsim_r2.log` cyc=2085).
R3: UART decoder maps FIRE; production `soc_top` still has MIG, no QSE, no TYPE_CLASS chain, `native_ctx_bind` still packs LM — `FULL_SOC_RESULT=INTEGRATION_GAP`. soc_top was not instantiated (would pull MIG).
R5: freeze blocks updates; same-key duplicate accumulates pri=2; after `train_reset`, same-key +1 restamps old prior to pri=4 (not from-zero +1).
R6: two facts same `(eid,iid,rid,xid)` different object/source collapse under `type_hit`; `member_ptr` unused in LM stream.
R7: TYPE_CLASS encoder 12-token stream PASS; HOLD_A 653 not met; pred_obs 861 archived; no retarget.
R8: harness catches bad CRC, illegal type, host_cue inject (`n_cue` 0→4). Zero constants were not used as proof.

## Not claimed / not closed

- silicon, Gate14, BOARD_PASS, OUT=653, "LM understands TYPE_CLASS"
- full-SoC WDMA ACK⇔commit through `tiny_gpt803k_core` / soc_top dest `dma_go_ready` (unwired; default 1)
- this bag's R4 dest-like TB (`cmd=2 s_go=0 m_done=0`) is not a slice PASS
- U9 freeze history not rewritten
- U9S / U9I / U9P / U10 not opened

## NEXT

Do **not** auto-open U9S / U9I / U9P / U10.
Do **not** declare BOARD_PASS or GATE14_PASS.
Do **not** patch frozen RTL in this bag to flip FAIL to PASS.
Smallest corrective revision: **C03** — pending/snapshot must come from the live parent query path when `SYNTHETIC_CAND_GEN=0`. C02 UART→QSE→TYPE_CLASS in soc_top and C04 dest `dma_go_ready` wiring remain residuals for later named lakes.
Do not reseat `1F0F2ABB` / `9CA2B30D` / `F24150BD` / `3A7EF204`.
Semantic LM stays `LM_CHECKPOINT_CONTEXT_MISMATCH`.
