# AUDIT — hs02_lm_path (VERIFY_ONLY evidence auditor)

**Auditor:** `a7-evidence-auditor`  
**Mode:** VERIFY_ONLY (no RTL edit; **no LOOP_STATE flip**)  
**Date:** 2026-08-22  
**Evidence_class:** **BOARD_UART_LM_PATH_PROBE** — **not** semantic HS-02, **not** HS-22, **not** BOARD_PASS  
**GATE:** `hs02_lm_path`  
**LOOP_STATE:** `next` / first OPEN = `hs02_lm_path`  
**Implementer:** `a7-vivado-gate` / repair `PASS_NARROW` / SoC SHA `4451AFD9…F40E`  
**HLB re-probe:** `a7-hlb-auditor` / `PASS_NARROW` / HLB CLEAN / RX `91B9` / `lm_path=1`  
**Prior FAIL CONTROL:** HLB FAIL on `D2C6CF4B…A92C` (`lm_path=0` through t+210s)  
**Refuse rule:** FAIL if BOARD_PASS self-declared, host invents `lm_path=1`, frozen LM/01R/02M/A0.3 overwrite, TinyGPT sold present, or sticky UART bit sold as full HS-02/HS-22 answer path.

```text
MUST_READ_UNBLOCK_H5: read. Next = ungated DIFF twin (not S2, not glue).
BLUEPRINT_LOOP: read. Goal=NATIVE_V1_MINI_AI_BOARD_PASS. Next=hs02_lm_path
```

---

## Verdict

```text
AUDIT: 1 FINDING
result: PASS_NARROW
allow_loop_done_eng: true
severity_metrics: repair SoC 4451AFD9 MATCH live; CONTROL D2C6CF4B archived MATCH; attempt1 09304F9D lm_path=0 retained; vivado+HLB MODE-only UART 91B9 → status=0x91 exam=1 lm_path=1 mig=1 pe=0; WNS=+0.244 TNS=0 BRAM=128 DSP=0; TinyGPT ABSENT LIMIT; frozen LM/01R/02M/A0.3 MATCH; HLB CLEAN re-probe; no BOARD_PASS; Evidence_class=BOARD_UART_LM_PATH_PROBE
```

H_CANDIDATE (new bit ≠ D2C6; COM12 reports `lm_path≠0` after MODE-only `E0`/`S`; HLB CLEAN; TinyGPT ABSENT LIMIT) **SUPPORTED (NARROW)** — **EVIDENCE**.  
H_RIVAL (hardwire `lm_path=1`; host invents UART bit5; overwrite frozen) **did not fire**.  
Full HS-02 held-out retrieval / HS-22 TinyGPT-in-path / §14 Native V1 **NOT closed** (finding).  
`NATIVE_V1_MINI_AI_BOARD_PASS` = **NOT EVIDENCED**.

**Do not declare BOARD_PASS.** **Do not flip LOOP_STATE** (orchestrator only).  
Orchestrator **may** mark `DONE_ENG` for this **narrow** board-visible `lm_path≠0` unknown only (`allow_loop_done_eng: true`).

---

## Dispatch / loop law

| Check | Outcome |
|-------|---------|
| `LOOP_STATE.next` / first OPEN = `hs02_lm_path` | **PASS** |
| Implementer = `a7-vivado-gate` (FALLBACK) repair PASS_NARROW | **PASS** — DISPATCH_LOG |
| Parallel VERIFY = `a7-ng-xsim-verify` + `a7-vivado-gate` VERIFY_ONLY | **PASS** — XSim ABSENT labeled; post-route re-derive |
| HLB re-probe after repair = `a7-hlb-auditor` PASS_NARROW / CLEAN | **PASS** — independent re-program + `91B9` |
| Auditor this VERIFY = `a7-evidence-auditor` | **PASS** |
| Evidence_class mixed as full HS-02 / BOARD_PASS | **PASS** — `BOARD_UART_LM_PATH_PROBE` + TinyGPT LIMIT; `board_pass: false` |
| Auditor VERIFY_ONLY (no LOOP flip) | **PASS** — this file |

