# AUDIT — wm00_timing (VERIFY_ONLY)

**Auditor:** `a7-evidence-auditor`  
**Mode:** VERIFY_ONLY (no RTL edit; **no LOOP_STATE flip**)  
**Date:** 2026-08-22  
**Evidence_class:** **XSIM** + **OOC_POST_ROUTE** (DERIVED from post-route reports — **not BOARD**, not silicon)  
**GATE:** `wm00_timing`  
**LOOP_STATE:** `next` / first OPEN = `wm00_timing`  
**Implementer DISPATCH:** `a7-ng-memory-arch` / `PASS_NARROW` / artifact `GATE_wm00_timing.md`  
**Parallel VERIFY:** `a7-vivado-gate` PASS_NARROW; `a7-ng-xsim-verify` PASS_NARROW  
**Refuse rule:** FAIL if BOARD_PASS / §45 `BRAM_WORKING_MEMORY_ARCH_PASS` self-declared, WNS&lt;0 sold as timing PASS, lossless regress, frozen SHA drift, or OOC WM sold as SoC/silicon.

```text
MUST_READ_UNBLOCK_H5: read. Next = ungated DIFF twin (not S2, not glue).
BLUEPRINT_LOOP: read. Goal=NATIVE_V1_MINI_AI_BOARD_PASS. Next=wm00_timing
```

---

## Verdict

```text
AUDIT: 1 FINDING
result: PASS_NARROW
allow_loop_done_eng: true
severity_metrics: OOC WNS=+0.069 TNS=0.000 constraints MET; CONTROL WNS=-290.499 byte-identical archive; 8/8 XSim bags PASS TOP8 31..24; LUT/FF/BRAM/DSP=2990/7493/0/0; evidence SHA A99C6C73… top 0B76BCF9…; frozen LM-06/01R/02M/A0.3+schema MATCH; no ARCH_PASS; no BOARD_PASS; Evidence_class=XSIM+OOC_POST_ROUTE
```

