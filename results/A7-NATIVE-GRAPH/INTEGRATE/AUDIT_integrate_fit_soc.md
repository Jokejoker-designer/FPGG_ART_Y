# AUDIT — integrate_fit FULL SoC reopen (VERIFY_ONLY)

**Auditor:** `a7-evidence-auditor`  
**Mode:** READ_ONLY_AUDIT / VERIFY_ONLY (no RTL edit; no LOOP_STATE flip)  
**Date:** 2026-08-22  
**Evidence_class:** **POST_ROUTE_SOC** (not silicon, not BOARD, not HS-02 exam)  
**GATE:** `integrate_fit` (FULL SoC reopen; proxy own_cut retained CONTROL)  
**LOOP_STATE:** `next` / first OPEN = `integrate_fit`  
**Implementer DISPATCH:** `a7-vivado-gate` / `PASS_NARROW` / SoC SHA `D65F3524…A4DF`  
**Refuse rule:** FAIL if BOARD_PASS self-declared, proxy re-sold as SoC, PE=16 without fabric, frozen SHA drift, or LM-06 weight ABSENT sold as HS-22 closed.

```text
MUST_READ_UNBLOCK_H5: read. Next = ungated DIFF twin (not S2, not glue).
BLUEPRINT_LOOP: read. Goal=NATIVE_V1_MINI_AI_BOARD_PASS. Next=integrate_fit
```

---

## Verdict

```text
AUDIT: 2 FINDINGS
result: PASS_NARROW
allow_loop_done_eng: true
severity_metrics: SoC BRAM 0/135 EVIDENCE; WNS=+0.952 TNS=0 EVIDENCE; PE lanes=16 fabric EVIDENCE (u_sc LUT=1046 FF=1856); SoC SHA D65F3524… != proxy CONTROL D2FC41A7…; frozen LM/01R/02M/A0.3 MATCH; LM-06 weight fabric ABSENT LIMIT; UART stub / HS-02 exam DEFERRED; no BOARD_PASS; Evidence_class=POST_ROUTE_SOC
```

H_CANDIDATE (real MIG+PE fabric+LM-arb path stub+UART stub ≠ proxy SHA; BRAM≤135 WNS≥0 TNS=0) **SUPPORTED (NARROW)** — **EVIDENCE** (re-derived).  
H_RIVAL (retick proxy as SoC / program proxy for teacher-off / frozen overwrite) **did not fire**.  
§14 Hardware “Integrated design fits” / LM-06 active response path / HS-02 silicon **NOT closed** (findings).  
WM-00 OOC WNS=−290.499 **still OPEN** (separate class).

**Do not declare BOARD_PASS.** **Do not flip LOOP_STATE** (orchestrator only).  
Orchestrator **may** mark `DONE_ENG` for this **narrow** SoC-fit unknown only (`allow_loop_done_eng: true`).

---

## Dispatch / loop law

| Check | Outcome |
|-------|---------|
| `LOOP_STATE.next` / first OPEN = `integrate_fit` | **PASS** |
| Implementer agent = `a7-vivado-gate` (FALLBACK) | **PASS** — DISPATCH_LOG last implementer line |
| Auditor agent this VERIFY = `a7-evidence-auditor` | **PASS** |
| Evidence_class mixed as board/silicon | **PASS** — labeled `POST_ROUTE_SOC`; blind exam DEFERRED |
| BOARD_PASS language | **PASS** — explicit non-claims; `board_pass: false` |
| Auditor VERIFY_ONLY (no LOOP flip) | **PASS** — this file |

---

## Independent re-derive (headline numbers)

| Metric | Claim | Auditor re-derive | Class |
|--------|------:|-------------------|-------|
| SoC bit SHA | D65F3524…A4DF | live SHA256 of `arty_a7_ng_integrate_fit_soc.bit` (3826008 B) **MATCH** | **EVIDENCE** |
| Proxy CONTROL SHA | D2FC41A7…D23CA3 | live SHA256 of `arty_a7_ng_integrate_fit_own_cut.bit` (3826000 B) **MATCH**; ≠ SoC | **EVIDENCE** |
| WNS / TNS | 0.952 / 0.000 | `fit_soc_timing.rpt` Design Timing Summary; constraints met | **EVIDENCE** |
| WHS / THS | 0.012 / 0.000 | same summary | **EVIDENCE** |
| LUT / FF / DSP | 5695 / 5903 / 0 | `fit_soc_util.rpt` | **EVIDENCE** |
| Block RAM Tile | 0 / 135 | util Block RAM Tile Used=0; RAMB36=0 RAMB18=0 | **EVIDENCE** |
| MIG | instantiated | hier `u_mig` / `mig_7series_0` LUT=4315 FF=3487 LUTRAM=370 | **EVIDENCE** |
| PE lanes | 16 | hier `u_sc` + 16×`g_lane[0..15].u_lane` (sum lane LUT=1056 / parent 1046 LUT-combine; FF=1856) | **EVIDENCE** |
| Frozen LM-06 / 01R / 02M / A0.3 | MATCH | live rehash vs `frozen_sha_soc.txt` EXPECT | **EVIDENCE** |
| LM-06 weight fabric | ABSENT | RTL comment + BRAM=0; no LM weight module in hier | **EVIDENCE** (LIMIT) |
| UART exam | stub / exam DEFERRED | `a7ng_exam_uart_stub` status 0x91; no grade path | **EVIDENCE** |
| u_arb / u_compose instance rows | “present” | **ABSENT** as named hier rows (likely flattened into top 80 LUT) | **ENGINEERING_INFERENCE** (RTL wired) |
| `a7ng_bram_hotset` | graph/cache | `u_hot` 44 LUT / 137 FF / **0 RAMB** — FF arrays, not Block RAM | **EVIDENCE** |
| XSim marker | (none claimed) | no A7NG_*_XSIM_PASS for this SoC bit | **ABSENT** (class = post-route only) |

