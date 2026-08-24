# AUDIT — lm06_soc_path (VERIFY_ONLY evidence auditor)

**Auditor:** `a7-evidence-auditor`  
**Mode:** VERIFY_ONLY (no RTL edit; **no LOOP_STATE flip**)  
**Date:** 2026-08-22  
**Evidence_class:** **POST_ROUTE_SOC** (not silicon, not BOARD, not HS-02 exam)  
**GATE:** `lm06_soc_path`  
**LOOP_STATE:** `next` / first OPEN = `lm06_soc_path`  
**Implementer DISPATCH:** `a7-vivado-gate` (FALLBACK) / `PASS_NARROW` / SoC SHA `D61BA6D4…053FA3`  
**Refuse rule:** FAIL if BOARD_PASS self-declared, CONTROL SoC sold as new bit, frozen LM-06 overwrite, weight-cut sold as full HS-22 / §14 LM-06 active, or lm_path hardwired-1 with BRAM=0.

```text
MUST_READ_UNBLOCK_H5: read. Next = ungated DIFF twin (not S2, not glue).
BLUEPRINT_LOOP: read. Goal=NATIVE_V1_MINI_AI_BOARD_PASS. Next=lm06_soc_path
```

---

## Verdict

```text
AUDIT: 2 FINDINGS
result: PASS_NARROW
allow_loop_done_eng: true
severity_metrics: SoC D61BA6D4… ≠ CONTROL D65F3524…; BRAM=64 (wtile32+wpp32) EVIDENCE; WNS=+0.365 TNS=0 EVIDENCE; PE lanes=16 fabric EVIDENCE (u_sc LUT=1048 FF=1856); frozen LM/01R/02M/A0.3 MATCH; u_a ABSENT LIMIT; lm_path RTL sticky only (not board-probed); XSim ABSENT; no BOARD_PASS; Evidence_class=POST_ROUTE_SOC
```

H_CANDIDATE (integrated SoC includes LM-06 weight modules with WNS≥0 TNS=0 BRAM≤device; frozen SHA MATCH; non-fake lm_path wiring) **SUPPORTED (NARROW)** — **EVIDENCE** (post-route).  
H_RIVAL (fake lm_path=1 with BRAM=0; overwrite frozen LM-06; host answers / BOARD_PASS) **did not fire**.  
§14 LM-06 “active on FPGA response path” / HS-22 silicon participation / board `lm_path≠0` **NOT closed** (finding).  
`NATIVE_V1_MINI_AI_BOARD_PASS` = **NOT EVIDENCED**.

**Do not declare BOARD_PASS.** **Do not flip LOOP_STATE** (orchestrator only).  
Orchestrator **may** mark `DONE_ENG` for this **narrow** weight-fabric-fit unknown only (`allow_loop_done_eng: true`).

---

## Dispatch / loop law

| Check | Outcome |
|-------|---------|
| `LOOP_STATE.next` / first OPEN = `lm06_soc_path` | **PASS** |
| Implementer agent = `a7-vivado-gate` (`run_blueprint_loop.py` FALLBACK) | **PASS** — DISPATCH_LOG implementer line |
| Parallel VERIFY = `a7-ng-xsim-verify` + `a7-vivado-gate` VERIFY_ONLY | **PASS** — both PASS_NARROW on disk |
| Auditor agent this VERIFY = `a7-evidence-auditor` | **PASS** |
| Evidence_class mixed as board/silicon | **PASS** — labeled `POST_ROUTE_SOC`; silicon DEFERRED |
| BOARD_PASS language | **PASS** — explicit non-claims; `board_pass: false` |
| Auditor VERIFY_ONLY (no LOOP flip) | **PASS** — this file |

---

## Independent re-derive (headline numbers)

