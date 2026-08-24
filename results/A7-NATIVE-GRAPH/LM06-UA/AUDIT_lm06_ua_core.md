# AUDIT — lm06_ua_core (VERIFY_ONLY evidence auditor)

**Auditor:** `a7-evidence-auditor`  
**Mode:** VERIFY_ONLY (no RTL edit; **no LOOP_STATE flip**)  
**Date:** 2026-08-22  
**Evidence_class:** **POST_ROUTE_SOC** (not silicon, not BOARD, not HS-02 exam)  
**GATE:** `lm06_ua_core`  
**LOOP_STATE:** `next` / first OPEN = `lm06_ua_core`  
**Implementer DISPATCH:** `a7-vivado-gate` (FALLBACK) / `PASS_NARROW` / SoC SHA `D2C6CF4B…B9A92C`  
**Parallel VERIFY:** `a7-ng-xsim-verify` / `PASS_NARROW` / XSim ABSENT  
**Refuse rule:** FAIL if BOARD_PASS self-declared, CONTROL weight-cut sold as new bit, frozen LM-06 overwrite, act+weight sold as HS-22 / §14 full LM-06, or lm_path hardwired-1 with no act BRAM.

```text
MUST_READ_UNBLOCK_H5: read. Next = ungated DIFF twin (not S2, not glue).
BLUEPRINT_LOOP: read. Goal=NATIVE_V1_MINI_AI_BOARD_PASS. Next=lm06_ua_core
```

---

## Verdict

```text
AUDIT: 2 FINDINGS
result: PASS_NARROW
allow_loop_done_eng: true
severity_metrics: SoC D2C6CF4B… ≠ CONTROL D61BA6D4…; BRAM=128 (wt64+u_a residual64) EVIDENCE; WNS=+0.257 TNS=0 EVIDENCE; named u_a/mem_reg_* RAMB36E1 in timing EVIDENCE; DSP=0 TinyGPT ABSENT LIMIT; PE lanes=16 fabric EVIDENCE; frozen LM/01R/02M/A0.3 MATCH; lm_path RTL sticky wt∧act only (not board-probed); XSim ABSENT; no BOARD_PASS; Evidence_class=POST_ROUTE_SOC
```

H_CANDIDATE (named `act_ram128k16 u_a` instantiates with weight tiles; WNS≥0 TNS=0 BRAM≤device; frozen MATCH; new bit ≠ weight-cut CONTROL) **SUPPORTED (NARROW)** — **EVIDENCE** (post-route).  
H_RIVAL (fake lm_path / no act BRAM; overwrite frozen LM-06; host answers / BOARD_PASS) **did not fire**.  
§14 LM-06 “active on FPGA response path” / HS-22 silicon participation / board `lm_path≠0` / TinyGPT+DSP core **NOT closed** (finding).  
`NATIVE_V1_MINI_AI_BOARD_PASS` = **NOT EVIDENCED**.

**Do not declare BOARD_PASS.** **Do not flip LOOP_STATE** (orchestrator only).  
Orchestrator **may** mark `DONE_ENG` for this **narrow** act+weight fabric-fit unknown only (`allow_loop_done_eng: true`).

---

## Dispatch / loop law

| Check | Outcome |
|-------|---------|
| `LOOP_STATE.next` / first OPEN = `lm06_ua_core` | **PASS** |
| Implementer agent = `a7-vivado-gate` (`run_blueprint_loop.py` FALLBACK) | **PASS** — DISPATCH_LOG implementer line |
| Parallel VERIFY = `a7-ng-xsim-verify` same gate | **PASS** — PASS_NARROW; XSim ABSENT correctly labeled |
| Auditor agent this VERIFY = `a7-evidence-auditor` | **PASS** |
| Evidence_class mixed as board/silicon | **PASS** — labeled `POST_ROUTE_SOC`; silicon not claimed |
| BOARD_PASS language | **PASS** — explicit non-claims; `board_pass: false` |
| Auditor VERIFY_ONLY (no LOOP flip) | **PASS** — this file |

---

## Independent re-derive (headline numbers)

