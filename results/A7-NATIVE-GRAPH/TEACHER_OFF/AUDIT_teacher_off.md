# AUDIT — teacher_off_exam (VERIFY_ONLY evidence auditor)

**Auditor:** `a7-evidence-auditor`  
**Mode:** VERIFY_ONLY (no RTL edit; **no LOOP_STATE flip**)  
**Date:** 2026-08-22  
**Evidence_class:** **BOARD_UART_STUB** (SoC programmed + UART framing) — **not** semantic HS-02, **not** BOARD_PASS  
**GATE:** `teacher_off_exam`  
**LOOP_STATE:** `next` / first OPEN = `teacher_off_exam`  
**Implementer DISPATCH:** `a7-hlb-auditor` / `PASS_NARROW` / SoC SHA `D65F3524…A4DF`  
**Refuse rule:** FAIL if BOARD_PASS self-declared, proxy sold as HS-02 vehicle, harness pytest sold as silicon, LM-06 ABSENT invent-filled, frozen SHA drift, or stub `0x91` sold as full HS-02 held-out proof.

```text
MUST_READ_UNBLOCK_H5: read. Next = ungated DIFF twin (not S2, not glue).
BLUEPRINT_LOOP: read. Goal=NATIVE_V1_MINI_AI_BOARD_PASS. Next=teacher_off_exam
```

---

## Verdict

```text
AUDIT: 2 FINDINGS
result: PASS_NARROW
allow_loop_done_eng: true
severity_metrics: SoC D65F3524 programmed MATCH; UART COM12 RX status 0x91 + exam_mode=1 + lm_path=0; proxy NOT programmed; HLB CLEAN mode-only; LM-06 ABSENT LIMIT; harness CONTROL retained; frozen LM/01R/02M/A0.3 MATCH; no BOARD_PASS; Evidence_class=BOARD_UART_STUB
```

H_CANDIDATE (SoC D65F3524 + UART stub blind framing archive with HLB clean, or honest LIMIT) **SUPPORTED (NARROW)** — **EVIDENCE**.  
H_RIVAL (host-graded harness as silicon; invent LM-06 answers; program proxy D2FC41A7) **did not fire**.  
Full HS-02 (held-out wording + live teacher/learn/LLM/freeze wires + retrieval) **NOT closed** (finding).  
`NATIVE_V1_MINI_AI_BOARD_PASS` = **NOT EVIDENCED**.

**Do not declare BOARD_PASS.** **Do not flip LOOP_STATE** (orchestrator only).  
Orchestrator **may** mark `DONE_ENG` for this **narrow** UART-stub framing unknown only (`allow_loop_done_eng: true`).

---

## Dispatch / loop law

| Check | Outcome |
|-------|---------|
| `LOOP_STATE.next` / first OPEN = `teacher_off_exam` | **PASS** |
| Implementer agent = `a7-hlb-auditor` (`pipeline.json` `character_id`) | **PASS** — DISPATCH_LOG last teacher_off line |
| Auditor agent this VERIFY = `a7-evidence-auditor` | **PASS** |
| Evidence_class mixed as full HS-02 / BOARD | **PASS** — HLB + GATE label `PASS_NARROW` / `BOARD_UART_STUB`; BOARD_PASS false |
| Prior FAIL held then SoC reopen | **PASS** — DISPATCH FAIL→integrate_fit SoC→HLB PASS_NARROW |
| Auditor VERIFY_ONLY (no LOOP flip) | **PASS** — this file |

---

## Independent re-derive (headline numbers)

| Metric | Claim | Auditor re-derive | Class |
|--------|------:|-------------------|-------|
| SoC bit SHA | D65F3524…A4DF | live SHA256 of `arty_a7_ng_integrate_fit_soc.bit` (3826008 B) **MATCH** | **EVIDENCE** |
| Proxy CONTROL SHA | D2FC41A7…D23CA3 | live SHA256 of `arty_a7_ng_integrate_fit_own_cut.bit` (3826000 B) **MATCH**; ≠ SoC; **not programmed** per probe | **EVIDENCE** |
| HLB AUDIT SHA | 4B020663…225F2D | live SHA256 of `AUDIT_teacher_off_hlb.md` **MATCH** `sha256_audit.txt` | **EVIDENCE** |
| Frozen LM-06 / 01R / 02M / A0.3 | MATCH | live rehash vs `frozen_sha_control.txt` EXPECT — all **MATCH** | **EVIDENCE** |
| UART status byte | `0x91` | transcript + board_probe; RTL `STATUS_HS02 = 8'h91` localparam | **EVIDENCE** (stub constant framing) |
| `exam_mode` | 1 after `0xE0` | flags byte bit4 under RTL pack `{mig,pe,lm,exam,pe_nib}`; `0x99`/`0xD9` both exam=1 | **EVIDENCE** |
| `lm_path` | 0 | same pack bit5=0 on `0x99` and `0xD9` | **EVIDENCE** (LIMIT consistent) |
| `mig_calib` | 1 | flags MSB=1 on both | **EVIDENCE** |
| Retrieval / host-graded answers | none / false | transcript `retrieval_answers=null`, `host_graded_answers=false`; TX mode-only `E0`/`53` | **EVIDENCE** |
| LM-06 weight fabric | ABSENT | integrate LIMIT + `lm_path=0` + BRAM0 SoC prior | **EVIDENCE** (LIMIT) |
| teacher/LLM/learn/freeze live wires | “teacher=0…” via `0x91` | **not** sampled I/O — constant emit | **ENGINEERING_INFERENCE** scoped as framing only |
| Pytest harness tel dict | CONTROL | `test_teacher_off_exam.py` hardwires shape; not used as silicon RX | **CONTROL** (not credited) |

