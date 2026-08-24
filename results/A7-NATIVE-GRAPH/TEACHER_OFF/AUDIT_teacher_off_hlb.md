# AUDIT — teacher_off_exam (HLB / HS-02 silicon on SoC bit)

**Gate:** `teacher_off_exam`  
**Agent:** `a7-hlb-auditor`  
**Board:** Digilent Arty A7-100T `xc7a100t` — serial **210319BE776EA** — UART **COM12**  
**Programmed bit:** `results/A7-NATIVE-GRAPH/INTEGRATE/arty_a7_ng_integrate_fit_soc.bit`  
**SoC SHA256:** `D65F3524BE1BD53D6B461CD8CD872DDCF8DE04EC4B7B0C8FB4CA4F959559A4DF` (**MATCH**; live rehash)  
**Proxy CONTROL:** `D2FC41A7…` — **not programmed** for this claim  
**Result:** **PASS_NARROW**  
**BOARD_PASS:** **not declared**  
**GlassBox:** not claimed  

```text
BLUEPRINT_LOOP: read. Goal=NATIVE_V1_MINI_AI_BOARD_PASS. Next=teacher_off_exam (this gate)
MUST_READ_UNBLOCK_H5: read (encoder lane parked; not this gate).
```

## Scientific frame

| Slot | Value |
|------|-------|
| OBSERVATION | SoC bit + UART stub exist; prior FAIL was missing path |
| UNKNOWN | does programming SoC + blind teacher-off UART exam yield BOARD-class evidence, or honest FAIL/LIMIT because LM-06 weights ABSENT? |
| H_CANDIDATE | silicon archive with bit SHA + UART transcript + HLB clean |
| H_RIVAL | host-graded harness; inventing LM-06 answers; programming proxy D2FC41A7 |
| FALSIFIER | teacher in path; frozen overwrite; BOARD_PASS self-declare |
| CONTROL | harness `GATE_teacher_off.md`; proxy bit not programmed |
| Verdict on UNKNOWN | **CLOSED PASS_NARROW + LIMIT** — SoC programmed; UART returns silicon `0x91` framing with `exam_mode=1`; `lm_path=0` confirms **LM-06 weight fabric ABSENT** blocks meaningful retrieval; no host answers invented |

## HLB: CLEAN

(Scope = this silicon stub exam claim: mode telemetry only. Harness remains CONTROL — do not credit to FPGA.)

Single question: if host harness / host grade code were deleted, would the silicon framing claim still be true?

**Yes for framing:** UART transcript `91…` was read from COM12 after programming SoC `D65F3524…`. Host sent only `0xE0` / `0x53` mode bytes. No cue/addr/winner/grad/answer payload. No host-scored “FPGA answer.”

**No for semantic retrieval / LM participation (HS-22):** not claimed. `lm_path=0` on wire; LM-06 weights ABSENT by SoC design (integrate LIMIT).

```
[CONTROL-ONLY — not credited] Host ranks facts in train_v2_harness score_new
  file: python/native_graph/train_v2_harness.py (prior CRITICAL)
  retained as HARNESS CONTROL; not used as silicon evidence this run

[CONTROL-ONLY — not credited] Pytest hardwires teacher_off telemetry dict
  file: tests/native_graph/test_teacher_off_exam.py:17–34
  retained as shape CONTROL; silicon flags taken from UART 0x91, not pytest
```

No new CRITICAL/MAJOR violations on the SoC UART path used for this archive.

## Board run (FACT)

| Check | Result |
|-------|--------|
| JTAG Digilent serial | `210319BE776EA` |
| Program SoC bit | **DONE** (not proxy) |
| SoC SHA live | **MATCH** `D65F3524…A4DF` |
| UART COM12 @115200 | **DONE** |
| TX | `E0` (enter exam), `53` (status) — MODE only |
| RX (primary) | `91 D9` then re-probe `91 99` |
| Decode | status=`0x91` (teacher=0 LLM=0 learn=0 freeze=1 framing); `exam_mode=1`; `mig_calib=1`; `lm_path=0`; `pe_nibble=9` |
| Retrieval answers | **none** (stub has no answer path) |
| Host-graded answers | **false** |
| Proxy programmed | **false** |

Artifacts: `uart_blind_exam_transcript.json`, `board_probe.json`.