| Metric | Claim | Auditor re-derive | Class |
|--------|------:|-------------------|-------|
| New UA SoC bit SHA | D2C6CF4B…B9A92C | live SHA256 of `LM06-UA/arty_a7_ng_lm06_ua_soc.bit` (3826006 B) **MATCH** | **EVIDENCE** |
| CONTROL weight-cut SHA | D61BA6D4…053FA3 | live SHA256 of `LM06-SOC/arty_a7_ng_lm06_soc.bit` (3826003 B) **MATCH**; **≠** new UA | **EVIDENCE** |
| WNS / TNS | 0.257 / 0.000 | `lm06_ua_timing.rpt` Design Timing Summary L141; constraints met | **EVIDENCE** |
| WHS / THS | 0.024 / 0.000 | same summary | **EVIDENCE** |
| LUT / FF / DSP | 7209 / 8075 / 0 | `lm06_ua_util.rpt` Slice LUTs/Regs/DSPs | **EVIDENCE** |
| Block RAM Tile | 128 / 135 | util Block RAM Tile Used=128; top hier RAMB36=128 | **EVIDENCE** |
| Weight fabric | PRESENT 64 | hier `u_lm06_wtile` RAMB36=32 + `u_lm06_wpp` RAMB36=32 | **EVIDENCE** |
| Act `u_a` | PRESENT; ua_bram=64 | timing paths `u_a/mem_reg_*` as **RAMB36E1**; residual **128−64=64**; RTL `act_ram128k16 u_a` + `DONT_TOUCH`/`keep_hierarchy` | **EVIDENCE** (named cell) + **ENGINEERING_INFERENCE** (exact 64 census; hier row ABSENT) |
| PE lanes | 16 | hier `u_sc` LUT=1047 FF=1856; 16×`g_lane[0..15]` | **EVIDENCE** |
| MIG | present | hier `u_mig` LUT=4301 | **EVIDENCE** |
| TinyGPT / DSP core | ABSENT LIMIT | DSP=0 util; no mac_array/gemv in SoC RTL cut | **EVIDENCE** (LIMIT) |
| Frozen LM-06 / 01R / 02M / A0.3 | MATCH | live rehash vs EXPECT — all **MATCH** | **EVIDENCE** |
| lm_path | sticky after wt_seen∧act_seen; not board-probed | RTL write→readback sticky → UART `lm_path_i`; no COM12 probe this gate | **ENGINEERING_INFERENCE** (RTL) + **LIMIT** |
| XSim marker | (none claimed) | VERIFY: ABSENT; no `A7NG_*_XSIM_PASS` | **ABSENT** |
| BOARD_PASS | false | GATE / FIT / LIMIT / VERIFY | **EVIDENCE** |

### lm_path sticky (auditor read of RTL)

```text
// arty_a7_ng_lm06_ua_soc_top.sv — under grant_lm:
//   wt readback → wt_seen; act_ram128k16 readback → act_seen
//   if (wt_seen && act_seen) lm_path_sticky <= 1
//   assign lm_path_active = lm_path_sticky | (compose_active & lm_path_sticky)
//                         ≡ lm_path_sticky
// SIM_FULL=0 weight_tile803k; synthetic tick traffic; not frozen-bit law forward
```

---

## Declared scientific frame (graded)

| Slot | Declared | Auditor grade |
|------|----------|---------------|
| OBSERVATION | weight-cut D61BA6D4… BRAM64; u_a ABSENT LIMIT | **EVIDENCE** (prior lm06_soc_path) |
| UNKNOWN | can u_a fit with weight tiles WNS≥0 TNS=0 BRAM≤device + path > sticky-UART? | **Closed YES (NARROW)** for fit/BRAM/timing/named u_a; board lm_path / TinyGPT **OPEN LIMIT** |
| H_CANDIDATE | new bit with named u_a + timing PASS | **SUPPORTED (NARROW)** — **EVIDENCE** |
| H_RIVAL | fake lm_path; overwrite frozen; host answers | **Did not fire** (u_a paths; BRAM128; frozen MATCH; no BOARD_PASS) |
| FALSIFIER | frozen SHA change; LIMIT sold as HS-22; BOARD_PASS | **Did not fire** |
| UNIT | one post-route SoC composition | **EVIDENCE** |
| CONTROL | weight-cut D61BA6D4…; frozen LM/01R/02M/A0.3 | **EVIDENCE** |
| METRICS | BRAM/WNS/TNS/PE/u_a/SHA | numeric **EVIDENCE**; full LM / HS-22 / board lm_path **LIMIT** |

---

## Findings

