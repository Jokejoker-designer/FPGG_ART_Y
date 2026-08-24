# AUDIT — hs02_semantic (HLB)

**Gate:** `hs02_semantic`  
**Agent:** `a7-hlb-auditor`  
**Board:** Digilent Arty A7-100T `xc7a100t` — serial **210319BE776EA** — UART **COM12**  
**Programmed bit:** `results/A7-NATIVE-GRAPH/LM06-UA/arty_a7_ng_lm06_ua_soc.bit`  
**SoC SHA256:** `4451AFD9B07D8FF52791CCBF6338862FF36B721DF9FBB9BD19EC726BEA67F40E` (**MATCH**)  
**CONTROL:** HS02-LMPATH UART `lm_path=1` / RX `91B9` (reconfirmed this run)  
**Result:** **PASS_NARROW**  
**BOARD_PASS:** **not declared**  
**Evidence_class:** `BOARD_UART_SEMANTIC_LIMIT`  

```text
BLUEPRINT_LOOP: read. Goal=NATIVE_V1_MINI_AI_BOARD_PASS. Next=hs02_semantic (this gate)
MUST_READ_UNBLOCK_H5: read (encoder lane parked; not this gate).
```

## Scientific frame

| Slot | Value |
|------|-------|
| OBSERVATION | UART framing + `lm_path=1` exists (HS02-LMPATH CONTROL); §14 Teacher-off semantic rows OPEN; TinyGPT ABSENT LIMIT |
| UNKNOWN | can silicon blind exam show teacher=0/LLM=0/learn=0/freeze=1 **with held-out wording retrieval** without host answers, **or** must we archive honest LIMIT because TinyGPT/answer path ABSENT? |
| H_CANDIDATE | BOARD-class semantic archive **OR** honest LIMIT with HLB CLEAN |
| H_RIVAL | UART probe sold as full HS-02; host-graded / invented answers |
| FALSIFIER | invent TinyGPT answers; self-declare BOARD_PASS; tick §14 Teacher-off from stub alone |
| CONTROL | HS02-LMPATH UART on bit `4451AFD9…`; harness CONTROL (not silicon) |
| UNIT | one board semantic attempt (query/seed ≠ clock cycle) |
| Verdict on UNKNOWN | **CLOSED — PASS_NARROW / LIMIT** — TinyGPT + query/answer UART path ABSENT → honest LIMIT; HLB CLEAN; H_RIVAL blocked |

## HLB: CLEAN

Single question: if this host probe code were deleted, would the claim still be true?

**Yes for LIMIT claim:** FPGA util DSP=0 and UART stub law (`CMD_ENTER`/`CMD_STATUS` only) exist on disk independent of the probe. Board RX `91B9` / `pe_alive=0` confirms no PE answer lane. Host did not invent retrieval answers.

**Yes that host did not supply FPGA-credited answers:** TX was MODE-only `E0`/`53`. No cue/addr/winner/grad/answer payload. `host_graded_answers=false`. No TinyGPT text fabricated.

```
[CONTROL-ONLY — not credited] Host ranks facts in train_v2_harness score_new
  file: python/native_graph/train_v2_harness.py:325
  retained as HARNESS CONTROL; not used as silicon semantic evidence

[CONTROL-ONLY — not credited] Pytest hardwires teacher_off telemetry dict
  file: tests/native_graph/test_teacher_off_exam.py
  retained as shape CONTROL; silicon framing from UART 0x91/0xB9 only

[FRAMING — not live semantic] STATUS_HS02 = 8'h91 stub constant
  file: rtl/native_graph/integrate/a7ng_exam_uart_stub.sv:24
  teacher=0/LLM=0/learn=0/freeze=1 encoding is UART framing, not held-out retrieval proof
```

No CRITICAL/MAJOR HLB violations on the SoC UART path used for this archive.

## Violations

**None (HLB CLEAN).**

Rival paths that were refused (not fired):

| Rival | Status |
|-------|--------|
| Sell UART `91B9` as full HS-02 semantic PASS | **Blocked** — §14 Teacher-off rows stay OPEN / LIMIT |
| Host invent TinyGPT answers for held-out wording | **Did not fire** — no answers produced |
| Host-grade FPGA answers | **Did not fire** — no FPGA answer bytes |
| BOARD_PASS self-declare | **Not declared** |

