# Native AI GlassBox Studio — coordination plan

Spec: `NATIVE_AI_GLASSBOX_UXUI_SPEC.md` (source of truth, not restated here).
Law: `AGENTS.md`, `.agents/skills/a7-fpga-gate/SKILL.md`,
`results/A7-EAM-03E/final.md` §23, `docs/contracts/A7-EAM-03E-UI.md`.

## Scope boundary

GlassBox, ILA and LiteScope hardware instrumentation is a hard stop before
Native V1 freeze. This build is host-side only. The waveform plane is a
`WaveformSource` interface with recorded and synthetic implementations; no
capture core is created. Every value this phase emits is stamped `TWIN` or
`SYNTHETIC`.

New code is confined to `web/glassbox/`, `services/glassbox/`,
`contracts/glassbox/` and `.cursor/agents/`.

## Environment facts

| Fact | Value |
|------|-------|
| Node / npm | v24.17.0 / 11.13.0 |
| Next.js / React / Tailwind | 16.3.1 / 19.2.8 / 4 |
| Repo version control | **not a git repository** at repo root |

Because the repo root is not under git, branch and worktree isolation is
unavailable. Isolation is enforced by **single-owner directory assignment**
instead: no two subagents may write the same path. The reviewer audits this
every turn.

## Ownership map — one writer per path

| Subagent | Owns (write) |
|---|---|
| `gb-ux-product` | `web/glassbox/src/features/**/ui/**`, `src/content/**` |
| `gb-design-system` | `web/glassbox/src/design/**`, `src/components/ui/**`, `src/app/globals.css`, `postcss.config.mjs` |
| `gb-frontend-architecture` | `web/glassbox/src/lib/**`, `src/adapters/**`, `src/features/**/{model,ports,hooks}.ts`, `src/fixtures/**`, `src/app/**` except `globals.css`, `tsconfig.json`, `next.config.ts` |
| `gb-scientific-dataviz` | `web/glassbox/src/components/charts/**` |
| `gb-waveform-glassbox` | `web/glassbox/src/components/waveform/**`, `src/workers/**` |
| `gb-storybook-component-qa` | `web/glassbox/.storybook/**`, `src/**/*.stories.tsx` |
| `gb-accessibility` | `web/glassbox/src/a11y/**`, `audit/a11y/**` |
| `gb-playwright-e2e` | `web/glassbox/e2e/**`, `playwright.config.ts` |
| `gb-frontend-performance` | `web/glassbox/audit/perf/**` |
| `gb-backend-contract` | `contracts/glassbox/**` |
| `gb-backend-implementation` | `services/glassbox/**` |
| `gb-independent-reviewer` | `web/glassbox/audit/reviews/**` |

`gb-accessibility`, `gb-frontend-performance` and `gb-independent-reviewer` do
not patch other people's code. They file blocking findings; the owner fixes.

## Skills assigned

| Subagent | Skills read before work |
|---|---|
| `gb-ux-product` | `.agents/skills/anti-ui-slop`, `~/.claude/skills/od-ui-ux-pro-max`, `od-reference-design-contract` |
| `gb-design-system` | `~/.claude/skills/od-shadcn-ui`, `od-web-design-guidelines`, `vercel-composition-patterns`, `od-impeccable-design-polish` |
| `gb-frontend-architecture` | `~/.claude/skills/vercel-react-best-practices`, `vercel-composition-patterns` |
| `gb-scientific-dataviz` | `~/.claude/skills/od-canvas-design`, `od-frontend-design` |
| `gb-waveform-glassbox` | `.agents/skills/a7-fpga-gate`, `~/.claude/skills/od-canvas-design` |
| `gb-storybook-component-qa` | `~/.claude/skills/od-frontend-dev` |
| `gb-accessibility` | `.agents/skills/wcag-accessibility-audit` |
| `gb-playwright-e2e` | `~/.claude/skills/od-frontend-dev` |
| `gb-frontend-performance` | `~/.claude/skills/vercel-react-best-practices`, `web-design-guidelines` |
| `gb-backend-contract` | `.agents/skills/a7-fpga-gate` |
| `gb-backend-implementation` | `~/.claude/skills/websocket-security`, `.agents/skills/a7-fpga-gate` |
| `gb-independent-reviewer` | `.agents/skills/anti-ui-slop`, `a7-fpga-gate`, `~/.claude/skills/od-design-review` |

Discovery entry point: `~/.agents/skills/find-skills/SKILL.md`.

## Open-source references

Structure only, never copied code. `alan2207/bulletproof-react` for feature
folders. `shadcn-ui/ui` for primitive composition. `TanStack/query` for
async-state boundaries. `storybookjs/storybook` for CSF story shape.
`microsoft/playwright` for locator and project matrix. `apache/echarts` for
chart-type selection reasoning only; charts here are hand-built on SVG and
Canvas because the waveform and 32×32 delta views need direct pixel control.

## Dependency graph

```
contracts/glassbox  (gb-backend-contract)
        |                        |
        v                        v
FRONTEND LANE               BACKEND LANE
design-system            backend-implementation
   -> frontend-architecture      |
      -> ux-product              |
      -> scientific-dataviz      |
      -> waveform-glassbox       |
         -> storybook            |
         -> accessibility        |
         -> playwright-e2e       |
         -> performance          |
            \                   /
             FRONTEND_PASS   BACKEND_PASS
                    \         /
                     WIRING (integration subagents, adapters only)
                          |
                     REAL E2E PASS
                          |
                   GLASSBOX_SYSTEM_PASS
```

The contract is the only shared artifact. The two lanes never import each
other until wiring.

## Parallelizable now

- `contracts/glassbox` schema authoring — blocks both lanes, do first.
- Design tokens and Tailwind theme — independent of contract.
- Backend lane from R0 onward — independent of every frontend path.
- Storybook and Playwright configuration — independent of feature code.

## Turn cadence

R0 app shell §6 + design system §7 + frozen contract + fixture/adapter layer
§34/§35 + interaction context §6.3. R1 tabs 1–2. R2 tabs 3–4. R3 tabs 5–6.
R4 tabs 7–8. R5 tabs 9–10. R6 tabs 11–12. R7 tab 13 + §22. R8 §26/§27/§28.
R9 FRONTEND_PASS audit against all fifteen §36 criteria.

## Turn exit gate

Enforced by `gb-independent-reviewer`; see that file for the full list. A FAIL
blocks advancement and is never softened to keep momentum.
