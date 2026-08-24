# M8-LM-05 — full tiny Transformer backprop on Basys 3

Every principal tensor trainable: tok, pos, Wq, Wk, Wv, Wo, FF1, FF2, head.
SGD, no Adam. Tiled BRAM / one MAC / one divider — not unrolled gradient lanes.
32 randomized training runs vs the fixed-point ref in `tiny_gpt_ref.backward_full`.

Integer law (host and RTL):

- Head / softmax: same as LM-04 (`g = dZ * y // s`, apply `w -= g >> lr`).
- Other linear grads: `g = q_grad((dy * x) >> 4)`.
- LN has no scale/bias: STE identity (`dx = dy`).
- Attention last-query: `dV = e*dA//z`, `de = sat16(V)·dA//z`,
  `dQ/dK = (dscore * sat16(K or Q)) >> 8`.
- Block / last-embed apply: sign-SGD, deadzone 2 (`±1` if `|g|>2`).
- AFTER (SW0 or cmd 12): weight writes = 0.
- Checkpoint: 3200-byte snapshot of all weight banks.

Claim (board only): `FULL_TINY_TRANSFORMER_BACKPROP_FPGA_BOARD_VALIDATED`.

Separate bitstream `basys3_lm05.bit`. Do not overwrite LM-04 or LEGACY bits.
This is the last Basys 3 research gate. Arty is M8-LM-06.
