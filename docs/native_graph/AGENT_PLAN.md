# A7-NATIVE-GRAPH — Agent Plan

**Board:** Digilent Arty A7-100T `xc7a100tcsg324-1`  
**Authority blueprint:** `docs/NATIVE_AI_ARTY_A7_BLUEPRINT/`  
**Lane:** new milestone namespace `A7-NATIVE-GRAPH-*` (does **not** overwrite 03E / 01R / 02M / LM-06)

## Doctrine

```text
FITS != RUNS != TRAINS != CONVERGES != USEFUL
LOGICAL AGENTS != PHYSICAL PARALLEL LANES
TEACHER SUPERVISION != HOST OPTIMIZATION
```

Hard stops: `docs/NATIVE_AI_ARTY_A7_BLUEPRINT/04_HARDSTOPS.md` (HS-01…HS-25).

## Orchestration pattern (MAF-aligned)

Source pattern: `E:\agents\characters\registry.yaml` + `E:\agents\workflows\flows\`.

| Pattern | Use |
|---------|-----|
| sequential | NG-00 → NG-01 → NG-02 → NG-03 (gated) |
| concurrent | RTL PE + Top-K + memory architecture reviews after contracts freeze |
| handoff | evidence auditor → vivado gate → scientific reviewer |
| human_in_the_loop | BOARD_PASS / bitstream program / claim language |

## Specialist roster (Cursor subagents)

| Agent id | File | Owns | PASS deliverable |
|----------|------|------|------------------|
| `a7-ng-orchestrator` | `.cursor/agents/a7-ng-orchestrator.md` | stage order, HITL | stage gate table |
| `a7-ng-rtl-scorer` | `.cursor/agents/a7-ng-rtl-scorer.md` | `rtl/native_graph/scorer*` | 16-lane XSim exact |
| `a7-ng-topk-frontier` | `.cursor/agents/a7-ng-topk-frontier.md` | Top-K / bucket FIFO | deterministic K winners |
| `a7-ng-memory-arch` | `.cursor/agents/a7-ng-memory-arch.md` | DDR shard + BRAM hotset | bytes/query measured |
| `a7-ng-teacher-protocol` | `.cursor/agents/a7-ng-teacher-protocol.md` | lesson/telemetry schemas | anti-leak tests green |
| `a7-ng-xsim-verify` | `.cursor/agents/a7-ng-xsim-verify.md` | TB + golden bags | XSim PASS markers |
| `a7-vivado-gate` | `.cursor/agents/a7-vivado-gate.md` | Vivado/Vitis MCP | WNS≥0 TNS=0 |
| `a7-evidence-auditor` | `.cursor/agents/a7-evidence-auditor.md` | closeout honesty | no overclaim |
| `a7-hlb-auditor` | `.cursor/agents/a7-hlb-auditor.md` | host learning boundary | HLB PASS |
| `a7-ng-scientific` | `.cursor/agents/a7-ng-scientific.md` | experiment design | one-unknown rule |
| `a7-ng-hf-research` | `.cursor/agents/a7-ng-hf-research.md` | HF low-bit inspiration | ADOPT/ADAPT/DEFER table |

Existing GlassBox agents (`gb-*`) stay **OUT OF SCOPE** until Native V1 freeze.

## First execution window

**Historical:** NG-00 → NG-03 was the opening window (done as engineering PASS).

**Live:** obey `15_CURSOR_BLUEPRINT_LOOP.md` and `LOOP_STATE.json`. First OPEN = `ng05_persist`, then NG-06…NG-09, MEM, LM compose, §14. Do not stop at NG-05 XSim. Do not jump to 800k episodes.

1. Freeze contracts + anti-leak (NG-00) — DONE  
2. 16-lane scorer (NG-01) — DONE eng.  
3. Top-K (NG-02) — DONE eng. (silicon log debt)  
4. DDR hotset (NG-03) — DONE eng. (silicon log debt)  
5. **Now:** NG-05 DDR persist → NG-06 shared frontier → … → teacher-off → §14

## Tooling

| Tool | Role |
|------|------|
| Vivado MCP `project-0-arty-a7-online-lm-vivado` | synth/impl/timing/util |
| Vitis MCP `project-0-arty-a7-online-lm-vitis` | host/UART when needed |
| Hugging Face MCP | BitNet / Qwen AWQ **inspiration only** — not host inference in EVAL |
| `E:\agents\xilinx-skill` | Vivado/Vitis procedure skill |

## Workflow files

- `.agents/workflows/native-graph/pipeline.json` — stage graph  
- `.agents/workflows/native-graph/registry.yaml` — crew registry  
- `.agents/skills/a7-native-graph-gate/SKILL.md` — operating skill
- `.agents/skills/scientific-method-native-ai/SKILL.md` — K-Dense method subset; plan `STATUS/PLAN_KDENSE_20260822.md`  

## Forbidden

- Overwrite frozen bits (A0.3 / 01R / 02M / LM-06)  
- Host gradient / ΔW / winner / address / next-token  
- Claim logical contexts as physical cores  
- Glue encoder research failure into graph by renaming milestones  
- GlassBox before Native V1 freeze  
