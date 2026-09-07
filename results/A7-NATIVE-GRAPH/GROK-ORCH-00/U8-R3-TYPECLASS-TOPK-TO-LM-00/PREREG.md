# PREREG — U8-R3-TYPECLASS-TOPK-TO-LM-00

Before XSim. Owner lock: `F_STAGED_FPGA_CONTEXT_ENCODER_V1`.
Encoder law frozen at U8-R2. This gate is unified chain XSim only.

```text
GATE     = U8-R3-TYPECLASS-TOPK-TO-LM-00
HEAD     = 4ca071e7927aa4ceb6b9868eb17630ffa985eaf0
POLICY   = F_STAGED_FPGA_CONTEXT_ENCODER_V1
SEMANTIC = LM_CHECKPOINT_CONTEXT_MISMATCH  (unchanged)
ENCODER  = rtl/native_graph/lm/a7ng_lm_ctx_encoder_v1.sv
ENCODER_SHA256 = bbd95f7f148e722002e1982292662c8cb54e26ce16ff7ead75400313182892aa
RANKING  = a7ng_u7_contextual_rank (topk_class_id_o[K] exists)
GLUE     = a7ng_lm_ctx_fwd_v1 (bag; encoder beats → ctx_we → start_fwd)
LM       = tiny_gpt803k_core SIM_FULL=1
RTL_EDIT_ENCODER = NO
QHEAD    = NO
BIT      = NO
PROGRAM  = NO
HOLD_A_ORACLE_RETARGET = NO
```

## Chain (required)

```text
U7 ranking CLASS_ID heap
  → a7ng_lm_ctx_encoder_v1
  → ctx_we beats of [eid,iid,rid,xid] tokens
  → exactly one accepted start_fwd
  → LM-06 SIM_FULL
  → exactly one done
```

Host:

```text
n_host_tok = n_host_w = n_host_win = n_host_addr = 0
ranking n_host_or = 0
```

Install-chiller poke (FPGA structured features, not host CLASS_ID):

```text
eid=1 iid=1 ev=1 iv=1  freeze=1 train_after=0
expected heap CLASS_ID = 65,66,67 + pads 0xFFF0+
expected stream = 1 1 0 0  1 1 0 1  1 1 1 0
ntok = 12
ctx_we beats = 2
```

## Encoding (unchanged V1)

Rank-order `[eid,iid,rid,xid]` per valid CLASS_ID 1..443.
Never serialize CLASS_ID or CLASS_ID[7:0].
Do not reuse `a7ng_native_ctx_bind` global_id low8 packing.

## Not this gate

Semantic LM understanding · OUT=653 · silicon · Gate14 · Q-head · U8R · U9