---

## Independent re-derive (headline numbers)

| Metric | Claim | Auditor re-derive | Class |
|--------|------:|-------------------|-------|
| Repair SoC SHA | 4451AFD9…F40E | live SHA256 of `LM06-UA/arty_a7_ng_lm06_ua_soc.bit` (3826006 B) **MATCH**; HS02 repair copy **MATCH** | **EVIDENCE** |
| Prior FAIL CONTROL | D2C6CF4B…A92C | live SHA256 of `HS02-LMPATH/CONTROL_prior_D2C6CF4B_*.bit` **MATCH**; ≠ repair | **EVIDENCE** |
| Attempt1 smoke-only | 09304F9D… `lm_path=0` | archived attempt1 bit SHA **MATCH**; falsifies smoke_done-alone | **EVIDENCE** |
| Frozen LM-06 / 01R / 02M / A0.3 | MATCH | live rehash vs EXPECT — all **MATCH** | **EVIDENCE** |
| WNS / TNS | +0.244 / 0.0 | `lm06_ua_timing_repair.rpt` Design Timing Summary WNS=0.244 TNS=0.000 | **EVIDENCE** |
| WHS / THS | +0.032 / 0.0 | same summary | **EVIDENCE** |
| BRAM / DSP | 128 / 0 | util repair Block RAM Tile=128; DSPs=0 | **EVIDENCE** |
| UART RX (repair + HLB re-probe) | `91B9` | `board_probe_repair.json` + `board_probe_hlb_reprobe.json` | **EVIDENCE** |
| `lm_path` | 1 | RTL pack bit5; `0xB9`→1; also pre-enter `0xA9` lm=1 | **EVIDENCE** |
| `exam_mode` | 1 after `0xE0` | flags bit4 on `0xB9` | **EVIDENCE** |
| Host TX | MODE only `E0`/`53` | both probes; no cue/addr/winner/grad/answer | **EVIDENCE** |
| Host-graded answers | false | both probes | **EVIDENCE** |
| HLB | CLEAN | `AUDIT_hs02_lm_path_hlb.md` re-probe | **EVIDENCE** |
| TinyGPT / DSP | ABSENT LIMIT | DSP=0; LIMIT file; pe_alive=0 | **EVIDENCE** (LIMIT) |
| BOARD_PASS | false | GATE / HLB / probes | **EVIDENCE** |

### UART flags packing (auditor)

```text
// rtl/native_graph/integrate/a7ng_exam_uart_stub.sv
tx_data <= {mig_calib_i, pe_alive_i, lm_path_i, exam_mode, pe_nibble_i};
→ bit7=mig, bit6=pe_alive, bit5=lm_path, bit4=exam_mode, bit3:0=pe_nibble
0xB9 → mig=1 pe=0 lm=1 exam=1 nib=9
0xA9 → mig=1 pe=0 lm=1 exam=0 nib=9
0x99 → mig=1 pe=0 lm=0 exam=1 nib=9   // prior FAIL D2C6
```

### lm_path sticky (auditor read of repair RTL)

```text
// arty_a7_ng_lm06_ua_soc_top.sv
// req_lm after calib (not smoke_pass); fixed-addr wt∧act WR→RD sticky
// if (wt_seen && act_seen) lm_path_sticky <= 1
// assign lm_path_active ≡ lm_path_sticky
// NOT: assign lm_path = 1'b1
```

Attempt1 (`09304F9D…`) kept `lm_path=0` after smoke_done-only — H_RIVAL “always-1 / smoke alone” **falsified** before repair FSM landed.  
Prior D2C6 FAIL (`lm_path=0`) with same MODE probe — host script does not force bit5.

---

## Declared scientific frame (graded)