### RTL flags packing (auditor)

```text
tx_data <= {mig_calib_i, pe_alive_i, lm_path_i, exam_mode, pe_nibble_i};
→ bit7=mig, bit6=pe_alive, bit5=lm_path, bit4=exam_mode, bit3:0=pe_nibble
0xD9 → mig=1 pe=1 lm=0 exam=1 nib=9
0x99 → mig=1 pe=0 lm=0 exam=1 nib=9
```

---

## Declared scientific frame (graded)

| Slot | Declared (HLB) | Auditor grade |
|------|----------------|---------------|
| OBSERVATION | SoC + UART stub; prior FAIL missing path | **EVIDENCE** (DISPATCH + artifacts) |
| UNKNOWN | board archive vs LIMIT (LM-06 ABSENT) | **Closed PASS_NARROW + LIMIT** — **EVIDENCE** |
| H_CANDIDATE | SHA + UART transcript + HLB clean | **SUPPORTED (NARROW)** — **EVIDENCE** |
| H_RIVAL | harness grade; invent LM answers; program proxy | **Did not fire** |
| FALSIFIER | teacher in path; frozen overwrite; BOARD_PASS | **Did not fire** for path/frozen/BOARD (teacher = stub constant) |
| CONTROL | harness GATE + proxy not programmed | **EVIDENCE** |
| METRICS | framing flags / LIMIT | numeric framing **EVIDENCE**; semantic HS-02 **LIMIT/OPEN** |

---

## Findings

```
[MAJOR] PASS_NARROW UART stub framing must not close full HS-02 / §14 blind retrieval
  where     : TEACHER_OFF/AUDIT_teacher_off_hlb.md HS-02 checklist;
              docs/NATIVE_AI_ARTY_A7_BLUEPRINT/04_HARDSTOPS.md HS-02;
              rtl/native_graph/integrate/a7ng_exam_uart_stub.sv:24 (STATUS_HS02 localparam)
  claim      : silicon teacher-off exam PASS_NARROW with teacher=0 LLM=0 learn=0 freeze=1 framing
  evidence   : 0x91 is compile-time constant (no teacher/learn/LLM inputs on stub);
               no query→answer path; LM-06 weights ABSENT; held-out wording NOT run on UART;
               HLB correctly scopes mode-only + LIMIT — full HS-02 still requires held-out queries.
  why it matters: A reader could treat DONE_ENG as Native V1 teacher-off / §14 blind exam closed.
  fix        : Keep PASS_NARROW + BOARD_UART_STUB + LIMIT; allow DONE_ENG for framing unknown only;
               leave semantic HS-02 / HS-22 / §14 retrieval OPEN until weight path + held-out protocol.
```

```
[MINOR] Primary RX 91D9 vs transcript-only 9199 archival mismatch
  where     : TEACHER_OFF/board_probe.json rx_hex_primary=91D9;
              TEACHER_OFF/uart_blind_exam_transcript.json (both probes 9199);
              GATE_teacher_off_silicon.md cites 91D9/9199
  claim      : primary then re-probe archive of both frames
  evidence   : board_probe records 91D9 then 9199; canonical transcript file only stores 9199×2;
               under RTL pack both keep status 0x91, exam_mode=1, lm_path=0 (pe_alive 1→0 only).
  why it matters: Weakens reproducibility of the primary frame without breaking framing PASS_NARROW.
  fix        : Append the 91D9 capture into uart_blind_exam_transcript.json or drop 91D9 from probe summary.
```

---

## Allowed narrow closure (why allow_loop_done_eng=true)

Gate UNKNOWN (post–SoC reopen): program SoC `D65F3524` (not proxy) on Arty + UART stub blind framing archive with HLB clean, **or** honest FAIL/LIMIT if LM-06 ABSENT blocks semantic claim.

That unknown is **met** on file-backed BOARD_UART_STUB with honest PASS_NARROW + LM-06 ABSENT LIMIT (mode-only TX; no host answers; frozen MATCH; no BOARD_PASS).

**Not** allowed to tick: full HS-02 held-out proof, HS-22 LM-in-output-path, Native V1 BOARD_PASS, or harness pytest as silicon.

---

## Forbidden-route scan

| Route | Result |
|-------|--------|
| Golden/expected edited to match DUT | **Not found** (stub emits fixed 0x91 by design; LIMIT documented) |
| Failing test deleted/weakened | **Not found** (prior HLB FAIL retained in DISPATCH; harness CONTROL kept) |
| Seeds post-selected / hard cases dropped | **N/A** (no semantic seed set this run) |
| TRAIN→EVAL leak / host answer path | **Did not fire** — mode bytes only; `host_graded_answers=false` |
| Host gradient/winner/addr/cue/answer | **ABSENT** on TX surface |
| Hardcoded semantic answers in bit | **Stub status constant only** — labeled framing; not sold as retrieval |
| Frozen bit overwrite | **MATCH** live rehash |
| BOARD_PASS self-declare | **false** on all TEACHER_OFF artifacts |
| Proxy programmed as HS-02 | **false** |
| Metric collapse sold as PASS | **N/A** (no M_L1/rank claim) |

---

## NOT VERIFIED

- Live JTAG/UART re-run this auditor session (artifacts + SHA re-derive only; board not re-probed).
- Whether `pe_alive` 1→0 between probes is sticky fabric state vs sample timing (out of framing scope).
- Semantic held-out / contradiction packets on silicon (explicitly LIMIT / not claimed).
- Weight-write counters in EVAL (stub does not expose).
- XSim marker for UART stub (not required for this Evidence_class).