## HS-02 checklist (silicon)

| Flag | Silicon evidence |
|------|------------------|
| teacher=0 | **EVIDENCE (framing)** — FPGA status byte `0x91` bit pattern / stub law |
| external_LLM=0 | **EVIDENCE (framing)** — same |
| learn=0 | **EVIDENCE (framing)** — same |
| freeze=1 / exam_mode | **EVIDENCE** — `exam_mode=1` after `0xE0` in flags byte |
| held-out wording retrieval | **LIMIT / NOT CLAIMED** — stub has no query→answer path; LM-06 ABSENT |
| weight writes in EVAL | **not measured as counters**; stub does not expose weight-write telemetry; SoC has no LM-06 weight fabric |
| HS-22 LM in output path | **OPEN / LIMIT** — `lm_path=0` |

## Host→board payload surface (this run)

| Field | Classification |
|-------|----------------|
| `0xE0` CMD_ENTER | MODE_FLAG |
| `0x53` CMD_STATUS | MODE_FLAG |
| tokens / cue / hash / winner / addr / way / grad / ΔW / answer | **ABSENT** (not sent) |
| UART RX status `0x91` | TELEMETRY-READ (FPGA stub constant framing) |
| UART RX flags `{mig,pe,lm_path,exam_mode,pe_nib}` | TELEMETRY-READ |
| Harness `score_new` | CONTROL only — not used |
| Pytest constructed tel | CONTROL only — not used |

## CONTROL (retained)

| Artifact | Role |
|----------|------|
| `GATE_teacher_off.md` | harness CONTROL |
| `tests/native_graph/test_teacher_off_exam.py` | shape gate CONTROL |
| Proxy own_cut `D2FC41A7…` | NOT programmed |
| Frozen LM-06 / 01R / 02M / A0.3 | HS-20 MATCH — `frozen_sha_control.txt` |

## Frozen / SoC SHA

| Bit | SHA256 | Status |
|-----|--------|--------|
| SoC integrate (programmed) | `D65F3524BE1BD53D6B461CD8CD872DDCF8DE04EC4B7B0C8FB4CA4F959559A4DF` | MATCH |
| Proxy own_cut | `D2FC41A7869E7C4FF9B2E852C0E6E3A328E8C87EE518ACC03091BD29A3D23CA3` | MATCH; not HS-02 vehicle |
| LM-06 / 01R / 02M / A0.3 | see `frozen_sha_control.txt` | MATCH; not overwritten |

## Parameter accounting (separate — never summed with episodes)

```text
P_LM = 802816
P_encoder = 9216
P_total_trainable = (report LM + encoder separately; do not headline a single sum with memory)
N_episodes = not measured on silicon this gate
episode_storage = n/a (no board episode dump)
index_storage = n/a
```

Episodes / graph nodes are **not** parameters. This archive does not add them into `P_*`.  
SoC under test has **LM-06 weight fabric ABSENT** — `P_LM` is the frozen LM-06 accounting reference, not active on this bit.

## Falsifiers checked

| Falsifier | Status |
|-----------|--------|
| Teacher bits / answers in exam path | **Did not fire** — mode-only TX; no answer RX path |
| Inventing LM-06 answers on host | **Did not fire** |
| Programming proxy as HS-02 | **Did not fire** |
| Frozen overwrite | **Not found** — MATCH |
| BOARD_PASS self-declare | **Not declared** |

## Verdict lines

```text
HLB: CLEAN
teacher_off_exam (silicon SoC+UART stub) = PASS_NARROW
Evidence_class = BOARD_UART_STUB + SOC_SHA (not full semantic HS-02 / not BOARD_PASS)
LIMIT = LM-06 weight fabric ABSENT; lm_path=0; no retrieval answers
NATIVE_V1_MINI_AI_BOARD_PASS = NOT EVIDENCED
allow_loop_done_eng = true (narrow framing only; §14 retrieval/HS-22 remain OPEN)
```

## NEXT

Keep harness CONTROL. Do **not** promote to Native V1 BOARD_PASS. For full HS-02 semantic exam: add LM-06 weight path (or honest non-LM claim scope) + held-out query protocol with FPGA-emitted answers/telemetry counters — then re-dispatch. Until then §14 LM + blind retrieval boxes stay OPEN/LIMIT.