| Slot | Declared | Auditor grade |
|------|----------|---------------|
| OBSERVATION | HLB FAIL D2C6 `lm_path=0`; sticky gated on smoke | **EVIDENCE** |
| UNKNOWN | board-visible `lm_path≠0` without smoke dependency / host-invented bit | **Closed PASS_NARROW + TinyGPT LIMIT** — **EVIDENCE** |
| H_CANDIDATE | new bit; COM12 `lm_path` bit set; MODE-only; HLB CLEAN | **SUPPORTED (NARROW)** — **EVIDENCE** |
| H_RIVAL | hardwire lm_path; host invents bit | **Did not fire** |
| FALSIFIER | frozen overwrite; BOARD_PASS; TinyGPT claimed present | **Did not fire** |
| CONTROL | D2C6 prior FAIL + frozen LM MATCH | **EVIDENCE** |
| METRICS | UART bit5 / WNS / BRAM / DSP=0 | visibility **EVIDENCE**; semantic HS-02/22 **LIMIT/OPEN** |

---

## Findings

```
[MAJOR] PASS_NARROW board lm_path≠0 must not close HS-02 / HS-22 / §14 answer-path
  where     : HS02-LMPATH/GATE_hs02_lm_path_repair.md;
              HS02-LMPATH/LIMIT_tinygpt_absent.md;
              HS02-LMPATH/AUDIT_hs02_lm_path_hlb.md;
              docs/NATIVE_AI_ARTY_A7_BLUEPRINT/04_HARDSTOPS.md HS-02/HS-22;
              rtl/board/arty_a7_ng_lm06_ua_soc_top.sv lm_path sticky FSM
  claim      : repair+HLB PASS_NARROW — board-visible lm_path≠0 (UART 91B9)
  evidence   : lm_path bit is wt∧act BRAM sticky self-test → UART bit5; pe_alive=0;
               DSP=0 TinyGPT ABSENT; no held-out query→answer; no retrieval transcript;
               GATE/HLB correctly scope LIMIT — full HS-02/22 still OPEN.
  why it matters: A reader could treat DONE_ENG as Native V1 LM-in-path / §14 HS-02 closed.
  fix        : Keep PASS_NARROW + BOARD_UART_LM_PATH_PROBE + TinyGPT ABSENT LIMIT;
               allow DONE_ENG for visibility unknown only; leave semantic HS-02/HS-22 OPEN.
```

---

## Allowed narrow closure (why allow_loop_done_eng=true)

UNKNOWN (narrow): after programming a **new** UA SoC bit ≠ `D2C6CF4B…`, does UART report **`lm_path≠0`** under MODE-only enter/status, without host-invented bit5, without frozen overwrite, with TinyGPT ABSENT honestly LIMITed?

That unknown is **met** on file-backed board probes (`91B9`) from both vivado repair and independent HLB re-program + live SHA `4451AFD9…` + CONTROL archive + attempt1 negative control.

`allow_loop_done_eng: true` = engineering close of **board-visible lm_path sticky** only — **not** Native V1, **not** semantic HS-02, **not** HS-22 TinyGPT participation.

---

## Explicit non-claims (auditor confirms)

- Not `NATIVE_V1_MINI_AI_BOARD_PASS` / not AI-declared BOARD_PASS  
- Not semantic HS-02 held-out wording retrieval on silicon  
- Not HS-22 TinyGPT/DSP in the FPGA answer path (`DSP=0`, `pe_alive=0`)  
- Not “LM-06 frozen law bitstream active end-to-end” — sticky is wt∧act self-test visibility  
- Not encoder ungated-DIFF / H5 progress (encoder lane PARKED; no glue)

---

## NOT VERIFIED

- Live re-program + COM12 re-probe this auditor session (artifacts + live SHA re-derived; board not re-touched by evidence auditor)  
- Functional TinyGPT / frozen-law forward vs sticky PAT write/read  
- XSim of repair sticky FSM (ABSENT; correctly not claimed by xsim VERIFY)

---

## Auditor close

```text
hs02_lm_path = PASS_NARROW
allow_loop_done_eng = true
Evidence_class = BOARD_UART_LM_PATH_PROBE
LIMIT = TinyGPT/DSP ABSENT (full HS-22 OPEN); pe_alive=0
NATIVE_V1_MINI_AI_BOARD_PASS = NOT EVIDENCED
BOARD_PASS = false
loop_flipped = false
```
