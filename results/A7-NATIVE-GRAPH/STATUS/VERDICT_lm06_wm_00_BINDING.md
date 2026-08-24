# BINDING VERDICT — `lm06_wm_00`

**Set by:** human, 2026-08-22, before the gate closed.
**Status:** binding on the implementer CLOSEOUT, on all verifiers, and on any later citation.

```text
result_class     PASS_NARROW
evidence_class   LM06_WM_XSIM
ladder           BLOCKED (unchanged)
BOARD            none
RESOURCE_BUDGET  not updated
```

## Inference struck from the record

`RESULTS` claimed, in effect: *"max 2 tile/cycle => ping-pong is sufficient for correctness."*

**Struck.** A port-demand count is **simultaneous port demand** and nothing more. It does not
establish:

- working-set = 2 tiles
- that DDR latency is hidden

The only permitted statement is the bare, workload-scoped observation:

> In this workload, at most 2 tiles are demanded in the same cycle.

No correctness conclusion may be drawn from it. Anyone later reading a "ping-pong is sufficient"
claim sourced to this gate is reading a struck inference.

## Scope corrections

| Item | Correct reading |
|------|-----------------|
| **Arm A** | Every tile still resident, plus accounting. This is **retile + measurement**, *not* a demonstrated BRAM bound. |
| **Arm B** | Functional zero-latency, `n=1` snapshot only. **Not timed RTL** — carries no timing, throughput, or latency-hiding claim. |
| **Traffic / reuse-distance** | Belongs to the **ladder** (`lm06_wm_01..04`). Not a WM-00 finding. |

## What the gate legitimately establishes

Bit-exactness of the restructured working set against the **recorded** frozen LM-06 CONTROL, with
mutant negative-controls proving the equivalence bench can actually detect divergence. That is the
result. It is a correctness result, not a resource result.

## Consequences

- `lm06_wm_01..04` remain **BLOCKED**. `forbid_ladder_without_bit_exact` still governs: the ladder
  opens on bit-exactness, and nothing in this gate sizes a tile target.
- `docs/native_graph/RESOURCE_BUDGET.md` is **not** updated from this gate.
- No BOARD claim. No COM12. Evidence class stays `LM06_WM_XSIM`.
- Any auditor that finds the struck inference still present must **FAIL** the closeout.