H_CANDIDATE (one timing change → OOC WNS≥0 TNS=0 + lossless XSim + frozen MATCH) **SUPPORTED (NARROW)** — **EVIDENCE**.  
H_RIVAL (claim bankable while WNS&lt;0; overwrite frozen) **FALSIFIED** — **EVIDENCE**.  
§45 `BRAM_WORKING_MEMORY_ARCH_PASS` / SoC 100 MHz / `NATIVE_V1_MINI_AI_BOARD_PASS` **NOT DECLARED** (finding #1 is wording-only).

**Do not declare BOARD_PASS.** **Do not flip LOOP_STATE** (orchestrator only).  
Orchestrator **may** mark `wm00_timing` `DONE_ENG` for this **narrow** OOC timing unknown only (`allow_loop_done_eng: true`).

---

## Dispatch / loop law

| Check | Outcome |
|-------|---------|
| `LOOP_STATE.next` / first OPEN = `wm00_timing` | **PASS** |
| Implementer agent = `a7-ng-memory-arch` (`run_blueprint_loop.py` FALLBACK) | **PASS** — DISPATCH_LOG |
| Parallel `a7-vivado-gate` VERIFY same gate | **PASS** — PASS_NARROW; WNS/TNS re-derived |
| Parallel `a7-ng-xsim-verify` VERIFY same gate | **PASS** — PASS_NARROW; independent re-sim marker |
| Auditor agent this VERIFY = `a7-evidence-auditor` | **PASS** |
| Evidence_class mixed as board/silicon | **PASS** — OOC + XSim only; SILICON_DEFERRED |
| BOARD_PASS / §45 ARCH_PASS language | **PASS** — explicit non-claims |
| Auditor VERIFY_ONLY (no LOOP flip) | **PASS** — this file |

---

## Independent re-derive (headline numbers)

| Metric | Claim | Auditor re-derive | Class |
|--------|------:|-------------------|-------|
| OOC WNS / TNS | +0.069 / 0.000 | `timing/timing_route.rpt` Design Timing Summary L141; Slack (MET) 0.069 ns; Setup failing endpoints=0; L144 constraints met | **EVIDENCE** |
| CONTROL WNS / TNS | −290.499 / −108584.445 | `CONTROL_timing_route_wns_neg290.rpt` L141; SHA256 **identical** to parent `BRAM-WM-00/timing_route.rpt` (`BA192AD1…`) | **EVIDENCE** |
| LUT / FF / BRAM / DSP | 2990 / 7493 / 0 / 0 | `timing/util_route.rpt` Slice LUTs=2990; Slice Registers=7493; Block RAM Tile=0; DSPs=0 | **EVIDENCE** |
| XSim marker | `A7NG_BRAM_WM00_XSIM_PASS` | implementer `xsim_wm00_timing.log` + VERIFY `xsim_wm00_verify.log` both emit marker + `A7NG_BRAM_WM00_XSIM_OK`; 8 bags incl. TOP8 `nodes=31..24`; FILL256 DROP=0 | **EVIDENCE** |
| evidence.sv SHA | A99C6C73…747D0740 | live SHA256 **MATCH** | **EVIDENCE** |
| top.sv SHA | 0B76BCF9…932E25 | live SHA256 **MATCH** | **EVIDENCE** |
| Schema SHA | F0FE426E… | live SHA256 **MATCH** | **EVIDENCE** |
| Frozen LM-06 / 01R / 02M / A0.3 | MATCH | live rehash vs EXPECT — all **MATCH** | **EVIDENCE** |
| Prior evidence SHA (bram_wm_00) | 1F7F3950… (control RTL) | superseded in-tree by systolic pipeline; CONTROL timing FAIL retained | **EVIDENCE** |
| BOARD_PASS | false | GATE / closeout / vivado / xsim VERIFY | **EVIDENCE** |
| §45 ARCH_PASS | NOT DECLARED | GATE + closeout | **EVIDENCE** |

### XSim bags (VERIFY log)

| Bag | Log line | Grade |
|-----|----------|-------|
| FILL256 | `count=256 drop=0 ddr_bytes=4096` | **EVIDENCE** |
| OVERFLOW | `drop=1 (not silent)` | **EVIDENCE** |
| FRONTIER | `count=64 drop=1` | **EVIDENCE** |
| TOP8 | `nodes=31..24` | **EVIDENCE** |
| LEARN | `count=32 coal=1 wr=16 bytes=512` | **EVIDENCE** |
| 16PE | `grants=16` | **EVIDENCE** |
| DUAL_OWNER | `dual_cnt=2` | **EVIDENCE** |
| SCHEMA | NodeRecordV1 version=1 | **EVIDENCE** |

### Forbidden-route sweep

| Route | Result |
|-------|--------|
| Golden / expected TOP8 edited to match | **Not found** — TB still requires 31..24 |
| Test deleted / DROP falsifier removed | **Not found** — OVERFLOW/FRONTIER still DROP>0 |
| Frozen bit overwrite | **Not found** — LM/01R/02M/A0.3 MATCH |
| Negative timing hidden | **Not found** — CONTROL −290.499 archived + byte-identical |
| Host gradient / winner / answer | **Not found** |
| BOARD_PASS / ARCH_PASS self-declare | **Not found** |
| Metric collapse (correctness for timing) | **Not found** — lossless XSim held; LUT↓ expected from comb→pipeline |

---

## Declared scientific frame (graded)

| Slot | Declared | Auditor grade |
|------|----------|---------------|
| OBSERVATION | prior lossless; OOC WNS≈−290.499 not bankable | **EVIDENCE** (prior AUDIT + CONTROL rpt) |
| UNKNOWN | one Top-8 pipeline → WNS≥0 TNS=0 + lossless + frozen MATCH? | **Closed YES (NARROW OOC)** — **EVIDENCE** |
| H_CANDIDATE | new archive WNS≥0 TNS=0 + lossless | **SUPPORTED** — **EVIDENCE** |
| H_RIVAL | bankable while WNS&lt;0; overwrite frozen | **FALSIFIED** — **EVIDENCE** |
| FALSIFIER | lossless regress; frozen drift; BOARD_PASS language | **Did not fire** |
| UNIT | WM query/seed bags + OOC timing summary | **EVIDENCE** |
| CONTROL | prior lossless + CONTROL WNS=−290.499 | **EVIDENCE** |
| METRICS | WNS/TNS/util/XSim/frozen SHA | **EVIDENCE** |

---

## Finding

```
[MINOR] "OOC bankability" wording can be misread as §45 ARCH_PASS
  where     : results/A7-NATIVE-GRAPH/BRAM-WM-00/timing/GATE_wm00_timing.md:49
  claim      : "unknown closed for WM-00 OOC bankability"
  evidence   : Gate correctly refuses BRAM_WORKING_MEMORY_ARCH_PASS (§45) and BOARD_PASS;
               only OOC post-route WNS/TNS + XSim closed. §45 remains multi-item (not this gate).
  why it matters: a reader skimming "bankable" may treat WM-00 as architecture-complete
  fix        : Prefer "OOC timing closed (WNS≥0 TNS=0)" in status tables; keep ARCH_PASS NOT DECLARED
```

---

## NOT VERIFIED

- Fresh OOC synth/impl re-run by auditor (vivado-gate also re-derived from archived `timing_route.rpt` / `util_route.rpt`; batch log `vivado_ooc.log` present but not re-executed here).
- Full SoC integration of pipelined WM-00 @100 MHz (explicit LIMIT; out of gate unknown).
- Silicon / JTAG / BOARD_UART (SILICON_DEFERRED).
- Parent chat did not write RTL this VERIFY (implementer was Task `a7-ng-memory-arch` per DISPATCH).

---

## allow_loop_done_eng

**true** — narrow unknown (OOC WNS≥0 TNS=0 + lossless XSim + frozen MATCH) closed with PASS_NARROW; CONTROL FAIL archived; no BOARD_PASS; no LOOP flip by auditor.
