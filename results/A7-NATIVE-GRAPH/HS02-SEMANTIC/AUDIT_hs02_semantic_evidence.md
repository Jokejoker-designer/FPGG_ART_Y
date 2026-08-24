# AUDIT — hs02_semantic (VERIFY_ONLY evidence auditor)

**Auditor:** `a7-evidence-auditor`  
**Mode:** VERIFY_ONLY (no RTL edit; **no LOOP_STATE flip**)  
**Date:** 2026-08-22  
**Evidence_class:** **BOARD_UART_SEMANTIC_LIMIT** — **not** full HS-02, **not** HS-22, **not** BOARD_PASS  
**GATE:** `hs02_semantic`  
**LOOP_STATE:** `next` / first OPEN = `hs02_semantic`  
**Implementer:** `a7-hlb-auditor` / `PASS_NARROW` / HLB CLEAN / RX `91B9` / `lm_path=1`  
**Parallel VERIFY:** `a7-ng-xsim-verify` (XSim ABSENT labeled) + `a7-vivado-gate` (SoC SHA + DSP=0 + frozen MATCH)  
**CONTROL UART:** HS02-LMPATH SoC `4451AFD9…F40E` / RX `91B9` / `lm_path=1` (reconfirmed this gate)  
**Refuse rule:** FAIL if BOARD_PASS self-declared, TinyGPT sold present, host invents held-out answers, UART stub sold as full live semantic HS-02, frozen overwrite, or §14 Teacher-off ticked PASS from framing alone.

```text
MUST_READ_UNBLOCK_H5: read. Next = ungated DIFF twin (not S2, not glue).
BLUEPRINT_LOOP: read. Goal=NATIVE_V1_MINI_AI_BOARD_PASS. Next=hs02_semantic
```

---

## Verdict

```text
AUDIT: 2 FINDINGS
result: PASS_NARROW
allow_loop_done_eng: true
severity_metrics: SoC 4451AFD9 MATCH live; UART COM12 RX 91B9 → status=0x91 exam=1 lm_path=1 mig=1 pe=0; MODE-only E0/S; TinyGPT ABSENT LIMIT (DSP=0 pe_alive=0; no query CMD); HLB CLEAN; frozen LM/01R/02M/A0.3 MATCH; host_graded_answers=false; XSim ABSENT labeled; no BOARD_PASS; Evidence_class=BOARD_UART_SEMANTIC_LIMIT
```

H_CANDIDATE (honest LIMIT because TinyGPT + UART query/answer path ABSENT, with CONTROL `91B9`/`lm_path=1` and HLB CLEAN) **SUPPORTED (NARROW)** — **EVIDENCE**.  
H_RIVAL (sell `91B9` as full HS-02; invent TinyGPT answers; host-grade FPGA answers) **did not fire**.  
Full HS-02 held-out wording retrieval / live teacher=0·LLM=0·learn=0·freeze=1 semantic / HS-22 TinyGPT-in-path / §14 Native V1 **NOT closed** (finding).  
`NATIVE_V1_MINI_AI_BOARD_PASS` = **NOT EVIDENCED**.

**Do not declare BOARD_PASS.** **Do not flip LOOP_STATE** (orchestrator only).  
Orchestrator **may** mark `DONE_ENG` for this **narrow** honest-LIMIT unknown only (`allow_loop_done_eng: true`).

---

## Dispatch / loop law

| Check | Outcome |
|-------|---------|
| `LOOP_STATE.next` / first OPEN = `hs02_semantic` | **PASS** |
| Implementer = `a7-hlb-auditor` PASS_NARROW / HLB CLEAN | **PASS** — DISPATCH_LOG |
| Parallel VERIFY = `a7-ng-xsim-verify` + `a7-vivado-gate` VERIFY_ONLY | **PASS** — XSim ABSENT labeled; post-route re-derive |
| Auditor this VERIFY = `a7-evidence-auditor` | **PASS** |
| Evidence_class mixed as full HS-02 / BOARD_PASS | **PASS** — `BOARD_UART_SEMANTIC_LIMIT` + TinyGPT LIMIT; `board_pass: false` |
| Auditor VERIFY_ONLY (no LOOP flip) | **PASS** — this file |

