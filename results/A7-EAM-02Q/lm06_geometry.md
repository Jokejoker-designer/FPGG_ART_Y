# LM-06 → Q0/Q1 geometry (no 02A)

**Decision: `EAM02A_NOGO`.** Do not glue LM-06 802,816 + EAM. Do not touch the router. Do not pull DDR in for capacity.

## What was measured

- Weights: official host oracle `TinyGPT803k(seed=2)`, law `lm06-signsgd-v1`. C3 DDR W was never dumped — not invented.
- Tokenizer (frozen): **UTF-8 bytes as token IDs** in `V=1024`. There is no Vietnamese wordpiece on this model.
- Hidden: last-token `h ∈ Z^{128}` INT16 after 4 blocks.
- Encoders: frozen `eam02q-q0-even-v1` and `eam02q-q1-rh-v1` seed `0x0EA10201`.
- HOLD scored last; **not** used to pick T / seed / law.

## Q1 Hamming (the FPGA encoder)

| Bag | n | mean | p50 | min | TP@T=8 |
|-----|---|------|-----|-----|--------|
| PARA (paraphrase) | 8 | **26.25** | 30 | 18 | **0** |
| UNREL | 8 | **23.75** | 24 | 21 | FP **0** |
| HOLD (unread for decision) | 3 | 23.0 | 25 | 18 | 0 |

`mean(UNREL) − mean(PARA) = −2.5` — paraphrases are **not** closer.

The registered pair “FPGA nào đang dùng?” / “Board hiện tại dùng chip gì?” is `d_H=32`.

Q0 is the same story (PARA 25.1, UNREL 22.0, TP@8=0).

## Diagnostic: native last-token corpus

Same-k vs different-k under Q1: mean 24.8 vs 25.0, TP@8=0 both. Even the task LM-06 was built for does **not** become a Hamming ball of radius 8 after Q0/Q1.

## Go / no-go

Open EAM-02A only if PARA ≪ UNREL and `T=8` separates. **Failed.**

Root cause is **query representation** (task + tokenizer + unsigned projection), not 01R routing and not BRAM capacity. Next research is Q2 (learned binary map) or a hidden that actually carries paraphrase, **not** DDR.