| Metric | Claim | Auditor re-derive | Class |
|--------|------:|-------------------|-------|
| New SoC bit SHA | D61BA6D4…053FA3 | live SHA256 of `arty_a7_ng_lm06_soc.bit` (3826003 B) **MATCH** | **EVIDENCE** |
| CONTROL SoC SHA | D65F3524…A4DF | live SHA256 of INTEGRATE SoC (3826008 B) **MATCH**; **≠** new SoC | **EVIDENCE** |
| WNS / TNS | 0.365 / 0.000 | `lm06_soc_timing.rpt` Design Timing Summary L141; constraints met | **EVIDENCE** |
| WHS / THS | 0.015 / 0.000 | same summary | **EVIDENCE** |
| LUT / FF / DSP | 7202 / 8060 / 0 | `lm06_soc_util.rpt` Slice LUTs/Regs/DSPs | **EVIDENCE** |
| Block RAM Tile | 64 / 135 | util Block RAM Tile Used=64; hier RAMB36=64 | **EVIDENCE** |
| Weight fabric | PRESENT | hier `u_lm06_wtile` RAMB36=32 (`weight_tile803k`) + `u_lm06_wpp` RAMB36=32 (`tile_weight_pingpong`) | **EVIDENCE** |
| Act `u_a` | ABSENT | hier instance count 0; RTL comment intentional | **EVIDENCE** (LIMIT) |
| PE lanes | 16 | hier `u_sc` + 16×`g_lane[0..15].u_lane`; parent LUT=1048 FF=1856 | **EVIDENCE** |
| MIG | present | hier `u_mig` LUT=4313 | **EVIDENCE** |
| Frozen LM-06 / 01R / 02M / A0.3 | MATCH | live rehash vs EXPECT — all **MATCH** | **EVIDENCE** |
| lm_path | sticky RTL; not board-probed | RTL write→readback sticky → UART `lm_path_i`; no COM12 probe this gate | **ENGINEERING_INFERENCE** (RTL) + **LIMIT** |
| XSim marker | (none claimed) | VERIFY: ABSENT; no `A7NG_*_XSIM_PASS` | **ABSENT** |
| BOARD_PASS | false | GATE / FIT / LIMIT / VERIFY | **EVIDENCE** |

### lm_path sticky (auditor read of RTL)

```text
// arty_a7_ng_lm06_soc_top.sv — under grant_lm:
//   write tick^0xA5 → readback match → wt_seen → lm_path_sticky=1
//   assign lm_path_active = lm_path_sticky | (compose_active & lm_path_sticky)
//                         ≡ lm_path_sticky   (compose term does not add)
// SIM_FULL=0 weight_tile803k; synthetic tick traffic; not frozen-bit weight load
```

---

## Declared scientific frame (graded)

| Slot | Declared | Auditor grade |
|------|----------|---------------|
| OBSERVATION | SoC D65F3524 had lm_path=0 / weights ABSENT | **EVIDENCE** (prior teacher_off) |
| UNKNOWN | weight fabric fit WNS≥0 TNS=0 BRAM≤device + lm_path≠0 path? | **Closed YES (NARROW)** for fit/BRAM/timing; lm_path board **OPEN LIMIT** |
| H_CANDIDATE | new SoC archive with real weight modules; frozen MATCH | **SUPPORTED (NARROW)** — **EVIDENCE** |
| H_RIVAL | fake lm_path=1; host answers; overwrite frozen | **Did not fire** (BRAM64; no BOARD_PASS; frozen MATCH) |
| FALSIFIER | frozen SHA change; BOARD_PASS; HS-02 without retrieval | **Did not fire** |
| UNIT | one post-route SoC composition | **EVIDENCE** |
| CONTROL | SoC D65F3524…; frozen LM/01R/02M/A0.3 | **EVIDENCE** |
| METRICS | BRAM/WNS/TNS/PE/wt hier/SHA | numeric **EVIDENCE**; full LM / HS-02 / board lm_path **LIMIT** |

---

## Findings

