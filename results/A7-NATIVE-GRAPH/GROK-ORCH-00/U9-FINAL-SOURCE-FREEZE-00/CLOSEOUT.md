# CLOSEOUT — U9-FINAL-SOURCE-FREEZE-00

```text
GATE                     = U9-FINAL-SOURCE-FREEZE-00
BASE                     = bdddbd68b048054dc0c52e87685829a590f25270
SOURCE_COMMIT            = bdddbd68b048054dc0c52e87685829a590f25270
FINAL_SOURCE_COMMIT      = bdddbd68b048054dc0c52e87685829a590f25270
RTL_EDIT                 = NO
SOC_TOP_EDIT             = NO
FILES_CHANGED            = results/A7-NATIVE-GRAPH/GROK-ORCH-00/U9-FINAL-SOURCE-FREEZE-00/*
                           docs/native_graph/CLOSE_NATIVE_V1_DAG.md (pointer only)
BIT_BUILD                = NO
PROGRAM                  = NO
QHEAD                    = NO
HOLD_A_ORACLE_RETARGET   = NO
GATE14_PASS              = NO
BOARD_PASS               = NO
M10                      = TYPECLASS HOST_MODEL PASS (NID FAIL immutable)
PRIMARY_UNKNOWN          = production source uniquely hashable as FINAL_SOURCE_COMMIT
                           with production paths clean vs HEAD
RESULT                   = PASS
EVIDENCE_CLASS           = RTL_FACT + GIT + XSIM
FIRST_DIVERGENCE         = NONE
FALSIFIED_ALTERNATIVES   = freeze-while-rtl-dirty;
                           relabel-SoC-WDMA-OPEN_AUDIT-as-PASS;
                           apply-U2-WNS-to-U8R-RTL
MARKER                   = U9_FINAL_SOURCE_FREEZE_XSIM_OK
CONFIRM_XSIM             = U8R_REMOVE_SYNTHETIC_PRODUCTION_PASS
TOP                      = arty_a7_ng_native_v1_ab_soc_top
PART                     = xc7a100tcsg324-1
PHYS                     = 4
WAVE                     = 16
K                        = 8
ROUTER_PROFILE_FINAL     = TYPE_CLASS_MASKED_CONJUNCTIVE
CAND_CAP_FINAL           = 64
DDR_QUERY_BOUND_FINAL    = 1024
VIVADO                   = 2026.1 SW Build 6511674
SOC_WDMA_ROOT_B          = SLICE_XSIM_PASS (dest unwired; SoC OPEN_AUDIT)
SEMANTIC_LM_CLAIM        = NO
CLASS                    = LM_CHECKPOINT_CONTEXT_MISMATCH
NEXT                     = U9R-FINAL-REGRESSION-00
```

## Allowed claim

Production `rtl/` `constraints/` `vivado/tcl` match HEAD `bdddbd68` (U8R).
Manifest + key SHA256 recorded. soc_top `SYNTHETIC_CAND_GEN=0`. Confirm
XSim reproduced U8R parent IDs 65/66/67 vs fixture idle 0. MIG XCI blob
unchanged. No bitstream.

## Not claimed / not closed

- silicon, Gate14, BOARD_PASS, OUT=653, "LM understands TYPE_CLASS"
- full-SoC WDMA ACK⇔commit (dest `dma_go_ready` still default 1)
- `native_ctx_bind` removed from `ab_core`
- U9R full regression suite
- U9S/U9I unique bit
- U2 POST_ROUTE numbers on this RTL
- U7A reachability un-failed

## NEXT

`U9R-FINAL-REGRESSION-00`. Do not auto-open U9S / U9I / U9P / U10.
Do not declare BOARD_PASS or GATE14_PASS.
Do not reseat `1F0F2ABB` / `9CA2B30D` / `F24150BD` / `3A7EF204`.
