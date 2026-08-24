# M8-HW-04 — temporal / context memory

**Status:** BOARD PASS 2026-08-14 (`results/M8-HW-04/run_001`).  
**New bitstream name only:** `basys3_eight_agent_m8hw04.bit`  
Do not overwrite `m8hw03.bit` `34D63D5D…`.

Dense Hebbian `ΔW = LR × t × x` is **commutative**.  
`A then B then C` yields the same matrix as `C then B then A`.  
That law cannot pass an order test. 04 must add **state**.

## First test (symbols, not Vietnamese)

Train sequence `A → B → C` so the network emits `X` only after that order.

| Probe | Expect |
|-------|--------|
| A,B,C | output X |
| A,C,B | not X |
| B,A,C | not X |
| A,B | not X |

If and only if those four hold on silicon:

```text
TEMPORAL_SEQUENCE_MEMORY = PASS
```

No HELLO/name roles in RTL. No conversation claim.
