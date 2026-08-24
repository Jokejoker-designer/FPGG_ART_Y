# AUDIT — tinygpt_soc (VERIFY_ONLY evidence auditor)

**Auditor:** `a7-evidence-auditor`  
**Mode:** VERIFY_ONLY (no RTL edit; **no LOOP_STATE flip**)  
**Date:** 2026-08-22  
**Evidence_class:** **POST_ROUTE_FIT_LIMIT** (two CONTROL post-route footprints + HS-11 additive BRAM bound) — **not** co-implemented TinyGPT+UA P&R, **not** HS-22 closed, **not** BOARD_PASS  
**GATE:** `tinygpt_soc`  
**LOOP_STATE:** `next` / first OPEN = `tinygpt_soc`  
**Implementer:** `a7-vivado-gate` (FALLBACK_AGENT; `pipeline.json` has no `tinygpt_soc` node) / `PASS_NARROW` / `fit_verdict=FAIL` / LIMIT  
**Parallel VERIFY:** `a7-vivado-gate` VERIFY_ONLY + `a7-ng-xsim-verify` (XSim ABSENT labeled)  
**CONTROL:** UA SoC `4451AFD9…BEA67F40E` (BRAM 128/135, headroom 7, DSP 0, WNS +0.244)  
**Refuse rule:** FAIL if BOARD_PASS self-declared, util>device sold as fit PASS, frozen overwrite, invented TinyGPT/`pe_alive` bit, or HS-22/§14 closed from this LIMIT alone.

```text
MUST_READ_UNBLOCK_H5: read. Next = ungated DIFF twin (not S2, not glue).
BLUEPRINT_LOOP: read. Goal=NATIVE_V1_MINI_AI_BOARD_PASS. Next=tinygpt_soc
```

---

## Verdict

```text
AUDIT: 2 FINDINGS
result: PASS_NARROW
allow_loop_done_eng: true
severity_metrics: CONTROL UA 4451AFD9 MATCH live; BRAM 128+132=260>135 LIMIT; headroom 7; TinyGPT hier 0 on UA; frozen LM/01R/02M/A0.3 MATCH; no new TinyGPT SoC bit; XSim ABSENT labeled; HS-22 OPEN; no BOARD_PASS; Evidence_class=POST_ROUTE_FIT_LIMIT
```

H_CANDIDATE (new TinyGPT/DSP + `pe_alive` bit **with** retained wt+u_a under BRAM≤135) **FALSIFIED** — **EVIDENCE** (additive HS-11 bound) + honest **LIMIT**.  
H_RIVAL (invent `pe_alive`; claim fit without fabric; overwrite frozen; sell 260>135 as PASS) **did not fire**.  
HS-22 silicon LM-on-answer-path / semantic HS-02 / §14 Native V1 **NOT closed** (finding).  
`NATIVE_V1_MINI_AI_BOARD_PASS` = **NOT EVIDENCED**.

**Do not declare BOARD_PASS.** **Do not flip LOOP_STATE** (orchestrator only).  
Orchestrator **may** mark `DONE_ENG` for this **narrow** honest-LIMIT unknown only (`allow_loop_done_eng: true`).

---

## Dispatch / loop law

| Check | Outcome |
|-------|---------|
| `LOOP_STATE.next` / first OPEN = `tinygpt_soc` | **PASS** |
| Implementer agent = `a7-vivado-gate` (FALLBACK) | **PASS** — DISPATCH_LOG; `pipeline.json` node absent → FALLBACK |
| Parallel VERIFY = `a7-vivado-gate` + `a7-ng-xsim-verify` VERIFY_ONLY | **PASS** — re-derive + XSim ABSENT labeled |
| Auditor this VERIFY = `a7-evidence-auditor` | **PASS** |
| Evidence_class mixed as BOARD / HS-22 PASS | **PASS** — LIMIT + `hs22_closed: false` + `board_pass: false` |
| Auditor VERIFY_ONLY (no LOOP flip) | **PASS** — this file |

---

## Independent re-derive (headline numbers)

