# DÁN NGUYÊN VÀO CURSOR — Blueprint Loop (không dừng tới GOAL)

Đọc `docs/NATIVE_AI_ARTY_A7_BLUEPRINT/15_CURSOR_BLUEPRINT_LOOP.md` rồi làm.  
Prompt cũ `results/A7-EAM-03E/PROMPT_CURSOR_LOOP_GOAL.md` **không** dùng cho lane graph (queue A0.3 đã xong / encoder parked).

---

## SYSTEM

You already stopped after NG-05 XSim. That stop is **illegal**. Resume **now**.

First commands this session (do them, do not describe them):

```text
python .agents/workflows/native-graph/run_blueprint_loop.py --tick
```

Then read in full:

```text
docs/NATIVE_AI_ARTY_A7_BLUEPRINT/README.md
docs/NATIVE_AI_ARTY_A7_BLUEPRINT/01_SYSTEM_BLUEPRINT.md
docs/NATIVE_AI_ARTY_A7_BLUEPRINT/02_IMPLEMENTATION_ROADMAP.md
docs/NATIVE_AI_ARTY_A7_BLUEPRINT/04_HARDSTOPS.md
docs/NATIVE_AI_ARTY_A7_BLUEPRINT/13_CURSOR_MASTER_PROMPT.md
docs/NATIVE_AI_ARTY_A7_BLUEPRINT/14_FINAL_ACCEPTANCE_CHECKLIST.md
docs/NATIVE_AI_ARTY_A7_BLUEPRINT/15_CURSOR_BLUEPRINT_LOOP.md
docs/native_graph/CONTRACT_FREEZE.md
results/A7-NATIVE-GRAPH/STATUS/LOOP_STATE.json
```

First output line:

`BLUEPRINT_LOOP: read. Goal=NATIVE_V1_MINI_AI_BOARD_PASS. Next=ng05_persist`

Repo: `D:\Jetking_sem4\SEM_4\arty-a7-online-lm`  
Board: Digilent Arty A7-100T `xc7a100tcsg324-1` serial `210319BE776EA` COM12  
Do not wait for Grok. Not PYNQ. Not GlassBox as Native V1.

====================================================================
GOAL  (loop exits ONLY here)
====================================================================

Archived evidence for **every required box** in `14_FINAL_ACCEPTANCE_CHECKLIST.md`, then:

```text
results/A7-NATIVE-GRAPH/PROJECT_COMPLETE.md
```

Human may declare `NATIVE_V1_MINI_AI_BOARD_PASS`. You never self-stamp BOARD_PASS.

GOAL is **not** met by: NG-00..05 XSim, a WNS number, LM-06 frozen bit sitting idle, encoder A0.1-T, or “pipeline PASS”.

Narrow claim from `01_SYSTEM_BLUEPRINT.md`. Never ChatGPT-on-FPGA. Never mix P_LM / P_encoder / N_episodes.

====================================================================
LOOP
====================================================================

Obey `15_CURSOR_BLUEPRINT_LOOP.md` §2 exactly.  
PASS → next OPEN item in `LOOP_STATE.json` **same session**.  
FAIL → stay on bottleneck; do not idle.

====================================================================
NOW  (do not re-plan NG-00..05)
====================================================================

`LOOP_STATE.next` = **ng05_persist**

Roadmap NG-05 PASS still needs: teacher-off **DDR-backed** prior persists across power; reset removes behavior; retrain differs; host cannot inject edge weights.

Then: archive NG-02/03 xsdb logs (auditor MAJOR) if board present, else NG-06 (16 PE × 256 logical contexts) without waiting.

One unknown. New files under `rtl/native_graph/` and `results/A7-NATIVE-GRAPH/`. Do not overwrite `80F2ED9E…` / `05E478FF…` / 01R / 02M / LM-06.

====================================================================
HARD STOPS
====================================================================

`04_HARDSTOPS.md` HS-01…HS-25. Especially HS-01 host learning boundary, HS-02 teacher-off, HS-09 physical vs logical lanes, HS-11 BRAM 180% naive sum.

END
