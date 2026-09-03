# P2-GATE14-C9-SOC-COFIT-BIT-06 RESULTS

**PROGRAM=NO. COM12 not touched. JTAG not touched.**  
Does **not** declare GATE14_PASS or BOARD_PASS.

Parent FIX-05 = PASS_NARROW / XSim. This gate puts the same learned path into SoC full-chip.

## Return

```text
GATE=P2-GATE14-C9-SOC-COFIT-BIT-06
CLASS=BIT_READY_FOR_CODEX
SOC_C9_SOURCE=learned_prior_graph minheap Top-8
FAST_ID_PREEMPT_REMOVED=YES
A_GRAPH_ACCEPT=20
A_REWARD_COMMIT=20
B_GRAPH_ACCEPT=20
B_REWARD_COMMIT=20
C9_PACK_A=8382238122802120
C9_PACK_UNREL=8786858483828180
C9_PACK_CONTRA=2322832182208180
C9_PACK_B=8382438142804140
LM_OUT_A=653
LM_OUT_UNREL=689
LM_OUT_CONTRA=237
LM_OUT_B=60
CTX_EQUALS_C9=YES
LM_START_DONE_COUNTS=exam HOLD_A/UNREL/CONTRA/HOLD_B each LMST=1 LMDN=1
PERSIST_RELOAD=PASS (kill hides r1=80; reload HOLD_A C9 A pack OUT=653)
FREEZE=PASS (C_REW after freeze ack unchanged)
RESET_FORGET=PASS (TRESET GEN+1; HOLD_A pack 2322832182208180 r1=80 OUT=237)
HOST_FORBIDDEN_COUNTERS=0
REGRESSIONS=PASS G1 G2 G3 G4 minheap C9-graph
LUT=35658
FF=44140
BRAM36=104
DSP=19
WNS=1.276
WHS=0.013
CDC=1 CLOCK_GEN_FALSEPATH (c166_raw→clk_pll_i); candidate_logic=0 persist_crit=0
DRC=0 Error; NSTD-1/UCIO-1 Critical Warning (waived for write_bitstream)
BIT_PATH=results/A7-NATIVE-GRAPH/GROK-ORCH-00/P2-GATE14-C9-SOC-COFIT-BIT-06/arty_a7_ng_native_v1_grok_orch_C9-SOC-COFIT-BIT-06.bit
BIT_SHA256=B0F64E6C37F6BDB428FAB18CD6EEDD191C389AC3EE9FFB4D23B641B5D289A0A1
SOURCE_SHA=see SOURCE_SHA.txt (TinyGPT 75706E2C bind C5F57AD1 oracle 062932B3)
PROGRAM=NO
COM12=NOT_TOUCHED
BIT_READY_FOR_CODEX=YES
NEXT=Codex audit of unique bit B0F64E6C. Do not program. Do not claim GATE14_PASS/BOARD_PASS.
```

## Architecture (EVIDENCE)

SoC `a7ng_g1g5_cofit` instantiates `a7ng_learned_prior_graph` + `a7ng_gate14_c9_glue` only.  
`persist_gen_fast` and `teacher_off_glue` are **not** in the full-chip fileset.  
Exam bind IDs = learned graph Top-8 (`g14_persist_id`), not FAST-ID `0706050403010002`, not existence pack `3B392B291B190B09`.  
One store, one scorer_lane, one stream minheap, one persist_axi_bridge, one native_ctx_bind, one TinyGPT.

## Integration XSim (EVIDENCE)

`GATE14_C9_SOC_COFIT_XSIM_PASS fails=0 OUTA=653 OUTU=689 OUTC=237 OUTB=60`  
FIRST_DIVERGENCE=NONE.

CTX_BEAT pack == C9 for HOLD_A / UNREL / CONTRA / HOLD_B.

## Full-chip vs A0B338E0 (delta)

| | A0B338E0 (LM-START-WIRE-01) | this bit B0F64E6C |
|--|--|--|
| BRAM36 | 103 | 104 (+1) |
| DSP | 19 | 19 |
| WNS | 1.276 | 1.276 |
| WHS | 0.021 | 0.013 |
| Slice | 15454 / 15850 free=396 | 15633 / 15850 free=217 |
| LUT | (parent util) | 35658 |
| FF | (parent util) | 44140 |
| CDC candidate_logic | 0 | 0 |

BRAM36 ≤ 135. Setup/hold PASS. No new critical CDC (only documented clock-gen falsepath). Unique bit name contains `C9-SOC-COFIT-BIT-06`. SHA ≠ A0B338E0.
