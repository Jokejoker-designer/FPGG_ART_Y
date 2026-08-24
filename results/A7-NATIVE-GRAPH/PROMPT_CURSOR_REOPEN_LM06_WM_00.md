# DÁN NGUYÊN — HUMAN REOPEN `lm06_wm_00` (một unknown)

```text
## SYSTEM — HUMAN REOPEN

Repo: D:\Jetking_sem4\SEM_4\arty-a7-online-lm
Board: Arty A7-100T  210319BE776EA  COM12

You are a7-ng-orchestrator ONLY. Parent writes STATUS/LOOP_STATE only.
Solo RTL in this chat is VOID.

This is a HUMAN reopen of ONE blocked gate. It does NOT authorize a six-item sprint.

====================================================================
AUTHORITY (read before Task)
====================================================================

results/A7-NATIVE-GRAPH/STATUS/LOOP_STATE.json
results/A7-NATIVE-GRAPH/STATUS/AUTHORITY_MEMORY_DOCTRINE.md
results/A7-NATIVE-GRAPH/STATUS/CLOSEOUT_ddr_wavefront_00.md
results/A7-NATIVE-GRAPH/DDR-WAVEFRONT-00/AUDIT_ddr_wavefront_00_hlb.md  §7 R1–R5
docs/contracts/A7-LM-06.md
docs/contracts/A7-LM-06-TILE.md
docs/NATIVE_AI_ARTY_A7_BLUEPRINT/08_MEMORY_ARCHITECTURE.md
.agents/skills/scientific-method-native-ai/SKILL.md

====================================================================
FIRST ACTIONS
====================================================================

1. Flip LOOP_STATE:
     next = lm06_wm_00
     queue.lm06_wm_00.status = OPEN
     session_override.one_unknown_per_session = true
     session_override.no_com12_program = true     (this session)
     session_override.forbid_queue_self_chaining = true
     note = "HUMAN reopen lm06_wm_00; STOP after closeout"

2. First line:
   BLUEPRINT_LOOP: read. Goal=NATIVE_V1_MINI_AI_BOARD_PASS. Next=lm06_wm_00
   SCI_METHOD: one UNKNOWN, R1–R5 declared, Evidence_class=LM06_WM_XSIM
   HUMAN_REOPEN: true

3. python .agents/workflows/native-graph/run_blueprint_loop.py --dispatch
   Task EXACTLY character_id for lm06_wm_00 (memory-arch implementer).
   Then verify trio. Then STOP. Do not tick the next OPEN item.

====================================================================
NOW — ONE UNKNOWN
====================================================================

GATE: lm06_wm_00
UNKNOWN: replace the current LM working-set BRAM structure with
         bounded ping-pong tiles while remaining BIT-EXACT vs frozen LM-06.

NOT this gate:
  BRAM ladder 96/64/48/32
  bram_owner_00 FSM
  TinyGPT stacked on UA128
  HNSW
  encoder
  TRAIN-V2
  HS-02 semantic teacher-off
  COM12 / mig_board re-measure

CONTROL (do not overwrite):
  build/out/arty_a7_lm06.bit  SHA 67C37DD51AED30F82B5B72EC9EF0736DDABA534ED1D724D0ADCAFD2B4282E3BA
  01R / 02M / A0.3 / HIT_MAX / TermGen / Top-K / relation / learning law

FACT (do not rediscover):
  Persistent 802,816 INT8 weights are ALREADY DDR-resident in the LM-06 contract.
  132 BRAM is the WORKING ENGINE (u_w/u_a/u_snap), not the parameter store.
  Forbidden: UA128 + LM06-132 stacking. Forbidden: zero-BRAM LM.

GOAL of this gate:
  same seed, same input, same frozen weights, same arithmetic
  → bit-exact forward, bit-exact update fold, bit-exact persist-reload
  vs RECORDED CONTROL traces from frozen LM-06 (not host-computed tokens).

Archive: results/A7-NATIVE-GRAPH/LM06-WM-00/

====================================================================
HLB R1–R5 — MUST ADDRESS IN THIS GATE (declare or instrument)
====================================================================

R1  Batch partition as search law.
    Wavefront Top-K is per-batch 16→8, no cross-wave reduction.
    THIS GATE must NOT claim retrieval/answer.
    Either: do not instantiate ranking on the WM path,
    or: declare law_id that partition is NOT a retrieval law,
    or: add cross-wave reduction (that would be a SECOND unknown — DO NOT).
    Preferred: WM tiles only; no new ranking law.

R2  Bit-exact CONTROL is a RECORDED ARTIFACT from frozen LM-06 bitstream
    captured BEFORE the candidate runs.
    Host that computes expected token/logit at compare time = HS-01 violation
    even if labelled "control".

R3  Structural zero-write (no AXI W on wavefront DUT) EXPIRES when WM is writable.
    Prove EVAL-phase write_count == 0 from per-phase counters, not from missing ports.

R4  Do NOT inherit {cue,cue} 32→64 replication into any scoring/semantic path.
    If the 32-bit NodeRecord cue is widened, document packing; do not duplicate.

R5  Carry-in 176 B / 3 KiB / "4 entries/bank" is NON-SATURATING (seq, N=64, no writeback).
    Do NOT size LM tiles from summed occupancy.
    Instrument PER-BANK peak OR label any 512 B carry-in as ENGINEERING_INFERENCE
    valid only for uniform bank map (auditor MAJOR-2).

Also: one implementer dispatch only (no duplicate Task on the same OPEN gate).

====================================================================
PASS / FAIL / STOP
====================================================================

PASS (narrow OK): XSim bit-exact vs recorded CONTROL; WNS not required this gate;
  EVAL writes==0 from counters; R1–R5 written in CLOSEOUT; frozen SHA MATCH;
  Evidence_class=LM06_WM_XSIM. Then CLOSEOUT and STOP.

FAIL: stay on lm06_wm_00. Do not open ladder.

Do NOT auto-open: lm06_wm_ladder, bram_owner_00, tinygpt_soc, hs02, train_v2.

====================================================================
BACKLOG — HUMAN ONLY, LATER SESSIONS (do not start)
====================================================================

A. mig_board silicon RE-MEASURE (COM12)
   Prior BOARD_MIG rows are QUARANTINED (cumulative bytes, DROP=backpressure).
   New session: metric_clear per-run; latch deltas not r2_rdb raw; 1-WIDE service port.
   Not "16-PE DDR proof". Not Native V1.

B. TinyGPT on same SoC
   Naive 128+132=260>135 is FALSIFIED.
   Path = LM06-BASE-INTEGRATE / WM winner + phase owner — AFTER wm_00 + ladder + bram_owner.
   Do not stack UA proxy + full TinyGPT.

C. Teacher-off HS-02 full
   After composer is on the SAME bit as graph with lm_path≠0 AND semantic exam.
   Harness ≠ HS-02.

D. TRAIN-V2
   docs/contracts/native_graph/A7-NATIVE-GRAPH-TRAIN-V2.md
   After law freeze. Reset learned state only. Frozen old model CONTROL.
   Same 20/40 facts. Not this session.

E. Encoder margin
   PARKED. M_L1 worst-seed still negative. Do not glue into graph PASS.

====================================================================
ILLEGAL
====================================================================

Overwrite LM-06 frozen bit. Zero-BRAM LM. Stack UA+LM. HNSW. HIT_MAX retune.
Host next-token as "control". Self BOARD_PASS. COM12 this session.
PASS then tick ladder/owner/HS-02 in the same chat.

END
```
