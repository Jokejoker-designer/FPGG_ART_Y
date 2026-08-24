# M8-LM-03 — causal Transformer forward (Basys 3)

**Status:** BOARD PASS. Claim `TINY_CAUSAL_TRANSFORMER_FORWARD_PATH_FPGA_BOARD_VALIDATED`. Separate bitstream `basys3_lm03.bit`. No LEGACY rewrite.

V=32, d=16, C=8, heads=1, layers=1, d_ff=32.

Required test: future-token mutation. Prefix hidden/logits for
`[A B C X Y]` vs `[A B C P Q]` must match through position C.

Claim after board: `TINY_CAUSAL_TRANSFORMER_FORWARD_PATH_FPGA_BOARD_VALIDATED`.
Do not start LM-04 until this board gate exists.
