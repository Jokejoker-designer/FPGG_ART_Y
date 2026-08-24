# AUDIT — hs02_lm_path (HLB VERIFY/REPROBE after vivado repair)

**Gate:** `hs02_lm_path`  
**Agent:** `a7-hlb-auditor`  
**Mode:** VERIFY/REPROBE (independent of repair agent probe)  
**Board:** Digilent Arty A7-100T `xc7a100t` — serial **210319BE776EA** — UART **COM12**  
**Programmed bit:** `results/A7-NATIVE-GRAPH/LM06-UA/arty_a7_ng_lm06_ua_soc.bit`  
**SoC SHA256:** `4451AFD9B07D8FF52791CCBF6338862FF36B721DF9FBB9BD19EC726BEA67F40E` (**MATCH**; live rehash + post-program)  
**CONTROL prior FAIL:** `D2C6CF4B28706B24CE513E2B7A09A4018EB9BB01EBB864FA3A5375B11DB9A92C` — archived; **not** programmed this run  
**Proxy / stub-only bits:** **not programmed**  
**Result:** **PASS_NARROW**  
**BOARD_PASS:** **not declared**  
**Evidence_class:** `BOARD_UART_LM_PATH_PROBE`  

```text
BLUEPRINT_LOOP: read. Goal=NATIVE_V1_MINI_AI_BOARD_PASS. Next=hs02_lm_path (this gate)
MUST_READ_UNBLOCK_H5: read (encoder lane parked; not this gate).
```

## Scientific frame

| Slot | Value |
|------|-------|
| OBSERVATION | prior HLB FAIL on D2C6: UART `9199`/`lm_path=0` t+210s; repair claims 4451AFD9 UART `91B9`/`lm_path=1` |
| UNKNOWN | after independent re-program of 4451AFD9 on COM12, does MODE-only UART report `lm_path≠0` without host-invented bit? |
| H_CANDIDATE | board transcript with `lm_path` bit set; HLB CLEAN; SHA MATCH |
| H_RIVAL | host forges `lm_path=1`; wrong bit programmed; hardwired UART flag without sticky |
| FALSIFIER | frozen overwrite; BOARD_PASS; TinyGPT/HS-22 sold from sticky alone |
| CONTROL | D2C6 FAIL archive; frozen LM/01R/02M/A0.3 MATCH |
| Verdict on UNKNOWN | **CLOSED — PASS_NARROW** — independent HLB re-probe RX `91B9`; `exam_mode=1`; **`lm_path=1`**; HLB CLEAN |

## HLB: CLEAN

Single question: if this host probe code were deleted, would the claim still be true?

**Yes for board-visible `lm_path≠0`:** UART bytes `91 B9` were read from COM12 after programming repair SoC `4451AFD9…`. Host sent only `0xE0` / `0x53` mode bytes. No cue/addr/winner/grad/answer payload. No host-scored “FPGA answer.” Flag decode is TELEMETRY-READ of FPGA-sourced byte (bit5=1).

**Yes that host did not invent the bit:** prior FAIL on D2C6 reported `lm_path=0` with the same probe script — script does not force PASS.

```
[CONTROL-ONLY — not credited] Host ranks facts in train_v2_harness score_new
  file: python/native_graph/train_v2_harness.py
  retained as HARNESS CONTROL; not used as silicon evidence this run

[CONTROL-ONLY — not credited] Pytest hardwires teacher_off telemetry dict
  file: tests/native_graph/test_teacher_off_exam.py
  retained as shape CONTROL; silicon flags taken from UART 0x91/0xB9, not pytest
```

No CRITICAL/MAJOR HLB violations on the SoC UART path used for this archive.

## Anti-hardcode (FPGA side — observation only)

RTL `arty_a7_ng_lm06_ua_soc_top.sv`: `lm_path_sticky` latches only after fixed-addr wt∧act write→readback match under `grant_lm`; `assign lm_path_active = lm_path_sticky | …` — **not** `assign lm_path=1`. HLB does not credit semantic TinyGPT from this sticky.

## Board run (FACT — this re-probe)

| Check | Result |
|-------|--------|
| JTAG Digilent serial | `210319BE776EA` |
| Program repair SoC bit | **DONE** (HLB re-program; Vivado `A7NG_HLB_REPROBE_PROGRAM_PASS`) |
| SoC SHA live | **MATCH** `4451AFD9…A67F40E` |
| UART COM12 @115200 | **DONE** |
| TX | `E0` (enter exam), `53` (status) — MODE only |
| RX (primary) | `91 B9` |
| Decode | status=`0x91`; `exam_mode=1`; `mig_calib=1`; **`lm_path=1`**; `pe_alive=0`; `pe_nibble=9` |
| Settle | `lm_path=1` by t0 status-only (`91A9`); after enter `91B9` at t+5s / t+15s |
| Retrieval answers | **none** |
| Host-graded answers | **false** |
| TinyGPT / DSP core | **ABSENT LIMIT** (post-route DSP=0; pe_alive=0) |