| Metric | Claim | Auditor re-derive | Class |
|--------|------:|-------------------|-------|
| CONTROL UA SHA256 | `4451AFD9…BEA67F40E` | live SHA256 of `results/A7-NATIVE-GRAPH/LM06-UA/arty_a7_ng_lm06_ua_soc.bit` **MATCH**; repair bit **MATCH** | **EVIDENCE** |
| Frozen LM-06 SHA256 | `67C37DD5…4282E3BA` | live SHA256 of `build/out/arty_a7_lm06.bit` **MATCH** | **EVIDENCE** |
| Frozen 01R / 02M / A0.3 | MATCH | live rehash vs `frozen_sha_control.txt` EXPECT — all **MATCH** | **EVIDENCE** |
| UA BRAM / headroom | 128 / 7 | `control_ua_util.rpt` Block RAM Tile Used=128 Available=135 | **EVIDENCE** |
| UA LUT / FF / DSP | 7196 / 8091 / 0 | Slice LUTs / Slice Registers / DSPs | **EVIDENCE** |
| UA WNS / TNS / WHS / THS | +0.244 / 0 / +0.032 / 0 | `control_ua_timing_repair.rpt` L141 | **EVIDENCE** |
| LM-06 BRAM / DSP | 132 / 154 | `frozen_lm06_utilization_route.rpt` | **EVIDENCE** |
| LM-06 LUT / FF | 37555 / 35864 | Slice LUTs / Slice Registers | **EVIDENCE** |
| LM-06 WNS / TNS | +0.179 / 0 | `frozen_lm06_timing_route.rpt` L141 | **EVIDENCE** |
| Additive BRAM | 260 > 135 | 128+132=260; overshoot 125 | **ENGINEERING_INFERENCE** (HS-11 naive sum of two CONTROL footprints; not co-P&R) → **FAIL/LIMIT** |
| Additive DSP | 154 ≤ 240 | 0+154 | **ENGINEERING_INFERENCE**; irrelevant under BRAM FAIL |
| TinyGPT hier on UA | 0 | grep `tiny_gpt`/`tinygpt`/`mac_array`/`gemv`/`u_mac` → 0 | **EVIDENCE** (ABSENT LIMIT) |
| New TinyGPT SoC `.bit` | null / count=0 | `TINYGPT-SOC/*.bit` absent | **EVIDENCE** |
| XSim marker | ABSENT | VERIFY labeled; no invent | **EVIDENCE** |
| BOARD_PASS | false | GATE / LIMIT / VERIFY | **EVIDENCE** |
| HS-22 | OPEN | GATE / FIT_BUDGET / VERIFY | **EVIDENCE** |

### BRAM arithmetic (auditor)

```text
bram_ua     = 128   # control_ua_util.rpt Block RAM Tile
bram_lm06   = 132   # frozen_lm06_utilization_route.rpt (TinyGPT/LM-06 CONTROL footprint)
bram_sum    = 260
bram_device = 135
headroom_ua = 7
fit_with_wt_ua = (260 <= 135) = False   # HS-11 architectural FAIL → honest LIMIT
```

---

## Scientific frame (auditor)

| Slot | Declared | Auditor grade |
|------|----------|---------------|
| OBSERVATION | UA CONTROL BRAM128 headroom7; TinyGPT ABSENT; LM-06 BRAM132 | **EVIDENCE** |
| UNKNOWN | can TinyGPT fit with wt+u_a BRAM≤135 without frozen overwrite? | **Closed NO → PASS_NARROW/LIMIT** |
| H_CANDIDATE | new TinyGPT/DSP + pe_alive with wt+u_a | **FALSIFIED** (additive bound) |
| H_RIVAL | invent pe_alive; claim fit; overwrite frozen | **Did not fire** |
| FALSIFIER | util>device as PASS; BOARD_PASS; frozen SHA change | **Did not fire** |
| CONTROL | 4451AFD9…; frozen LM MATCH 67C37DD5… | **EVIDENCE** |
| UNIT | one post-route SoC composition (BRAM tiles), ≠ clock cycle | **EVIDENCE** |

---

## Findings