---

## Independent re-derive (headline numbers)

| Metric | Claim | Auditor re-derive | Class |
|--------|------:|-------------------|-------|
| SoC SHA | 4451AFD9…F40E | live SHA256 of `LM06-UA/arty_a7_ng_lm06_ua_soc.bit` **MATCH** | **EVIDENCE** |
| Frozen LM-06 / 01R / 02M / A0.3 | MATCH | live rehash vs EXPECT — all **MATCH** | **EVIDENCE** |
| HLB audit file SHA | D55FAF27… | SHA256 of `AUDIT_hs02_semantic.md` **MATCH** | **EVIDENCE** |
| UART RX primary | `91B9` | `board_probe_semantic.json` + transcript | **EVIDENCE** (archived board; not re-probed this auditor) |
| Flag decode `0xB9` | lm_path=1 exam=1 pe=0 mig=1 nib=9 | bit pack `{mig,pe,lm,exam,nib}` → **MATCH** | **EVIDENCE** |
| Host TX | MODE only `E0`/`53` | probe + stub RTL CMD_* only | **EVIDENCE** |
| Held-out wording / FPGA answers | ABSENT | `held_out_wording_sent=false`; `fpga_answer_bytes=[]` | **EVIDENCE** (LIMIT) |
| Host-graded answers | false | probe + transcript | **EVIDENCE** |
| TinyGPT / DSP | ABSENT LIMIT | `lm06_ua_util.rpt` DSPs=0; `pe_alive=0`; LIMIT file | **EVIDENCE** (LIMIT) |
| UART query/answer path | ABSENT | `a7ng_exam_uart_stub.sv` CMD_ENTER/STATUS only | **EVIDENCE** (LIMIT) |
| HLB | CLEAN | `AUDIT_hs02_semantic.md` | **EVIDENCE** |
| XSim marker | ABSENT | VERIFY labeled; no invent | **EVIDENCE** |
| BOARD_PASS | false | GATE / HLB / probes | **EVIDENCE** |

### UART flags packing (auditor)

```text
// rtl/native_graph/integrate/a7ng_exam_uart_stub.sv
tx_data <= {mig_calib_i, pe_alive_i, lm_path_i, exam_mode, pe_nibble_i};
→ bit7=mig, bit6=pe_alive, bit5=lm_path, bit4=exam_mode, bit3:0=pe_nibble
0xB9 → mig=1 pe=0 lm=1 exam=1 nib=9
0x91 STATUS_HS02 = stub framing constant (teacher/LLM/learn/freeze encoding) — FRAMING ONLY
```

---

## Scientific frame (auditor)

| Slot | Value | Class |
|------|-------|-------|
| OBSERVATION | CONTROL UART `lm_path=1`/`91B9`; TinyGPT+query path ABSENT; §14 Teacher-off OPEN | **EVIDENCE** |
| UNKNOWN | must we archive honest LIMIT because TinyGPT/answer path ABSENT? | **Closed PASS_NARROW/LIMIT** |
| H_CANDIDATE | LIMIT + HLB CLEAN + CONTROL reconfirm | **SUPPORTED (NARROW)** |
| H_RIVAL | UART probe as full HS-02; invented answers | **Did not fire** |
| FALSIFIER | BOARD_PASS; TinyGPT claimed present; frozen overwrite; invent answers | **Did not fire** |
| CONTROL | HS02-LMPATH bit `4451AFD9…`; harness/pytest CONTROL not credited | **EVIDENCE** |
| UNIT | one board semantic LIMIT attempt (≠ clock cycle) | — |

---

## Findings