Artifacts: `board_probe_hlb_reprobe.json`, `uart_blind_exam_transcript_hlb_reprobe.json`, `LIMIT_tinygpt_absent.md`, `frozen_sha_control_repair.txt`, `GATE_hs02_lm_path_repair.md`.

Prior FAIL (CONTROL): `board_probe.json` / `AUDIT` historical — D2C6 `lm_path=0`.

## HS-02 / HS-22 checklist (this gate)

| Flag | Silicon evidence |
|------|------------------|
| teacher=0 | **EVIDENCE (framing)** — status `0x91` |
| external_LLM=0 | **EVIDENCE (framing)** |
| learn=0 | **EVIDENCE (framing)** |
| freeze=1 / exam_mode | **EVIDENCE** — `exam_mode=1` after `0xE0` |
| `lm_path!=0` (gate UNKNOWN) | **PASS** — UART bit5 = 1 (`0xB9`) |
| held-out wording retrieval | **LIMIT / NOT CLAIMED** |
| HS-22 LM in output path (TinyGPT) | **LIMIT / OPEN** — TinyGPT ABSENT |

## Host→board payload surface (this run)

| Field | Classification |
|-------|----------------|
| `0xE0` CMD_ENTER | MODE_FLAG |
| `0x53` CMD_STATUS | MODE_FLAG |
| tokens / cue / hash / winner / addr / way / grad / ΔW / answer | **ABSENT** (not sent) |
| UART RX status `0x91` | TELEMETRY-READ |
| UART RX flags `0xB9` `{mig,pe,lm_path,exam,pe_nib}` | TELEMETRY-READ (`lm_path=1` FACT) |
| Harness `score_new` | CONTROL only — not used |
| Pytest constructed tel | CONTROL only — not used |

## Frozen / SoC SHA

| Bit | SHA256 | Status |
|-----|--------|--------|
| Repair UA SoC (programmed) | `4451AFD9B07D8FF52791CCBF6338862FF36B721DF9FBB9BD19EC726BEA67F40E` | MATCH |
| CONTROL prior FAIL D2C6 | `D2C6CF4B28706B24CE513E2B7A09A4018EB9BB01EBB864FA3A5375B11DB9A92C` | archived; not vehicle |
| LM-06 / 01R / 02M / A0.3 | `frozen_sha_control_repair.txt` | MATCH; not overwritten |

## Parameter accounting (separate — never summed with episodes)

```text
P_LM = 802816
P_encoder = 9216
P_total_trainable = (report LM + encoder separately; do not headline a single sum with memory)
N_episodes = not measured on silicon this gate
episode_storage = n/a
index_storage = n/a
```

Episodes / graph nodes are **not** parameters. TinyGPT ABSENT on this SoC — do **not** claim full `P_LM` active in the FPGA answer path. Do **not** add episodes into `P_*`.

## Falsifiers checked

| Falsifier | Status |
|-----------|--------|
| Invent `lm_path=1` on host | **Did not fire** — same MODE-only script; RX from board |
| Program wrong / prior FAIL / proxy bit | **Did not fire** — SHA `4451AFD9` MATCH; Digilent `210319BE776EA` |
| Host-graded answers as FPGA | **Did not fire** |
| Hardwire `assign lm_path=1` | **Not found** — sticky after wt∧act readback |
| Frozen overwrite | **Not found** — MATCH |
| BOARD_PASS / semantic HS-22 without TinyGPT | **Not declared** |

## Verdict lines

```text
HLB: CLEAN
hs02_lm_path = PASS_NARROW
Evidence_class = BOARD_UART_LM_PATH_PROBE
LIMIT = TinyGPT ABSENT (full HS-22 OPEN); pe_alive=0
NATIVE_V1_MINI_AI_BOARD_PASS = NOT EVIDENCED
allow_loop_done_eng = true
board_pass = false
```

## NEXT

Orchestrator may mark `hs02_lm_path` DONE_ENG (narrow board-visible `lm_path≠0` only) and advance LOOP_STATE. Do **not** claim HS-22 / retrieval / BOARD_PASS until TinyGPT/DSP participation or an honest non-TinyGPT claim scope is frozen.
