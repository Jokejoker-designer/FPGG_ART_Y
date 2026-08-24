# Baseline and limits — 8-agent package

## Board default (this rewrite)

Same contracts as the 4-agent Basys 3 run that produced:

- `weight[1][0] = 1088` after 512 updates
- frozen `in/out` cyclic 140/140

Scaled to N=8:

- 8 LIF, 64 STDP synapses, full-parallel LEARN
- route-gate 256 / 560
- output latch
- supervisor EVAL 32 → TRAIN 1024 → EVAL 32 → HOLD
- UART `A5 5A` / `A5 5C`

## Explicitly not claimed (still)

- 64-synapse **arbitrary** associative learning on board
- Random session A → B remapping on board
- Reset → forget → retrain a new mapping on board
- Natural-language / simple conversation
- Transformer attention / backprop / LLM

M8-HW-01 only claims **cyclic** online-learning convergence
(`8_AGENT_CYCLIC_LEARNING_CONVERGENCE_DEMONSTRATED`).

## Legacy bipolar core

`rtl/legacy_bipolar/` + `python/golden_model.py` still implement the original
±1 outer-product associative rule (weights start at 0). That path is for
anti-hardcode association research. It is **not** wired to the Basys 3 top.
