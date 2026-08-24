# M8-LM-02 — tiny next-token LM (Basys 3, new LM profile)

**Status:** BOARD PASS 2026-08-16. Separate bitstream from LEGACY.  
**Config:** V=32, d_model=16, context=8, no attention.

## Must exist before RTL board

- `python/lm/tiny_lm_ref.py`
- INT8 weights / INT16 act / INT32 acc
- Tensor SHA serializer
- `SEQ-EASY` + `GRAMMAR-32` (`synth_grammar`)

## RTL (LM profile, not added to 06B/LM-01 top)

`token_embedding_bram`, `position_embedding_bram`, `context_buffer`,
`fixed_context_pool`, `lm_head_mac`, `argmax32`.

## Board claim (not open)

`TINY_AUTOREGRESSIVE_LANGUAGE_MODEL_FPGA_BOARD_VALIDATED` only after
1k logit vectors match the fixed-point ref and held-out next-token ≥80%.
