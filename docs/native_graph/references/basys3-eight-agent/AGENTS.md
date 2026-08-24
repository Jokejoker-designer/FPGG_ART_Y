# Agent instructions — 8-agent Basys 3 package

## Mission
Scale the **board-proven 4-agent** SNN to 8 agents without inventing conversation,
Transformer, or LLM claims.

## Skills
- `.agents/skills/anti-hardcode-learning/SKILL.md` — no semantic ROM / role at reset
- `.agents/skills/full-parallel-rtl/SKILL.md` — 8×8 update stays spatially unrolled
- Four-agent operational standard (latch, route-gate, eval supervisor, UART):
  `../basys3-four-agent-snn-ready/.agents/skills/`

## Claim discipline
- M8-HW-01 closed: cyclic convergence only. Never upgrade that to
  conversation or “64-synapse associative architecture board-proven”.
- Closed through M8-HW-06B (`SIMPLE_LEARNED_MULTI_TURN_CONVERSATION_BOARD_VALIDATED`).
  Do not upgrade that to LLM / open-domain chat.

## Invariants
- Board default = LIF + supervised STDP + `ATTENTION_ROUTE_GATE`.
- Weights start identical: diagonal 0, others 64. No prewired routes.
- Teacher only in TRAIN. EVAL/HOLD have `learn=0` and freeze.
- Latch `output_spikes` on LEARN so UART/LED are observable.
- `WEIGHT_LIMIT=2047` (`07FF`). New experiment = **BTNU**, not SW11 toggle.
- Keep `rtl/legacy_bipolar/` as a separate research backend. Do not mix it
  into the board top without a parameter and a second reference model.
- `rtl/core/` stays board-independent.
- Basys 3 = `xc7a35tcpg236-1`. No false timing exceptions.

## Change order
`reference → RTL → pytest → sim → synth/impl → board UART → docs`