```
[MAJOR] PASS_NARROW LIMIT must not close §14 Teacher-off / full HS-02 / HS-22
  where     : HS02-SEMANTIC/GATE_hs02_semantic.md;
              HS02-SEMANTIC/AUDIT_hs02_semantic.md;
              docs/NATIVE_AI_ARTY_A7_BLUEPRINT/14_FINAL_ACCEPTANCE_CHECKLIST.md Teacher-off
  claim      : hs02_semantic PASS_NARROW / allow_loop_done_eng
  evidence   : TinyGPT ABSENT; stub has no query/answer CMD; STATUS_HS02=0x91 is framing;
               held-out wording not sent; §14 Teacher-off boxes remain unchecked OPEN
  why it matters: a reader could treat DONE_ENG as Native V1 teacher-off silicon PASS
  fix        : Keep PASS_NARROW + BOARD_UART_SEMANTIC_LIMIT; leave §14 OPEN until TinyGPT/query path + held-out wording exam without host answers
```

```
[MINOR] board_probe retains lm_path unknown key from prior gate template
  where     : HS02-SEMANTIC/board_probe_semantic.json:unknown_lm_path_ne_0
  claim      : probe JSON for hs02_semantic
  evidence   : top-level key still `unknown_lm_path_ne_0: true` (hs02_lm_path unknown), while this gate UNKNOWN is LIMIT vs held-out retrieval
  why it matters: skimmers may think this run closed lm_path≠0 again rather than semantic LIMIT
  fix        : rename key to gate-local unknown (e.g. `unknown_semantic_limit`) on next probe; do not re-run board solely for rename
```

---

## Forbidden-route search (negative)

| Route | Status |
|-------|--------|
| Invent TinyGPT / host answers | **Did not fire** |
| Host-graded FPGA answers | **Did not fire** (`host_graded_answers=false`) |
| Sell `91B9` as full HS-02 | **Blocked** — LIMIT + §14 OPEN |
| Frozen LM/01R/02M/A0.3 overwrite | **Not found** — MATCH |
| Hardwire TinyGPT present with DSP=0 | **Blocked** |
| Invent XSim marker | **Did not fire** — ABSENT labeled |
| BOARD_PASS self-declare | **Not declared** |
| Parent RTL write for this gate | **Not found** — HLB/board probe + VERIFY only |

---

## PASS_NARROW acceptance (this VERIFY)

| Criterion (user LIMIT) | Met? |
|------------------------|------|
| TinyGPT / answer path ABSENT | **YES** |
| CONTROL UART `91B9` `lm_path=1` | **YES** |
| HLB CLEAN | **YES** |
| Not full HS-02 | **YES** |
| Claimed PASS_NARROW allowed | **YES** (`allow_loop_done_eng: true`) |

---

## Explicit non-claims

- Not full HS-02 live semantic (held-out wording + live teacher/learn/LLM/freeze wires)  
- Not HS-22 TinyGPT/DSP on FPGA answer path  
- Not §14 Teacher-off PASS  
- Not `NATIVE_V1_MINI_AI_BOARD_PASS` / BOARD_PASS  
- Not XSim functional proof for this gate  

---

## NOT VERIFIED

- Live COM12 re-program / re-probe this auditor session (cite HLB `board_probe_semantic.json` + VERIFY/vivado SHA; UART bytes not reinvented)  
- Whether Digilent serial `210319BE776EA` was physically attached at probe time beyond JSON claim  
- Future TinyGPT / query UART once implemented (NEEDS_EXPERIMENT)

---

## Verdict lines

```text
AUDIT: 2 FINDINGS
HLB: CLEAN (cited)
hs02_semantic = PASS_NARROW
Evidence_class = BOARD_UART_SEMANTIC_LIMIT
LIMIT = TinyGPT ABSENT + no UART query/answer path
allow_loop_done_eng = true
board_pass = false
loop_flipped = false
NATIVE_V1_MINI_AI_BOARD_PASS = NOT EVIDENCED
```