---

## Declared scientific frame (graded)

| Slot | Declared | Auditor grade |
|------|----------|---------------|
| OBSERVATION | proxy BRAM130 PE optimized away; not HS-02 path | **EVIDENCE** (prior AUDIT / util) |
| UNKNOWN | real SoC meet BRAM/WNS/TNS + PE measured + UART stub? | **Closed YES (NARROW)** — **EVIDENCE** |
| H_CANDIDATE | full SoC (or honest LIMIT) ≠ proxy SHA | **SUPPORTED (NARROW)** — **EVIDENCE** |
| H_RIVAL | retick proxy as SoC; program proxy for teacher-off | **Did not fire** |
| FALSIFIER | frozen overwrite; PE sold as 16 when gone; BOARD_PASS | **Did not fire** for PE/frozen/BOARD |
| UNIT | one post-route SoC composition | **EVIDENCE** |
| CONTROL | proxy D2FC41A7… + frozen LM/01R/02M/A0.3 | **EVIDENCE** |
| METRICS | BRAM/WNS/TNS/PE/MIG/UART | numeric **EVIDENCE**; LM-06 fabric / HS-02 **LIMIT/DEFERRED** |

---

## Findings

```
[MAJOR] PASS_NARROW SoC must not tick §14 Integrated design / LM-06 response path
  where     : GATE_integrate_fit_soc.md LIMIT rows; 14_FINAL_ACCEPTANCE_CHECKLIST.md
              Hardware + LM-06; LOOP_STATE reopen note “MIG+LM-06 path”
  claim      : FULL SoC reopen meets integrate_fit numeric BRAM/WNS/TNS + PE fabric
  evidence   : LM-06 weight fabric ABSENT by design (arb+compose stub only); UART exam
               stub only (blind HS-02 DEFERRED); BRAM hotset is FF-array (0 RAMB);
               Evidence_class=POST_ROUTE_SOC — not silicon.
  why it matters: A reader could treat DONE_ENG as §14 Hardware + LM-06 closed or as
                  teacher_off vehicle fully ready; HS-22 / HS-02 remain OPEN.
  fix        : Keep PASS_NARROW + LIMIT labels; allow DONE_ENG for fit unknown only;
               leave teacher_off_exam / §14 LM+Hardware boxes OPEN until weight path
               and silicon exam evidence exist.
```

```
[MINOR] u_arb / u_compose not evidenced as named post-route hierarchy rows
  where     : GATE_integrate_fit_soc.md “u_arb + u_compose | EVIDENCE”;
              fit_soc_util_hier.rpt (no a7ng_lm_graph_arb / a7ng_evidence_compose)
  claim      : LM arb + evidence compose present in fabric
  evidence   : RTL instantiates both; hier lists u_mig/u_sc/u_fetch/u_exam/u_led only;
               top self-cell 80 LUT / 186 FF may absorb flattened arb/compose.
  why it matters: “EVIDENCE” overstates post-route instance proof for the LM path stub.
  fix        : Relabel arb/compose as RTL+inferred-in-top, or keep_hierarchy and re-report.
```

---

## Allowed narrow closure (why allow_loop_done_eng=true)

Reopen UNKNOWN: real MIG + DONT_TOUCH PE fabric + LM-arb path stub + UART stub meet device BRAM/WNS/TNS with PE measured and bit SHA ≠ proxy CONTROL.

That unknown is **met** on file-backed post-route SoC with honest PASS_NARROW + LIMIT (no LM-06 weights; exam DEFERRED; proxy retained; frozen MATCH; no BOARD_PASS).

`allow_loop_done_eng: true` = engineering close of **this** SoC-fit unknown only — **not** Native V1, **not** §14 Hardware/LM-06 tick, **not** HS-02 silicon, **not** WM-00 bankable.

---

## Explicit non-claims (auditor confirms)

- Not `NATIVE_V1_MINI_AI_BOARD_PASS` / not AI-declared BOARD_PASS  
- Not LM-06 weight fabric / HS-22 closed  
- Not silicon HS-02 blind exam (UART stub ≠ exam)  
- Not proxy own_cut as SoC or as HS-02 program vehicle  
- Not WM-00 100 MHz bankable (WNS=−290.499 OOC)  
- Not encoder ungated-DIFF / H5 progress (encoder lane PARKED)

---

## NOT VERIFIED

- Live re-run of Vivado `measure_integrate_fit_soc.tcl` this session (artifacts + SHA re-derived only)  
- Functional MIG calib / DDR traffic on board (post-route util ≠ silicon)  
- Functional dual-owner under real LM vs graph traffic (`dual_owner_err` unreachable by construction)  
- That flattened u_arb/u_compose cells remain after opt (no cell-level netlist dump archived)  
- XSim of SoC top (ABSENT; not claimed)
