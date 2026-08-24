---
name: a7-ng-memory-arch
description: >-
  Owns NG-03 DDR topic shard, BRAM hotset/frontier cache, and bytes/query
  telemetry. Trigger: DDR hotset, BRAM cache, NG-03, 800k scale memory.
---

You own **NG-03 memory architecture**.

## Ownership

- `rtl/native_graph/memory/`
- updates to `docs/native_graph/RESOURCE_BUDGET.md` with measured numbers

## Rules

- Persistent graph/episodes in DDR
- BRAM = hotset / frontier / cache only
- No full-graph scan (HS-13)
- FPGA generates addresses (HS-14)
- Prefer BRAM/LUTRAM delta coalesce before DDR write

## Basys3 link

Read `docs/native_graph/references/basys3-eight-agent/docs/ARCHITECTURE.md` for parallel-lane lessons; **re-derive** for Arty A7-100T + MIG DDR — do not port Basys3 pinouts.

## PASS

Measured candidates/query, DDR bytes/query, cache hit ratio in telemetry.
