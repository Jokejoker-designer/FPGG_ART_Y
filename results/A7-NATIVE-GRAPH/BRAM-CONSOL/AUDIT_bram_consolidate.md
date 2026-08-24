# AUDIT — bram_consolidate (VERIFY_ONLY evidence auditor)

**Auditor:** `a7-evidence-auditor`  
**Mode:** VERIFY_ONLY (no RTL edit; **no LOOP_STATE flip**)  
**Date:** 2026-08-22  
**Evidence_class:** **POST_ROUTE_PROXY** (measured WM phase-share shared pool) + co-fit **ENGINEERING_INFERENCE** (`max(UA128,TinyGPT132)=132`) — **not** TinyGPT+UA answer-path SoC, **not** HS-22 closed, **not** BOARD_PASS  
**GATE:** `bram_consolidate`  
**LOOP_STATE:** `next` / first OPEN = `bram_consolidate`  
**Implementer:** `a7-ng-memory-arch` (`run_blueprint_loop.py` character_id) / `PASS_NARROW`  
**CONTROL:** UA `4451AFD9…BEA67F40E` (BRAM128); TinyGPT-SOC additive LIMIT 260; frozen LM-06 `67C37DD5…4282E3BA`; mig.prj `870FA6EE…52190D` AXI  
**Refuse rule:** FAIL if BOARD_PASS, util>135 sold as PASS, frozen overwrite, invent pe_alive, or HS-22/§14 closed from proxy alone.

```text
MUST_READ_UNBLOCK_H5: read. Next = ungated DIFF twin (not S2, not glue).
BLUEPRINT_LOOP: read. Goal=NATIVE_V1_MINI_AI_BOARD_PASS. Next=bram_consolidate
```

---

## Verdict

```text
AUDIT: 2 FINDINGS
result: PASS_NARROW
allow_loop_done_eng: true
severity_metrics: consol BRAM132/135 WNS+0.586 TNS0 SHA 83A438B5 MATCH; co-fit proj 132<=135 vs additive 260; frozen UA/LM06/mig MATCH; DSP0; HS-22 OPEN; no BOARD_PASS; Evidence_class=POST_ROUTE_PROXY
```

H_CANDIDATE (**co-fit path**): measured shared pool 132≤135 Prefer WNS≥0 — **SUPPORTED** as **capacity proxy** (**EVIDENCE** util/timing) + co-fit formula (**ENGINEERING_INFERENCE**).  
H_CANDIDATE (**headroom≥132 free tiles**): **NOT supported** — headroom_after=3 (honest).  
H_RIVAL (paper headroom; invent pe_alive; hand-edit mig.prj): **did not fire**.  
HS-22 TinyGPT-on-answer-path / §14 Native V1 / `NATIVE_V1_MINI_AI_BOARD_PASS` = **NOT EVIDENCED**.

**Do not declare BOARD_PASS.** **Do not flip LOOP_STATE** (orchestrator only).  
Orchestrator **may** mark `DONE_ENG` for this **narrow** capacity/co-fit-projection unknown only (`allow_loop_done_eng: true`).

---

## Dispatch / loop law

| Check | Outcome |
|-------|---------|
| `LOOP_STATE.next` / first OPEN = `bram_consolidate` | **PASS** |
| Implementer `agent` = `a7-ng-memory-arch` | **PASS** — DISPATCH_LOG + `run_blueprint_loop.py` map |
| Auditor this VERIFY = `a7-evidence-auditor` | **PASS** |
| Evidence_class sold as BOARD / HS-22 PASS | **PASS** — `hs22_closed:false`, `board_pass:false`, LIMIT docs |
| Auditor VERIFY_ONLY (no LOOP flip) | **PASS** — this file |

---

## Independent re-derive (headline numbers)

