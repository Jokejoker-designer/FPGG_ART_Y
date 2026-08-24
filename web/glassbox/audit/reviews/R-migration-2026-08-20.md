# Independent review — migration honesty turn (2026-08-20)

Reviewer: orchestrator filing as `gb-independent-reviewer` owner of this path.
Verdict: **FAIL to advance cadence** (work is real; exit gate is incomplete).

## What was inspected

- `web/glassbox/src/components/tabs/learning.tsx`
- `web/glassbox/src/components/tabs/overview.tsx`
- `web/glassbox/src/components/insight.tsx`
- `web/glassbox/src/lib/metrics.ts`
- `services/glassbox/**`
- Commands below, not claimed from memory

## Commands

| Command | Result |
| --- | --- |
| `web/glassbox` `npx tsc --noEmit` | exit 0 |
| `web/glassbox` `npm run build` | exit 0 (chunk-size warning) |
| `services/glassbox` `npm run typecheck` | exit 0 |
| `services/glassbox` `npm test` | 4/4 pass |

## Findings that block FRONTEND_PASS / turn advance

1. Storybook is not re-established on Vite. Stories are excluded from `tsc`. No story per new/changed screen state.
2. Playwright was not re-run this turn against the TanStack shell. Old Next-oriented e2e is not evidence.
3. Contrast checker still targets the previous token names (`m5` open).
4. Frontend still fixture-local; backend exists but is **not wired** (correct). Do not call FRONTEND_PASS or BACKEND_PASS.
5. Remaining SPEC tabs (input, compare-as-own-tab, memory, model, output, waveform, replay, evidence, §22 as dedicated feature, §26–§28) are not signed.

## Honesty that did land

- Learning reads `violated` / writes from the contract, not “margin > 0 ⇒ không học”.
- Overview no longer prints token/s, EAM hit, DDR %, LM-06-as-running, or invented LUT 65%.
- Insight rail no longer stamps BOARD; health copy follows `COLLAPSED`.
- Backend binds 127.0.0.1, stamps SYNTHETIC, returns 404 rather than fabricating an interaction. No serial port.

## Flags

- FRONTEND: not PASS
- BACKEND: not PASS
- WIRING: not started
- GLASSBOX_SYSTEM_PASS: not reached
