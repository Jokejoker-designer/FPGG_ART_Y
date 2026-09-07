# RESULTS — U4B-GLOBAL-ID-C9-WIDTH-00

```text
PACK_XSIM        = U4B_ID20_PACK_PASS
CHAIN_XSIM       = U4B_C9_BIND_WIDTH_PASS
SCORER_TOPK_C9   = U4B_SCORER_HEAP_C9_PASS  id0=000c34ff
SENTINEL         = 799999 = 20'hC34FF
LIVE_C9          = c9_id20_o through glue → g1g5 → ab_core
LIVE_BIND        = ctx_pack20_o through bind → ab_core
DIAG_UART_C9     = c9_cframe_o / c9_topk_o 64-bit 8-bit pack UNCHANGED (oracle HOLD)
LM_CTX_64        = frozen TinyGPT still consumes diagnostic pack8
LOW8_ALIAS       = FORBIDDEN on live 20-bit path
SOC/BIT          = NO
```

Scorer and Global TopK already carry `node_id_t` (32). Truncation was C9/LM pack;
live observe is now 20-bit in parallel. UART C9 payload not retargeted.
