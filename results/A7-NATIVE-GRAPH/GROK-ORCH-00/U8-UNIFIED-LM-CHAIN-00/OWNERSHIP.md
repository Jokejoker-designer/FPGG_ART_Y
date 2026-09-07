# OWNERSHIP — U8

```text
retrieval_id     = CLASS_ID          (U6/U7 production)
learning_target  = V1 {subj,rel,obj} (U7)
c9_pack          = low8(topk_id)     (legacy NID graph / silicon)
lm_tok           = ctx_pack[8*i +: 8]
lm_pred          = tiny_gpt803k core_pred (10-bit)
```

Host must not supply: CLASS_ID, winner, NID, member, token, next-token,
final answer, weight write during teacher-off exam.

Existing counters on C9+LM wrapper: `n_host_tok_o`, `n_host_w_o`,
`n_host_win_o`, `n_host_addr_o`. Expected 0 on exam.

Selection owner for TYPE_CLASS→LM: **NOT DEFINED**.
U6 heap is FPGA-owned. What that heap **means** as LM tokens is not.
Do not let TB pick a winner or a member to fake the production connection.