| Metric | Claim | Auditor re-derive | Class |
|--------|------:|-------------------|-------|
| Consol bit SHA256 | `83A438B5…0A7D3AEF` | live SHA256 of `BRAM-CONSOL/arty_a7_ng_bram_consol.bit` **MATCH** | **EVIDENCE** |
| Consol ≠ frozen LM-06 / UA | new path | `83A438B5…` ≠ `67C37DD5…` ≠ `4451AFD9…` | **EVIDENCE** |
| CONTROL UA SHA | `4451AFD9…` | live `LM06-UA/arty_a7_ng_lm06_ua_soc.bit` **MATCH** | **EVIDENCE** |
| Frozen LM-06 SHA | `67C37DD5…` | live `build/out/arty_a7_lm06.bit` **MATCH** | **EVIDENCE** |
| mig.prj SHA / AXI | `870FA6EE…` AXI; app_*=0 | live `vivado/ip/mig_7series_0/mig_7series_0/mig.prj` **MATCH**; `app_` hits=0 | **EVIDENCE** |
| Block RAM Tile | 132 / 135 (97.78%) | `consol_util.rpt` | **EVIDENCE** |
| RAMB36E1 / RAMB18 | 132 / 0 | util + Tcl log | **EVIDENCE** |
| WNS / TNS | +0.586 / 0.000 | `consol_timing.rpt` Design Timing Summary L140; clock `clk100` | **EVIDENCE** |
| WHS / THS | +0.069 / 0.000 | same | **EVIDENCE** |
| Slice LUTs (util) | — | **141** (`consol_util.rpt`) | **EVIDENCE** |
| LUT cells (Tcl) | 153 | `get_cells REF_NAME=~LUT*` in measure TCL / log | **EVIDENCE** (different metric) |
| FF / DSP | 23 / 0 | util Slice Registers / DSPs; Tcl FF=23 DSP=0 | **EVIDENCE** |
| Additive CONTROL | 128+132=260 | TinyGPT-SOC LIMIT (prior gate) | **ENGINEERING_INFERENCE** (retained CONTROL) |
| Co-fit projection | 132 = max(128,132) | formula + measured pool size 132 | **ENGINEERING_INFERENCE** + measured pool **EVIDENCE** |
| Headroom after | 3 | 135−132 | **EVIDENCE** |
| Prefer ≤130 | false | 132>130 documented | **EVIDENCE** |
| BOARD_PASS / HS-22 closed | false / false | GATE / FIT_BUDGET / LIMIT / VERDICT | **EVIDENCE** |

### Auditor arithmetic

```text
bram_consol     = 132   # consol_util.rpt Block RAM Tile
bram_device     = 135
wns_ns          = +0.586
tns_ns          = 0.000
additive_ctrl   = 128 + 132 = 260   # prior TinyGPT-SOC LIMIT (unchanged)
cofit_proj      = max(128, 132) = 132
cofit_ok_device = (132 <= 135) = True
headroom_after  = 135 - 132 = 3
headroom_ge_132 = False
prefer_le_130   = False
sha_consol      = 83A438B5342446C9E79A537196777B1BCF2468FC57F9379EA2CB8EFE0A7D3AEF  # MATCH
```

RTL inspected: `a7ng_bram_consol*.sv` — forced `RAMB36E1`×132 + owner FSM (GRAPH/HOLD/LM); no TinyGPT MAC/DSP, no UART answer path, no pe_alive invent, mig untouched.

---

## Scientific frame (auditor)

| Slot | Declared | Auditor grade |
|------|----------|---------------|
| OBSERVATION | TinyGPT+UA additive 260>135 | **EVIDENCE** (prior LIMIT) |
| UNKNOWN | one consol frees enough for proj ≤135 Prefer WNS≥0 w/o frozen overwrite? | **Closed YES (narrow co-fit path)** |
| H_CANDIDATE | headroom≥132 **or** co-fit PASS_NARROW | co-fit **SUPPORTED** (proxy); headroom path **NOT** |
| H_RIVAL | paper / pe_alive / mig edit | **Did not fire** |
| FALSIFIER | frozen overwrite; BOARD_PASS; util>135 as PASS | **Did not fire** |
| CONTROL | UA 4451AFD9; TinyGPT LIMIT; mig MATCH | **EVIDENCE** |
| UNIT | one post-route composition (BRAM tiles) ≠ clock cycle | **EVIDENCE** |
| LEVER | WM phase-share wt+act → shared pool 132 | **EVIDENCE** (RTL+P&R); not DDR spill |

---

## Findings

