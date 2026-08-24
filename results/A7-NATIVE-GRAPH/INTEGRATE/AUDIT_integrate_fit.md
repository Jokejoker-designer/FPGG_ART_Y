# AUDIT — integrate_fit (VERIFY_ONLY)

**Auditor:** `a7-evidence-auditor`  
**Mode:** READ_ONLY_AUDIT / VERIFY_ONLY (no RTL edit; no LOOP_STATE flip)  
**Date:** 2026-08-22  
**Evidence_class:** **POST_ROUTE_PROXY** (not silicon, not BOARD, not fitted LM+graph SoC)  
**GATE:** `integrate_fit`  
**LOOP_STATE:** first OPEN / `next` = `integrate_fit` (matches this audit)  
**Implementer DISPATCH:** `a7-vivado-gate` / `PASS_NARROW` / bit SHA `D2FC41A7…D23CA3`  
**Refuse rule:** DONE_ENG allow **false** if BRAM>prefer without LIMIT label, WNS\<0 sold as PASS, frozen SHA drift, proxy sold as §14 Integrated design / BOARD_PASS, or phase-share FALSIFIED quietly reopened as PASS.

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
severity_metrics: BRAM 130/135 EVIDENCE; WNS=+1.365 TNS=0 EVIDENCE (proxy only); prior u_a_phase_share 135 FALSIFIED stands; frozen LM/01R/02M/A0.3 MATCH; WM-00 WNS=-290.499 OPEN; no BOARD_PASS; Evidence_class=POST_ROUTE_PROXY
```

H_CANDIDATE (**ownership-audited Prefer≤130 tile cut** meets BRAM≤130 + WNS≥0 + TNS=0 on the declared proxy) **SUPPORTED** — **EVIDENCE** (re-derived from `fit_own_cut_*.rpt` + live bit SHA).  
H_RIVAL (illegal collapse / frozen overwrite / host answer path) **did not fire** — frozen MATCH; no host answer in measure path.  
§14 “Integrated design fits” / full R6 MIG+LM+graph SoC **NOT closed** by this archive (finding #1).  
WM-00 bankable timing **remains OPEN** (WNS=−290.499) — **EVIDENCE**.

**Do not declare BOARD_PASS.** **Do not flip LOOP_STATE** (orchestrator only).  
Orchestrator **may** mark `DONE_ENG` for this **narrow** unknown only.

---

## Declared scientific frame (graded)

| Slot | Declared | Auditor grade |
|------|----------|---------------|
| OBSERVATION | `u_a_phase_share` FALSIFIED; MAS LUT OOC ~824%; WM-00 timing OPEN | **EVIDENCE** (prior util 135/135; FIT_NOTE; BRAM-WM-00) |
| UNKNOWN | ownership-audited ≤130 cut meet Prefer≤130 + WNS/TNS? | **Closed YES (proxy)** — **EVIDENCE** |
| H_CANDIDATE | ownership cut meets Prefer≤130 + WNS≥0 TNS=0 | **SUPPORTED (NARROW)** — **EVIDENCE** |
| H_RIVAL | fit via illegal collapse / frozen overwrite / host answer | **Did not fire** — **EVIDENCE** |
| FALSIFIER | util>device w/o LIMIT; WNS\<0 as PASS; frozen SHA change | **Did not fire** |
| UNIT | one post-route ownership-cut composition (not query bag) | **EVIDENCE** |
| CONTROL | frozen LM-06/01R/02M/A0.3; prior phase-share 135 LIMIT | **EVIDENCE** (live rehash) |
| METRICS | BRAM/WNS/TNS/WHS; dual-owner; PE; MIG; DDR corruption | BRAM/WNS/TNS **EVIDENCE**; PE/dual/MIG **caveats** (findings) |

---

## Dispatch / loop law

| Check | Outcome |
|-------|---------|
| `LOOP_STATE.next` / first OPEN = `integrate_fit` | **PASS** |
| Implementer agent = `a7-vivado-gate` (FALLBACK / registry) | **PASS** — DISPATCH_LOG last implementer line |
| Evidence_class mixed as board/silicon | **PASS** — labeled `POST_ROUTE_PROXY`; silicon deferred |
| BOARD_PASS language | **PASS** — explicit non-claims |
| Auditor VERIFY_ONLY (no LOOP flip) | **PASS** — this file |

---

## Independent re-derive (headline numbers)

| Metric | Claim | Auditor re-derive | Class |
|--------|------:|-------------------|-------|
| Block RAM Tile | 130/135 | `fit_own_cut_util.rpt` line: Used=130 Available=135 Util%=96.30; primitives RAMB36E1=130 | **EVIDENCE** |
| WNS / TNS | 1.365 / 0.000 | `fit_own_cut_timing.rpt` Design Timing Summary; “All user specified timing constraints are met.” | **EVIDENCE** (proxy clock) |
| WHS / THS | 0.067 / 0.000 | same timing summary | **EVIDENCE** |
| LUT / FF / DSP | 182 / 61 / 0 | util Slice LUTs=182 Registers=61 DSPs=0; primitives LUT6=111 FDCE=60 | **EVIDENCE** |
| Own-cut bit SHA | D2FC41A7…D23CA3 | live SHA256 MATCH file `arty_a7_ng_integrate_fit_own_cut.bit` | **EVIDENCE** |
| Frozen LM-06 | 67C37DD5…E3BA MATCH | live rehash MATCH | **EVIDENCE** |
| Frozen 01R / 02M / A0.3 | MATCH | live rehash MATCH | **EVIDENCE** |
| Prior phase-share | 135 LIMIT / FALSIFIED | `fit_phase_share_util.rpt` Block RAM Tile=135/135; WNS=1.234 | **EVIDENCE** |
| Formula 66+64+0 | 130 | TCL `residual_n=66` `shared_n=64` a03=0 — model matches forced RAMB36 count | **EVIDENCE** (proxy accounting) |
| MIG BRAM | 0 cited | NG-03 closeout MIG post-route BRAM=0 — **not** re-instantiated this run | **ENGINEERING_INFERENCE** (cited) |
| WM-00 WNS | −290.499 OPEN | BRAM-WM-00 OOC archive | **EVIDENCE** (separate class) |

---

## Findings

```
[MAJOR] Proxy WNS/BRAM must not be read as §14 Integrated SoC fit
  where     : results/A7-NATIVE-GRAPH/INTEGRATE/GATE_integrate_fit.md (WNS/TNS PASS rows);
              PLAN_KDENSE_20260822.md §5 (“timing of proxy top”)
  claim      : ownership-cut post-route meets Prefer≤130 + WNS≥0 + TNS=0
  evidence   : Design is AUTOGEN RAMB36E1 shell top (`measure_integrate_fit_own_cut.tcl`);
               LUT=182 FF=61 — not LM-06+graph+MIG composition. Checklist §14
               “Integrated design fits xc7a100t” remains unchecked. WM-00 OOC
               WNS=-290.499 still OPEN / not bankable.
  why it matters: A reader could treat integrate_fit DONE_ENG as Hardware §14 closed
                  or as SoC timing PASS; PLAN already warns proxy ≠ fitted SoC.
  fix        : Keep result PASS_NARROW; Evidence_class=POST_ROUTE_PROXY; never tick
               §14 Hardware from this bit alone; keep WM-00 timing OPEN in LOOP note.
