# Agent lock — Arty A7 Transformer Family

## MUST READ FIRST (Native AI / EAM-03E — do not skip)

Before any encoder RTL, stability sweep, A0.2-L, or closeout, read in full:

```text
MUST_READ_UNBLOCK_H5.md
results/A7-EAM-03E/MUST_READ_UNBLOCK_H5.md
```

Cursor rule: `.cursor/rules/MUST_READ_UNBLOCK_H5.mdc` (`alwaysApply: true`).

Bottleneck is **H5 gated DIFF** (`d1 < 4096`), not S2 Wh-clamp (FALSIFIED) and not A0.3 silicon (already exact). Next: ungated DIFF twin, one law id. First reply line: `MUST_READ_UNBLOCK_H5: read. Next = ungated DIFF twin (not S2, not glue).`

---

Authority: `Revised Arty A7 Program Master.md` (sole program roadmap).  
Historical only: `Arty A7-100T Native Online-Training Transformer Program.md` and `docs/architecture/PROGRAM.md` (DEPRECATED).

Current milestone: **A7-LM-06** (OPEN 2026-08-18 after LM-05 BOARD_PASS).  
A7-LM-05 is **BOARD_PASS / FROZEN**. Granted claim: `ARTY_A7_399K_DDR_DEPTH_LM_BOARD_VALIDATED` (depth + exact oracle; not 8-class retrieval). Bit SHA `1AA0B5C481B0ADF3CAA599F081B430AF3C28A26FB4715DC56A0D25D940548F51`.  
A7-LM-04 R5 is **BOARD_PASS / FROZEN** (`ARTY_A7_100K_DDR_ONLINE_LM_BOARD_VALIDATED`, target-switch only).  
A7-LM-00 / 01 / 02 / 03 / 04 / 05 are **BOARD_PASS / FROZEN**. Do not rebuild or redesign them.

Authority order: board evidence > `docs/contracts/A7-LM-xx.md` > immutable BOARD_PASS releases > Revised Master > research-branch docs > papers / chat suggestions. AI cannot declare BOARD_PASS.

Do not:

- use the deprecated Program file for architecture, order, law, DDR interface, gates, or next tasks
- overwrite frozen `arty_a7_lm00.bit` / `lm01` / `lm02` / `lm03` / `lm04r5` / `lm05` (C02)
- hand-edit MIG `mig.prj` (official Digilent AXI MIG only; no native `app_*`)
- change `law_id` while keeping the milestone name
- let the host compute gradient / update / next-token / CE in evidence
- close an A7-LM contract from a shadow branch (A7-MEM-RECOMP, A7-QTRAIN, A7-LR, A7-OPT, A7-KD-SHADOW, A7-INF-*, A7-SSM, A7-PEFT)
- start A7-LM-07+ before 06 PASS
- use LM-06 to broaden the LM-04 R5 or LM-05 depth claims
- claim conversation, LLM, or open-domain chat
- treat this as a continuation of the 8-agent SNN

---

## A7-NATIVE-GRAPH (new branch — does not replace encoder lane)

Authority package: `docs/NATIVE_AI_ARTY_A7_BLUEPRINT/` (from `NATIVE_AI_ARTY_A7_COMPLETE_BLUEPRINT.zip`).  
Operating docs: `docs/native_graph/{AGENT_PLAN,RESOURCE_BUDGET,CONTRACT_FREEZE,TEST_MATRIX}.md`.  
Crew: `.agents/workflows/native-graph/registry.yaml` + `.cursor/agents/a7-ng-*.md`.  
Pipeline: `.agents/workflows/native-graph/pipeline.json` (live queue through §14 / HITL).  
Loop: `docs/NATIVE_AI_ARTY_A7_BLUEPRINT/15_CURSOR_BLUEPRINT_LOOP.md` + `LOOP_STATE.json`.  
**feedback + SPEC compliance:** `results/A7-NATIVE-GRAPH/STATUS/COMPLIANCE_INDEX.md` (start here when reconciling design audits with evidence).  
**Execution path (human-approved):** `docs/NATIVE_AI_ARTY_A7_BLUEPRINT/16_MASTERPLAN_EXECUTION_PATH.md`; package finish audit: `results/A7-NATIVE-GRAPH/STATUS/MASTERPLAN_FINISH_STATUS.md`.  
Dispatch: parent = orchestrator only; `python .agents/workflows/native-graph/run_blueprint_loop.py --dispatch` then Cursor **Task** `character_id`.  
Skill: `.agents/skills/a7-native-graph-gate/SKILL.md`.  
Results: `results/A7-NATIVE-GRAPH/`. RTL: `rtl/native_graph/` only.

Hard stops: `docs/NATIVE_AI_ARTY_A7_BLUEPRINT/04_HARDSTOPS.md`.  
Basys3 eight-agent zip is **research reference** under `docs/native_graph/references/basys3-eight-agent/` — ADAPT lessons only; never port Basys3 pinouts or treat as Arty BOARD_PASS.  
Hugging Face BitNet / Qwen AWQ = design inspiration (`results/A7-NATIVE-GRAPH/HF_RESEARCH/`); never host EVAL answer path.

Do not overwrite frozen A0.3 / 01R / 02M / LM-06. Do not claim Native V1 BOARD_PASS from scaffolding alone. GlassBox remains out of scope until Native V1 freeze.

---

## Learned User Preferences

- Keep existence before quality: prove FPGA-owned `pred=664` before quality, perf, or BRAM-optimization work.
- Run the E2R board existence ladder as one-change-per-experiment (one unknown, one RTL/probe delta, then rebuild/program/UART).
- Parent chat stays `a7-ng-orchestrator` only: `python .agents/workflows/native-graph/run_blueprint_loop.py --dispatch` then Task with pipeline `character_id`; do not implement silicon gates or edit board RTL in the parent.
- Board silicon work belongs in the board worktree; keep main-tree STATUS/dispatch ownership separate from board build/program/UART.

## Learned Workspace Facts

- Main repo: `D:/Jetking_sem4/SEM_4/arty-a7-online-lm`. Board existence worktree: `D:/Jetking_sem4/SEM_4/arty-a7-online-lm-board` (RTL/build/bit/UART); main tree holds `results/A7-NATIVE-GRAPH/STATUS/` dispatch and closeout pointers.
- E2R F1 ladder (post-F1u): F1k restored AR handshake CDC into LM; F1r–F1s identified WDMA CDC ghost `m_busy` (partial `busy_hold` fix; tile advanced to D_WAITDONE); F1t–F1u showed `s_go` never reaches `ddr_tile_dma` (`DMA_ST=IDLE`, `SGO=0`) under subclass `LM_WDMA_MUX_OWNER_BLOCK`; F1v owner-grant/`m_go` probe in flight.
- `NATIVE_V1_EXISTENCE_BOARD_PASS` requires UART `pred=664`; AI must not self-declare `BOARD_PASS` or `NATIVE_V1_MINI_AI_BOARD_PASS`.
- UART evidence: arm capture on COM before programming; occasional 0-byte captures happen—recapture before treating empty UART as design FAIL.
- Standing doctrine: `.agents/handoff/EXISTENCE_BEFORE_QUALITY.md` and Native STATUS existence law; XSim ≠ board; harness ≠ HS-02.
