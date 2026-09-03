# AUDIT — Gate L LM-06 active chain (READ-ONLY)

```text
RTL_EDIT = NO
PROGRAM  = NO
```

## Hierarchy (C9 SoC XSim = silicon law, SIM_FULL=1)

```text
glue.lm_start_o
  → bind.start_i  (grant_lm=1, do_start=1)
       S_IDLE: capture pack_comb from global_id_i (= graph TopK = C9 bytes)
       S_CTX:  ctx_we=1, ctx_pack=captured_pack, ctx_n=8
       S_START/S_WAIT: start_fwd until core_busy
       S_WAIT: on core_done, pred_r <= core_pred
  → tiny_gpt803k_core
       ctx_we: tok[0:7] <= ctx_pack bytes, ntok<=8
       start_fwd: ST_IDLE → ST_EMB_* → ATT/MV/LN/SMX/ARG
       pred <= arg_best  (ST_ARG)
       done pulse, busy=(st!=IDLE)
  → glue S_LMW: c10_out <= lm_pred_i (= bind.pred_o)
```

Silicon `ab_core` uses the same bind+TinyGPT with `g14_lm_start`. XSim wrapper
ties `grant_lm=1` and `SIM_FULL=1` (sim BRAM, `stall=0`, no DDR WDMA miss).

## Causal table (expected)

| signal | producer | consumer | phase | class |
|--------|----------|----------|-------|-------|
| c9_topk | glue pack of graph TopK | TB / UART C9 | snap | RTL_FACT |
| captured_pack | bind S_IDLE | ctx_pack | L0/L1 | RTL_FACT |
| ctx_we / ctx_pack | bind S_CTX | tiny_gpt tok[] | L1 | RTL_FACT |
| lm_start | glue S_QWAIT want_lm | bind.start | L2 | RTL_FACT |
| start_fwd | bind S_START/S_WAIT | tiny_gpt start_fwd | L2 | RTL_FACT |
| busy / st | tiny_gpt | bind.core_busy | L3 | RTL_FACT |
| tile rdata (SIM_FULL BRAM) | weight_tile803k | TinyGPT MAC | L4 | XSIM (not DDR) |
| core_done / pred | tiny_gpt ST_ARG/DONE | bind pred_r | L5 | RTL_FACT |
| c10_out | glue <= bind.pred | UART C10 | L6 | RTL_FACT |
| host_next/wren | tied 0 | n_host_* | L7 | RTL_FACT |

No constant OUT mux: glue zeros c10_out at FIRE, then only writes `lm_pred_i`
on `lm_done_i`. `exam_lm_used_o` is sticky — **not** used as proof.

## Perturbation

Same frozen A state, freeze=1: HOLD_A vs UNREL. Different C9 → different
`ctx_pack` → different `pred`/`OUT` (653 vs 689). Oracle not retargeted.
