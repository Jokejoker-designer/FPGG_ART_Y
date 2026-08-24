# M8-LM-04 — gradient train embeddings + LM head

Freeze Q/K/V/FFN. Train token/position embeddings and LM head with SGD.
Need 128 hardware gradients within 2 LSB or 5% of `tiny_gpt_ref` backward
(to be added with the RTL). AFTER writes = 0.

Claim: `ON_FPGA_GRADIENT_TRAINED_LM_HEAD_AND_EMBEDDINGS`.
