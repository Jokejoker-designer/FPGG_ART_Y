# RESULTS — U4B-GLOBAL-ID-C9-WIDTH-00

```text
PACK_XSIM   = U4B_ID20_PACK_PASS
CHAIN_XSIM  = U4B_C9_BIND_WIDTH_PASS sentinel=C34FF
LIVE_C9     = c9_id20_o[19:0] = 20'hC34FF
DIAG_C9     = c9_topk_o[7:0]  = 8'hFF  (diagnostic only)
LIVE_BIND   = ctx_pack20_o[19:0] = 20'hC34FF
DIAG_BIND   = ctx_pack_o[7:0]    = 8'hFF
LOW8_ALIAS  = FORBIDDEN on live path (20-bit != {12'0, low8})
SCORER/TOPK = already node_id_t 32-bit (untouched)
ROUTER      = a7ng_sparse_dir_axi cand_id ID_W=20 (U4-R2)
SOC/BIT     = NO
```

Legacy 64-bit C9/LM pack remains diagnostic. Frozen TinyGPT ctx_pack 64-bit
input is unchanged (still consumes diagnostic pack). Live ID observe is
ctx_pack20_o / c9_id20_o.

Next fullchip fileset must add `rtl/native_graph/integrate/a7ng_id20_pack.sv`.
U2R running now used the pre-U4B glue snapshot (already in synth).