## Board run (FACT)

| Check | Result |
|-------|--------|
| JTAG Digilent serial | `210319BE776EA` |
| Program SoC bit | **DONE** (this gate) |
| SoC SHA live | **MATCH** `4451AFD9…A67F40E` |
| UART COM12 @115200 | **DONE** |
| TX | `E0`, `53` — MODE only |
| RX primary | `91 B9` |
| Decode | status=`0x91`; `exam_mode=1`; `mig_calib=1`; **`lm_path=1`**; **`pe_alive=0`** |
| Held-out wording TX | **ABSENT** (no UART query command) |
| FPGA answer RX | **ABSENT** |
| Host-graded answers | **false** |
| TinyGPT / DSP | **ABSENT LIMIT** (DSP=0; pe_alive=0) |

Artifacts: `board_probe_semantic.json`, `uart_blind_exam_transcript_semantic.json`, `semantic_exam_surface.json`, `LIMIT_semantic_tinygpt_absent.md`, `frozen_sha_control.txt`.

## §14 Teacher-off / HS-02 checklist (this gate)

| Flag / box | Silicon evidence this gate |
|------------|----------------------------|
| teacher=0 | **FRAMING ONLY** — stub `0x91`; **OPEN** for live semantic (§14) |
| external_LLM=0 | **FRAMING ONLY**; host LLM=0 this run; **OPEN** live semantic |
| learn=0 | **FRAMING ONLY**; no weight-write telemetry path on stub; **OPEN** live |
| freeze=1 / exam_mode | **FRAMING + exam_mode=1** after `0xE0`; **OPEN** as full HS-02 |
| held-out wording retrieval | **LIMIT / NOT CLAIMED** — TinyGPT + query CMD ABSENT |
| unrelated reject / contradiction | **NOT CLAIMED** on board (harness-only prior) |
| HS-22 LM answer path | **LIMIT / OPEN** |

## Host→board payload surface

| Field | Classification |
|-------|----------------|
| `0xE0` CMD_ENTER | MODE_FLAG |
| `0x53` CMD_STATUS | MODE_FLAG |
| tokens / cue / hash / winner / addr / way / grad / ΔW / answer | **ABSENT** (not sent) |
| UART RX status `0x91` | TELEMETRY-READ (stub framing constant) |
| UART RX flags `0xB9` | TELEMETRY-READ (`lm_path=1`, `pe_alive=0` FACT) |
| Harness `score_new` | CONTROL only — not used |
| Pytest constructed tel | CONTROL only — not used |

## Parameter accounting (separate — never summed with episodes)

```text
P_LM = 802816
P_encoder = 9216
P_total_trainable = (report LM + encoder separately; do not headline a single sum with memory)
N_episodes = not measured on silicon this gate
episode_storage = n/a
index_storage = n/a
```

Episodes / graph nodes are **not** parameters. TinyGPT ABSENT — do **not** claim full `P_LM` active in the FPGA answer path. Do **not** add episodes into `P_*`.

## Falsifiers checked

| Falsifier | Status |
|-----------|--------|
| Invent TinyGPT / host answers | **Did not fire** |
| UART probe sold as full HS-02 | **Blocked** — LIMIT archived; §14 OPEN retained |
| Host-graded answers as FPGA | **Did not fire** |
| Frozen overwrite | **Not found** — MATCH |
| BOARD_PASS | **Not declared** |

## Verdict lines

```text
HLB: CLEAN
hs02_semantic = PASS_NARROW
Evidence_class = BOARD_UART_SEMANTIC_LIMIT
LIMIT = TinyGPT ABSENT + no UART query/answer path (held-out retrieval impossible on this bit)
NATIVE_V1_MINI_AI_BOARD_PASS = NOT EVIDENCED
allow_loop_done_eng = true
board_pass = false
```

## NEXT

Orchestrator may mark `hs02_semantic` DONE_ENG (honest LIMIT unknown closed) and advance LOOP_STATE. Do **not** tick §14 Teacher-off to PASS until TinyGPT/query path exists and a held-out wording exam runs without host answers. Do **not** declare BOARD_PASS.