```
[MAJOR] PASS_NARROW act+weight must not tick §14 LM-06 / HS-22
  where     : GATE_lm06_ua_core.md; LIMIT_ua_core.md;
              14_FINAL_ACCEPTANCE_CHECKLIST.md LM-06; 04_HARDSTOPS.md HS-22;
              rtl/board/arty_a7_ng_lm06_ua_soc_top.sv lm_path sticky
  claim      : act u_a + weight fabric on integrated SoC (UNKNOWN closed)
  evidence   : Post-route proves act_ram128k16 u_a + weight tiles BRAM128 fit with
               WNS=+0.257. Path is smoke tick write/readback → sticky UART bit after
               wt_seen∧act_seen — not frozen-law TinyGPT/DSP forward, not retrieval
               answers, not board lm_path≠0. DSP=0; TinyGPT ABSENT LIMIT. XSim ABSENT.
  why it matters: A reader could treat DONE_ENG as §14 “LM-06 active on FPGA response
                  path” / HS-22 participation closed; silicon teacher-off still needs
                  D2C6CF4B vehicle + live lm_path probe + law core.
  fix        : Keep PASS_NARROW + LIMIT; allow DONE_ENG for act+weight fabric-fit
               unknown only; leave §14 LM-06 / HS-22 / HS-02 OPEN until board lm_path≠0
               and retrieval-class / TinyGPT-or-honest-LIMIT evidence exist.
```

```
[MINOR] hier omits u_a; ua_bram=64 is residual + sampled timing, not full cell census
  where     : lm06_ua_util_hier.rpt (no u_a row); GATE cites “DCP cell u_a”;
              lm06_ua_timing.rpt u_a/mem_reg_* (path-sampled)
  claim      : ua_bram=64 named act_ram128k16 PRESENT via DCP
  evidence   : Named u_a/mem_reg_* RAMB36E1 appears in timing (PRESENT). Exact 64 is
               128−64wt residual + design sizing; hier row ABSENT; DCP lives under
               build/out/ not copied into LM06-UA/. Timing max_paths samples ≪64 cells.
  why it matters: Overstates census precision; a hostile reader could demand a
                  report_property/get_cells dump before believing ua_bram=64.
  fix        : Archive get_cells -hier *u_a* RAMB count (or copy post-route DCP
               summary) under LM06-UA/; keep residual math as corroboration.
```

---

## Allowed narrow closure (why allow_loop_done_eng=true)

UNKNOWN (narrow): can integrated SoC include frozen-law **act** `act_ram128k16` as named `u_a` **with** LM-06 weight modules (`weight_tile803k` + `tile_weight_pingpong`) with WNS≥0 TNS=0 BRAM≤135, PE16 fabric retained, frozen LM-06/01R/02M/A0.3 MATCH, new bit ≠ CONTROL weight-cut, without hardwiring lm_path=1 at act-ABSENT.

That unknown is **met** on file-backed post-route SoC with honest PASS_NARROW + ACT_PLUS_WEIGHT / TinyGPT-DSP ABSENT LIMIT (lm_path RTL-only; no BOARD_PASS).

`allow_loop_done_eng: true` = engineering close of **this** act+weight fabric-fit unknown only — **not** Native V1, **not** §14 LM-06 tick, **not** HS-22 silicon participation, **not** semantic HS-02.

---

## Explicit non-claims (auditor confirms)

- Not `NATIVE_V1_MINI_AI_BOARD_PASS` / not AI-declared BOARD_PASS  
- Not full LM-06 law bitstream / TinyGPT + DSP≈154 on SoC  
- Not silicon teacher-off retrieval / HS-02 semantic  
- Not board-proved UART `lm_path` bit5≠0 on D2C6CF4B…  
- Not CONTROL weight-cut D61BA6D4… or frozen `arty_a7_lm06.bit` replaced  
- Not encoder ungated-DIFF / H5 progress (encoder lane PARKED; no glue)

---

## NOT VERIFIED

- Live re-run of Vivado `measure_lm06_ua_core.tcl` this session (reports + SHA re-derived only)  
- Full `get_cells` census of all 64 `u_a` RAMB36E1 (timing path-sampled; residual math used)  
- Board program of `arty_a7_ng_lm06_ua_soc.bit` + COM12 lm_path bit5 sample  
- Functional frozen LM-06 payload / TinyGPT forward vs synthetic tick smoke  
- XSim of SoC top (ABSENT; correctly not claimed)  
- Parallel `a7-vivado-gate` VERIFY_ONLY re-derive line (implementer + xsim-verify present; auditor independent re-derive covers numbers)
