# CONTROL-SET-MAILBOX-00 — preregister

**PROGRAM=NO.** Do not overwrite `B0F42C11` / `DD4842DC` / `439CC42D`.

## One unknown

Wavefront `id/cue/prior_beats_mem` are tagged `ram_style=distributed` but live in an
**async-reset** `always_ff`, so they pack as **FF** (~52×128 plus `pf_beats`). That matches
`u_soa` 14249 FF. BRAM36 is 103/135 (32 tiles free).

If those arrays are written **one beat per R** in a **sync-only** process (`ram_style=block`),
with **no** one-cycle bulk copy and **no** async reset on the arrays, does post-route
**Slice used drop by ≥1000** (used ≤14850) with WNS≥0, BRAM36 ≤135, and A-FAST `pred=664`?

## Keep

- 16 lanes, `beats()`, min-heap `G_(t+1)`, r0/r1 **FF** banks (XSim rec0 lag)
- poison_i=0, UART existence markers
- Do **not** convert existing FIFO **BRAM** to LUTRAM

## Fail

Slice save <1000, BRAM overflow, or A-FAST pred≠664 → revert array writes.