```

```
[MAJOR] PE/lanes=16 “scorer array keep” not evidenced in post-route fabric
  where     : GATE_integrate_fit.md measured row “PE / lanes | 16 | scorer array keep”;
              fit_own_cut_util.rpt primitives (LUT6=111, FDCE=60, RAMB36E1=130)
  claim      : 16 PE / lanes kept in ownership-cut measure
  evidence   : TCL instantiates `a7ng_scorer_array` + episode/index banks, but routed
               util is BRAM-dominated with ~182 LUT / 61 FF — incompatible with a
               kept 16-lane scorer (cf. TermGen OOC LUT~12k). Logic was optimized away.
  why it matters: Inflates “PE count measured” toward checklist language without fabric proof.
  fix        : Relabel PE as “instantiated in source / optimized away post-route” or
               force DONT_TOUCH/keep hierarchy and re-measure; do not cite PE=16 as EVIDENCE.
```

---

## Allowed narrow closure (why allow_loop_done_eng=true)

PLAN C3 unknown for this reopen: **new lever** (drop concurrent A0.3 + DDR-spill cut of `u_a`) → Prefer≤130 + WNS≥0 + new bit + no frozen overwrite.

That narrow unknown is **met** on file-backed post-route proxy with honest PASS_NARROW + documented non-claims (no concurrent A0.3; MIG cited; DDR spill capacity proxy; WM-00 OPEN).

`allow_loop_done_eng: true` = engineering close of **this** unknown only — **not** Native V1, **not** §14 Hardware, **not** WM-00 bankable, **not** functional DDR act-spill RTL.

---

## Explicit non-claims (auditor confirms)

- Not `NATIVE_V1_MINI_AI_BOARD_PASS` / not AI-declared BOARD_PASS  
- Not full MIG + LM-06 + graph functional bitstream  
- Not concurrent A0.3 + LM + graph  
- Not WM-00 100 MHz bankable  
- Not DDR corruption silicon / functional spill law  
- Not encoder ungated-DIFF / H5 progress (encoder lane PARKED)

---

## NOT VERIFIED

- Full hierarchical util / `report_utilization -hierarchical` for residual vs shared tile owners (flat util only)  
- Live re-run of Vivado flow this audit session (artifacts + SHA re-derived only)  
- Functional dual-owner under real LM vs graph traffic (FSM exclusivity is by construction; `dual_owner_err` path `owner_is_lm && owner_is_graph` is unreachable)  
- MIG BRAM on this composed top (cited NG-03 only)  
- Silicon JTAG of `arty_a7_ng_integrate_fit_own_cut.bit`
