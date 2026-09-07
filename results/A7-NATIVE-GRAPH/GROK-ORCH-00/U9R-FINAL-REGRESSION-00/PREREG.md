# PREREG — U9R-FINAL-REGRESSION-00

```text
GATE              = U9R-FINAL-REGRESSION-00
AUTHORITY         = UNIFIED_NATIVE_AI_FINAL_BLUEPRINT_V3_1.md
                    docs/native_graph/V31_CLOSURE_PLAN_20260907/PLAN.md R0–R9
                    docs/native_graph/CLOSE_NATIVE_V1_DAG.md P10
                    docs/native_graph/V31_LEDGER.md
STATUS            = OPEN
PRIMARY_UNKNOWN   = Does frozen PRODUCTION_RTL=bdddbd68 satisfy
                    R0–R9 regression (query/reward liveness, full
                    soc_top path, WDMA dest ready, M10 member
                    evidence, LM oracle compatibility) without
                    editing frozen RTL in this bag?
RTL_EDIT          = NO
SOC_TOP_EDIT      = NO
SYNTH_IMPL        = NO
BIT               = NO
PROGRAM           = NO
REPROGRAM_AGAIN   = NO
QHEAD             = NO
HOLD_A_ORACLE_RETARGET = NO
U9S               = NO
U9I               = NO
U9P               = NO
U10               = NO
GATE14_PASS       = NO
BOARD_PASS        = NO
SCOPE             = XSim/regression only on frozen source
```

Pass language (all required):

- R0 provenance: bdddbd68 + test/config hashes; production porcelain empty
- R1 contracts: query/route/heap versioned golden; FAIL marker wins PASS
- R2 SYNTHETIC_CAND_GEN=0 query then real reward: snapshot, pending, commit
- R3 actual soc_top SIM_FULL=0 + fast AXI; missing wire = INTEGRATION_GAP
- R4 dest ready held low, two requests, reset/owner; accepted = retired+outstanding+aborted
- R5 freeze/duplicate/full/reset-retrain/reload; from-zero after train_reset
- R6 class vs record; two facts same class different object not collapsed
- R7 legacy vs TYPE_CLASS contexts; 861 ≠ 653 not retargeted
- R8 negative UART/AXI; counters catch injected faults
- R9 matrix + READY_FOR_FINAL_SYNTH; narrow PASS must not open U9S

Forbidden: silicon / Gate14 / BOARD_PASS / OUT=653 / "LM understands TYPE_CLASS" /
reseat frozen bits / git-add MIG or a7lm06_wmem.hex / force-push / patch frozen
RTL in this bag to flip FAIL to PASS.