```
[MAJOR] PASS_NARROW LIMIT must not close HS-22 / §14 / full TinyGPT-on-answer-path
  where     : TINYGPT-SOC/GATE_tinygpt_soc.md;
              TINYGPT-SOC/LIMIT_tinygpt_bram_fit.md;
              docs/NATIVE_AI_ARTY_A7_BLUEPRINT/14_FINAL_ACCEPTANCE_CHECKLIST.md;
              LOOP_STATE tinygpt_soc / HS-22
  claim      : tinygpt_soc PASS_NARROW / allow_loop_done_eng
  evidence   : fit=FAIL LIMIT only; no new TinyGPT SoC bit; TinyGPT hier 0 on UA;
               GATE/VERIFY explicitly hs22_closed=false; §14 Teacher-off / Native V1 still OPEN
  why it matters: a reader could treat DONE_ENG as HS-22 silicon LM-on-answer-path PASS
  fix        : Keep PASS_NARROW + POST_ROUTE_FIT_LIMIT; leave HS-22/§14 OPEN until a real
               answer-path fit (or redesigned DDR/consolidation unknown) is evidenced
```

```
[MINOR] Additive 260 is HS-11 bound, not a co-implemented UA+TinyGPT post-route
  where     : TINYGPT-SOC/FIT_BUDGET_TINYGPT_SOC.json additive_fit;
              GATE / VERIFY evidence_class POST_ROUTE_FIT_LIMIT
  claim      : TinyGPT cannot fit with wt+u_a (BRAM 260>135)
  evidence   : 128 and 132 are each post-route EVIDENCE; sum is ENGINEERING_INFERENCE;
               no combined bitstream was placed/routed (new_tinygpt_soc_bit=null) — correctly LIMIT
  why it matters: skimmers may think a single P&R measured 260 BRAM rather than a CONTROL sum
  fix        : retain LIMIT; optionally label metric as additive_bound_bram in future gates;
               do not re-run impl solely for label
```

---

## Forbidden-route search (negative)

| Route | Status |
|-------|--------|
| Sell BRAM 260>135 as fit PASS | **Did not fire** — fit_verdict=FAIL / LIMIT |
| Invent TinyGPT / pe_alive / new SoC bit | **Did not fire** — bit_count=0; hier 0 |
| Frozen LM-06 / 01R / 02M / A0.3 overwrite | **Not found** — live SHA MATCH |
| Invent XSim marker | **Did not fire** — ABSENT labeled |
| BOARD_PASS self-declare | **Not declared** |
| Close HS-22 from this gate | **Blocked** — hs22_closed=false |
| Parent RTL write for this gate | **Not found** — vivado-gate fit archive only |

---

## PASS_NARROW acceptance (this VERIFY)

| Criterion (user LIMIT) | Met? |
|------------------------|------|
| TinyGPT cannot fit with wt+u_a (BRAM 260>135) | **YES** (re-derived) |
| CONTROL 4451AFD9 | **YES** (live MATCH) |
| Frozen MATCH | **YES** (LM/01R/02M/A0.3) |
| HS-22 stays OPEN | **YES** |
| Claimed PASS_NARROW allowed | **YES** (`allow_loop_done_eng: true`) |

---

## Explicit non-claims

- Not HS-22 silicon LM-on-answer-path  
- Not a co-placed UA+TinyGPT bitstream  
- Not semantic HS-02 / held-out retrieval  
- Not §14 Teacher-off / Native V1  
- Not `NATIVE_V1_MINI_AI_BOARD_PASS` / BOARD_PASS  
- Not XSim functional proof for TinyGPT-on-SoC  

---

## NOT VERIFIED

- Co-implementation P&R of any reduced/minimal answer core in the remaining 7 BRAM (NEEDS_EXPERIMENT; separate unknown — DDR/consolidation)  
- Board re-program with a TinyGPT-bearing SoC (none exists this gate)  
- Whether a non-LM-06 “minimal frozen-law” core could theoretically use ≤7 BRAM (not sized here; full LM-06 footprint 132 was the falsifier)

---

## Verdict lines

```text
AUDIT: 2 FINDINGS
tinygpt_soc = PASS_NARROW
Evidence_class = POST_ROUTE_FIT_LIMIT
LIMIT = TinyGPT+wt+u_a BRAM 260>135
CONTROL = 4451AFD9 MATCH
frozen = MATCH
HS-22 = OPEN
allow_loop_done_eng = true
board_pass = false
loop_flipped = false
NATIVE_V1_MINI_AI_BOARD_PASS = NOT EVIDENCED
```