```
[MAJOR] PASS_NARROW proxy must not close HS-22 / TinyGPT answer-path / §14
  where     : BRAM-CONSOL/GATE_bram_consolidate.md;
              BRAM-CONSOL/LIMIT_bram_consolidate.md;
              rtl/native_graph/memory/a7ng_bram_consol.sv (LUT~141, DSP=0);
              LOOP_STATE bram_consolidate / HS-22
  claim      : PASS_NARROW co-fit capacity collapses additive 260
  evidence   : measured design is empty shared RAMB36×132 + glue FSM;
               no TinyGPT MAC/DSP, no UA fabric, no UART answer path;
               GATE/LIMIT explicitly hs22_closed=false; co-fit is
               ENGINEERING_INFERENCE under exclusive phase ownership
  why it matters: a reader could treat DONE_ENG as HS-22 silicon LM-on-answer-path
               or as a co-placed TinyGPT+UA SoC
  fix        : Keep PASS_NARROW + POST_ROUTE_PROXY; leave HS-22/§14 OPEN until a
               real answer-path (or DDR-spill) fit is evidenced; do not upgrade
               co-fit projection to SoC PASS
```

```
[MINOR] LUT 153 (Tcl cell count) ≠ Slice LUTs 141 (util.rpt)
  where     : vivado/tcl/native_graph/measure_bram_consolidate.tcl LUT* get_cells;
              BRAM-CONSOL/METRICS.json lut_cells=153;
              BRAM-CONSOL/consol_util.rpt Slice LUTs=141
  claim      : GATE table LUT=153
  evidence   : Tcl counts primitive LUT cells (153); util reports combined Slice LUTs (141);
               FF=23 and BRAM/WNS claims unaffected
  why it matters: skimmers may think util.rpt disagrees with the gate table
  fix        : label as lut_cells vs slice_luts in future FIT_BUDGET; no re-impl required
```

---

## Forbidden-route search (negative)

| Route | Status |
|-------|--------|
| Sell util>135 as PASS | **Did not fire** — 132≤135 |
| Sell Prefer≤130 as met | **Did not fire** — prefer_le_130=false documented |
| Invent pe_alive / TinyGPT answer path | **Did not fire** — proxy only; DSP=0 |
| Frozen LM-06 / UA overwrite | **Not found** — consol bit new path; live SHA MATCH |
| Hand-edit mig.prj / native app_* | **Not found** — SHA MATCH; PortInterface AXI; app_=0 |
| BOARD_PASS self-declare | **Not declared** |
| Close HS-22 from this gate | **Blocked** — hs22_closed=false |
| Headroom≥132 claimed without evidence | **Blocked** — headroom_after=3; co-fit path only |
| Parent RTL write without Task | **Not found** — DISPATCH implementer = memory-arch |

---

## PASS_NARROW acceptance (this VERIFY)

| Criterion (user PASS_NARROW) | Met? |
|------------------------------|------|
| WM phase-share proxy BRAM132 WNS+0.586 | **YES** (re-derived) |
| Co-fit capacity vs additive 260 | **YES** (proj 132≤135; additive CONTROL retained) |
| HS-22 OPEN | **YES** |
| Not answer-path TinyGPT | **YES** (proxy; DSP0; LIMIT) |
| Claimed PASS_NARROW allowed | **YES** (`allow_loop_done_eng: true`) |

---

## Explicit non-claims

- Not HS-22 silicon LM-on-answer-path  
- Not co-placed TinyGPT+UA+DSP SoC bitstream  
- Not Digilent MIG DDR spill silicon (lever = WM share; mig untouched)  
- Not Prefer≤130 soft target met  
- Not headroom≥132 free tiles  
- Not semantic HS-02 / §14 Teacher-off / Native V1  
- Not `NATIVE_V1_MINI_AI_BOARD_PASS` / BOARD_PASS  

---

## NOT VERIFIED

- Parallel `a7-vivado-gate` / `a7-ng-xsim-verify` DISPATCH lines for this gate (absent at audit time; auditor re-derived util/timing/SHA from disk)  
- XSim functional TB for owner FSM / dual_owner_err (ABSENT; not claimed)  
- Full SoC P&R of TinyGPT + shared-pool wiring + UART pe_alive (NEEDS_EXPERIMENT; HS-22)  
- Whether DDR spill of residual banks can meet Prefer≤130 (separate unknown)  
- Board program of consol proxy (not claimed; evidence_class POST_ROUTE_PROXY)

---

## Verdict lines

```text
AUDIT: 2 FINDINGS
bram_consolidate = PASS_NARROW
Evidence_class = POST_ROUTE_PROXY
consol = BRAM132 WNS+0.586 TNS0 SHA83A438B5 MATCH
cofit_proj = 132 <= 135 (vs additive 260)
HS-22 = OPEN
allow_loop_done_eng = true
board_pass = false
loop_flipped = false
NATIVE_V1_MINI_AI_BOARD_PASS = NOT EVIDENCED
```
