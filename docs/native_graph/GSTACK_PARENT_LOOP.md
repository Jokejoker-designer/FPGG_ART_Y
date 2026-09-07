# GStack parent loop — Native V1

gstack source: `E:\agents\gstack` (garrytan/gstack, MIT). Not qstack.
Grok host: `.grok/workflows/blueprint-gate-loop.rhai` (also `~/.grok/workflows/`).

Final design: `docs/native_graph/V31_CLOSURE_PLAN_20260907/PLAN.md` + `PROMPT_GROK_U9R.md`.
Owner instruction: DAG already planned. Parent must not rewind accepted gates (C00).

## Roles

| Role | gstack analog | Grok |
|---|---|---|
| Parent | /autoplan coordinator | this workflow |
| Identify scout | plan intake | agent read-only |
| Implementer | eng after /plan-eng-review | agent execute |
| Nghiem-thu auditor | /qa-only (never fixes) | agent read-only |
| Patch implementer | /review auto-fix then re-QA | agent execute |
| Hard stop | /careful + /guard | BIT=NO PROGRAM=NO |

## Loop

```text
identify next blueprint gate from CLOSE_NATIVE_V1_DAG
    → implementer (one lake, one unknown)
    → independent auditor (FAIL / overclaim / fraud / logic)
         PASS → next auto lake until max_gates
         FAIL/OVERCLAIM/logic_bug → one causal patch → auditor again
         BLOCKED (BIT/PROGRAM/owner) → stop, do not invent
```

Default `start_gate=U9R-FINAL-REGRESSION-00`, `max_gates=1`.
If scout returns U8-R3 / U8R / U9 freeze (already ACCEPTED), parent **rejects** and keeps requested P10.
U9R must not patch frozen RTL in the same bag. Never auto U9S/U9I/U9P/U10.

## Hard stops (never auto)

BIT, PROGRAM, REPROGRAM_AGAIN, Q-head, HOLD_A retarget,
force-push, identity invention (CLASS_ID as NID / LM token / first member),
reseat `1F0F2ABB`.

## Current lake

P9 freeze ACCEPTED (`bdddbd68`). Next: **P10/U9R** R0–R9 per PLAN.
Do not re-identify U8-R3. Pred 861 is known MISMATCH, not a new transport bug.
Not U9S/PROGRAM. Gaps C02–C10 remain until U9R names them.
