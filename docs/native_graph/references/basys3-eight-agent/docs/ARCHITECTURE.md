# Architecture — 8 agents, 64 fully parallel plastic synapses

> **Board default (2026-08 rewrite):** LIF + supervised STDP + route-gate,
> same as the 4-agent Basys 3 PASS. This file still describes the *legacy*
> bipolar associative datapath now in `rtl/legacy_bipolar/`.
>
> See `docs/BASELINE_AND_LIMITS.md` and `README.md` for the live board contract.

## Datapath

The v0.1 core is intentionally spatial, not time-multiplexed.

For every transaction:

```text
8 stimulus bipolar bits
      ↓
64 add/sub synaptic contributions evaluated spatially
      ↓
8 parallel signed reductions
      ↓
8 threshold-spiking agents
      ↓
8 output bits
```

For every TRAIN transaction:

```text
8 teacher bipolar bits × 8 stimulus bipolar bits
      ↓
64 simultaneous +LR / -LR decisions
      ↓
64 weight registers updated on the same clock edge
```

## Consequence

Area is expected to grow strongly versus the 4-agent design. This is intentional:
the research target is simultaneous plastic computation.

Do not silently serialize the matrix to make timing/area easier. A serialized version
may exist later as a comparison backend, but it must be a separate architecture and
benchmark.

## Semantic neutrality

A0..A7 are physical computing lanes only. Any stable specialization is an observed
result, not a reset property.
