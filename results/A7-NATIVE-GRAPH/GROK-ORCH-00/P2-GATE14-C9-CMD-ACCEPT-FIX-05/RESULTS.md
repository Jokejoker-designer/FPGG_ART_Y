# P2-GATE14-C9-CMD-ACCEPT-FIX-05 RESULTS

**PROGRAM=NO. COM12 not touched. No unique SoC bitstream.**  
Does **not** declare GATE14_PASS / BOARD_PASS / BIT_READY_FOR_CODEX.

Codex audit stop `PERSIST_BUSY_MISS cmd=8` was a TB acceptance error. TRAIN_RESET without wrap pulses `persist_done` and increments GEN in `P_IDLE`; it does not hold `persist_busy`.

## Return

```text
GATE=P2-GATE14-C9-CMD-ACCEPT-FIX-05
CLASS=PASS_XSIM_C9_LM_HANDSHAKE
FIRST_DIVERGENCE=NONE
CMD_DUPLICATE_COUNT=0
A_CMD_FIRE_ACCEPT=20
A_GRAPH_ACCEPT_COUNT=20
A_REWARD_COMMIT_COUNT=20
A_ACK_COUNT=20
A_COMMIT_SEQ=20
B_CMD_FIRE_ACCEPT=20
B_GRAPH_ACCEPT_COUNT=20
B_REWARD_COMMIT_COUNT=20
B_ACK_COUNT=40
B_COMMIT_SEQ=40
GEN_BEFORE_RESET=1
GEN_AFTER_RESET=2
C9_PACK_A=8382238122802120
C9_PACK_UNREL=8786858483828180
C9_PACK_CONTRA=2322832182208180
C9_PACK_B=8382438142804140
LM_OUT_A=653
LM_OUT_UNREL=689
LM_OUT_CONTRA=237
LM_OUT_B=60
ORACLE_SHA=062932B3853144526B1C9A42C2076966C45EF108C707546C68C9BC89754C912B
REGRESSIONS=PASS G1 G2 G3 G4 minheap C9-03-graph
LUT=2906
FF=1493
BRAM36=1
DSP=0
WNS=+53.745
WHS=+0.128
CDC=empty
BIT_PATH=none
BIT_SHA256=none
PROGRAM=NO
COM12=NOT_TOUCHED
NEXT=Wire learned_prior_graph + c9_glue into SoC cofit; bind exam LM to learned C9 (drop persist FAST-ID preempt); unique bit then BIT_READY_FOR_CODEX. Do not program A0B338E0.
```

## TB contract (this revision)

`do_cmd_fix` samples `cmd_valid && cmd_ready` on the posedge in the task. Valid drops on the following negedge. Monitor `cmd_accept_n` is NBA evidence only; stimulus does not wait on it.

Per command:

| Cmd | Completion |
|-----|------------|
| TOK/TRAIN/FREEZE | one local handshake, `accepted_delta==1` |
| FIRE | `query_valid&&query_ready`, qid match, one snap, glue idle; graph/snap delta==1 |
| REW | `c7_ack_valid`, ack/seq +1, then persist idle |
| FLUSH/RELOAD | `persist_done` then busy=0 |
| TRESET | GEN+1; **not** busy. Forget HOLD_A pack `2322832182208180` r1=80 |
| KILL | `persist_done` (not used in this curriculum) |

`CMD_DUPLICATE` is consecutive `valid&&ready` cycles. Count=0. Odd tokens `11,13,…,23` each have one `CMD_ACCEPT cmd=1` and one `GRAPH_ACCEPT`.

## LM

CTX_BEAT idx=0 n=8 pack equals C9 for HOLD_A/UNREL/CONTRA/HOLD_B. Frozen OUT 653/689/237/60. Forget HOLD_A (not an oracle) C9=`2322832182208180` OUT=237 (same pack as CONTRA). Oracle file not edited.

## Unique bit not created

SoC `a7ng_g1g5_cofit` still uses persist FAST-ID + teacher_off_glue. A full-chip of that SoC is not this XSim C9 path. OOC of `a7ng_learned_prior_graph` only (80 ns): LUT 2906 FF 1493 RAMB36=1 DSP 0 WNS +53.745.

## Product RTL

Handshake was TB-only. Glue not rewritten. Store `have_free` uses `!vis_w` so 20 B writes fit after TRESET in 32 slots (GEN-stamp reuse, not a handshake cover-up).