```
[MAJOR] PASS_NARROW weight-cut must not tick §14 LM-06 / HS-22
  where     : GATE_lm06_soc_path.md; LIMIT_weight_cut.md;
              14_FINAL_ACCEPTANCE_CHECKLIST.md LM-06; 04_HARDSTOPS.md HS-22;
              rtl/board/arty_a7_ng_lm06_soc_top.sv lm_path sticky
  claim      : LM-06 weight fabric on integrated SoC response path (UNKNOWN closed)
  evidence   : Post-route proves weight_tile803k + tile_weight_pingpong BRAM64 fit with
               WNS=+0.365. Path is smoke tick write/readback → sticky UART bit — not
               frozen-law weight load, not retrieval answers, not board lm_path≠0.
               Full act u_a + GPT/DSP core ABSENT (WEIGHT_CUT_ONLY). XSim ABSENT.
  why it matters: A reader could treat DONE_ENG as §14 “LM-06 active on FPGA response
                  path” / HS-22 participation closed; silicon teacher-off still needs
                  D61BA6D4 vehicle + live lm_path probe.
  fix        : Keep PASS_NARROW + LIMIT; allow DONE_ENG for weight-fabric-fit unknown
               only; leave §14 LM-06 / HS-22 / HS-02 OPEN until board lm_path≠0 and
               retrieval-class evidence exist.
```

```
[MINOR] lm_path_active reduces to lm_path_sticky; compose/arb not named in hier
  where     : arty_a7_ng_lm06_soc_top.sv assign lm_path_active;
              lm06_soc_util_hier.rpt (no u_compose / u_arb rows)
  claim      : lm_path from weight evidence on response/compose path
  evidence   : `lm_path_sticky | (compose_active & lm_path_sticky)` ≡ sticky alone;
               intent XOR uses pp_keep but does not gate lm_path; u_compose/u_arb
               absent as named hier rows (likely flattened into top 91 LUT).
  why it matters: Slightly overstates compose coupling as independent lm_path proof.
  fix        : Relabel lm_path as sticky-from-weight-BRAM-R/W only; or keep_hierarchy
               on compose/arb and re-report.
```

---

## Allowed narrow closure (why allow_loop_done_eng=true)

UNKNOWN (narrow): can integrated SoC include LM-06 **weight** modules (`weight_tile803k` + `tile_weight_pingpong`) with WNS≥0 TNS=0 BRAM≤135, PE16 fabric retained, frozen LM-06/01R/02M/A0.3 MATCH, new bit ≠ CONTROL SoC, without hardwiring lm_path=1 at BRAM=0.

That unknown is **met** on file-backed post-route SoC with honest PASS_NARROW + WEIGHT_CUT_ONLY LIMIT (`u_a` ABSENT; lm_path RTL-only; no BOARD_PASS).

`allow_loop_done_eng: true` = engineering close of **this** weight-fabric-fit unknown only — **not** Native V1, **not** §14 LM-06 tick, **not** HS-22 silicon participation, **not** semantic HS-02.

---

## Explicit non-claims (auditor confirms)

- Not `NATIVE_V1_MINI_AI_BOARD_PASS` / not AI-declared BOARD_PASS  
- Not full LM-06 law bitstream / act `u_a` / GPT+DSP core on SoC  
- Not silicon teacher-off retrieval / HS-02 semantic  
- Not board-proved UART `lm_path` bit5≠0 on D61BA6D4…  
- Not CONTROL SoC D65F3524… replaced as frozen release  
- Not encoder ungated-DIFF / H5 progress (encoder lane PARKED; no glue)

---

## NOT VERIFIED

- Live re-run of Vivado `measure_lm06_soc_path.tcl` this session (artifacts + SHA re-derived only)  
- Board program of `arty_a7_ng_lm06_soc.bit` + COM12 lm_path bit5 sample  
- Functional weight-law contents (frozen LM-06 payload) vs synthetic tick smoke  
- Cell-level netlist proof that flattened compose/arb remain after opt  
- XSim of SoC top (ABSENT; correctly not claimed)
