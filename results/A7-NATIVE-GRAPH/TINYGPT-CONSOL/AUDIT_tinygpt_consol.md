# AUDIT — tinygpt_consol (VERIFY_ONLY evidence auditor)

**Auditor:** `a7-evidence-auditor`  
**Mode:** VERIFY_ONLY (no RTL edit; **no LOOP_STATE flip**)  
**Date:** 2026-08-22  
**Evidence_class:** **POST_ROUTE_FIT_LIMIT** (consol CONTROL + frozen LM-06 CONTROL footprints + HS-11 naive additive BRAM) — **not** TinyGPT+consol SoC bit, **not** HS-22 closed, **not** BOARD_PASS  
**GATE:** `tinygpt_consol`  
**LOOP_STATE:** `next` / first OPEN = `tinygpt_consol`  
**Implementer:** `a7-vivado-gate` (`run_blueprint_loop.py` FALLBACK map) / `PASS_NARROW` / `fit_verdict=FAIL` / LIMIT  
**CONTROL:** consol `83A438B5…0A7D3AEF` (BRAM132/135 DSP0); UA `4451AFD9…BEA67F40E`; frozen LM-06 `67C37DD5…4282E3BA`  
**Refuse rule:** FAIL if BOARD_PASS, util>135 sold as fit PASS, frozen overwrite, invent pe_alive / TinyGPT-on-consol, sell cofit_proj as TinyGPT, or close HS-22/§14 from this LIMIT alone.

```text
MUST_READ_UNBLOCK_H5: read. Next = ungated DIFF twin (not S2, not glue).
BLUEPRINT_LOOP: read. Goal=NATIVE_V1_MINI_AI_BOARD_PASS. Next=tinygpt_consol
```

---

## Verdict

```text
AUDIT: 2 FINDINGS
result: PASS_NARROW
allow_loop_done_eng: true
severity_metrics: consol CONTROL 83A438B5 MATCH live; DSP=0 TinyGPT hier=0 ABSENT; naive additive 132+132=264>135; cofit_proj 132 ENGINEERING_INFERENCE not TinyGPT; no new TinyGPT+consol bit; frozen LM/01R/02M/A0.3/UA/mig MATCH; HS-22 OPEN; no BOARD_PASS; Evidence_class=POST_ROUTE_FIT_LIMIT
```

H_CANDIDATE (new TinyGPT/DSP + consol bit with pe_alive, BRAM≤135 WNS≥0) **FALSIFIED / ABSENT** — **EVIDENCE** (consol DSP0/hier0; new_bit=null) + naive additive **ENGINEERING_INFERENCE** 264>135 → honest **LIMIT**.  
H_RIVAL (invent pe_alive; sell capacity/cofit as TinyGPT; overwrite frozen; sell 264>135 as PASS) **did not fire**.  
HS-22 silicon LM-on-answer-path / §14 Native V1 / `NATIVE_V1_MINI_AI_BOARD_PASS` = **NOT EVIDENCED**.

**Do not declare BOARD_PASS.** **Do not flip LOOP_STATE** (orchestrator only).  
Orchestrator **may** mark `DONE_ENG` for this **narrow** honest-LIMIT unknown only (`allow_loop_done_eng: true`).

---

## Dispatch / loop law

| Check | Outcome |
|-------|---------|
| `LOOP_STATE.next` / first OPEN = `tinygpt_consol` | **PASS** |
| Implementer `agent` = `a7-vivado-gate` | **PASS** — DISPATCH_LOG L139; `run_blueprint_loop.py` map `"tinygpt_consol": "a7-vivado-gate"` |
| Auditor this VERIFY = `a7-evidence-auditor` | **PASS** |
| Evidence_class sold as BOARD / HS-22 PASS | **PASS** — `hs22_closed:false`, `board_pass:false`, LIMIT docs |
| Auditor VERIFY_ONLY (no LOOP flip) | **PASS** — this file |

---

## Independent re-derive (headline numbers)

| Metric | Claim | Auditor re-derive | Class |
|--------|------:|-------------------|-------|
| CONTROL consol SHA256 | `83A438B5…0A7D3AEF` | live SHA256 of `BRAM-CONSOL/arty_a7_ng_bram_consol.bit` **MATCH** | **EVIDENCE** |
| CONTROL UA SHA256 | `4451AFD9…BEA67F40E` | live `LM06-UA/arty_a7_ng_lm06_ua_soc.bit` **MATCH** | **EVIDENCE** |
| Frozen LM-06 SHA256 | `67C37DD5…4282E3BA` | live `build/out/arty_a7_lm06.bit` **MATCH** | **EVIDENCE** |
| Frozen 01R / 02M / A0.3 / mig | MATCH | `SHA256.txt` / `frozen_sha_control.txt` EXPECT lines | **EVIDENCE** (file-backed; live consol/UA/LM06 rehashed) |
| Consol BRAM / headroom | 132 / 3 | `control_consol_util.rpt` Block RAM Tile 132/135 | **EVIDENCE** |
| Consol LUT / FF / DSP | 141 / 23 / **0** | Slice LUTs / Slice Registers / DSPs | **EVIDENCE** |
| Consol WNS / TNS / WHS / THS | +0.586 / 0 / +0.069 / 0 | `control_consol_timing.rpt` Design Timing Summary L141 | **EVIDENCE** |
| TinyGPT hier on consol | **0** | `control_consol_util_hier.rpt`: only `a7ng_bram_consol_top` / `u_consol`; grep `tiny_gpt`/`mac_array`/`gemv`/`pe_alive`/`TinyGPT` = 0 | **EVIDENCE** (ABSENT LIMIT) |
| LM-06 BRAM / DSP | 132 / 154 | `frozen_lm06_utilization_route.rpt` | **EVIDENCE** |
| LM-06 LUT / FF | 37555 / 35864 | same | **EVIDENCE** |
| LM-06 WNS / TNS | +0.179 / 0 | `frozen_lm06_timing_route.rpt` L141 | **EVIDENCE** (standalone CONTROL; ≠ consol SoC) |
| Naive additive BRAM | **264 > 135** | 132+132=264; overshoot 129 | **ENGINEERING_INFERENCE** (HS-11 sum of two CONTROL footprints) → **FAIL/LIMIT** |
| Co-fit projection | 132 = max(132,132) | prior BRAM-CONSOL formula | **ENGINEERING_INFERENCE** — **not** TinyGPT evidence |
| New TinyGPT+consol `.bit` | null | `TINYGPT-CONSOL/*.bit` count=0 | **EVIDENCE** |
| pe_alive invented | no | hier 0; no UART invent | **EVIDENCE** |
| BOARD_PASS / HS-22 closed | false / false | GATE / LIMIT / METRICS / VERDICT / FIT_BUDGET | **EVIDENCE** |

### Auditor arithmetic

```text
bram_consol         = 132   # control_consol_util.rpt Block RAM Tile
dsp_consol          = 0     # DSPs Used=0
bram_lm06           = 132   # frozen_lm06_utilization_route.rpt
dsp_lm06            = 154
naive_additive_bram = 132 + 132 = 264
bram_device         = 135
bram_ok_naive       = (264 <= 135) = False   # HS-11 FAIL → honest LIMIT
cofit_proj          = max(132, 132) = 132    # ENGINEERING_INFERENCE only
cofit_ok_device     = (132 <= 135) = True    # NOT TinyGPT fabric evidence
headroom_consol     = 135 - 132 = 3
tinygpt_hier_hits   = 0
new_tinygpt_consol_bit = null
sha_consol          = 83A438B5342446C9E79A537196777B1BCF2468FC57F9379EA2CB8EFE0A7D3AEF  # MATCH live
```

Hier design name: `a7ng_bram_consol_top` — empty shared RAMB36×132 + glue; **no** TinyGPT MAC/DSP, **no** pe_alive.

---

## Scientific frame (auditor)

| Slot | Declared | Auditor grade |
|------|----------|---------------|
| OBSERVATION | consol proxy BRAM132 WNS+0.586 DSP0; TinyGPT ABSENT; prior TinyGPT-SOC additive LIMIT | **EVIDENCE** |
| UNKNOWN | can TinyGPT instantiate on consol BRAM≤135 WNS≥0 with named fabric/pe_alive? | **Closed NO → PASS_NARROW/LIMIT** |
| H_CANDIDATE | new TinyGPT+consol bit | **FALSIFIED / ABSENT** |
| H_RIVAL | pe_alive invent; cofit sold as TinyGPT; overwrite frozen | **Did not fire** |
| FALSIFIER | util>135 as PASS; BOARD_PASS; frozen SHA change | **Did not fire** |
| CONTROL | consol 83A438B5; UA 4451AFD9; TinyGPT-SOC LIMIT; LM-06 MATCH | **EVIDENCE** |
| UNIT | one post-route composition (BRAM tiles / named fabric) ≠ clock cycle | **EVIDENCE** |

---

## Findings

```
[MAJOR] PASS_NARROW LIMIT must not close HS-22 / TinyGPT answer-path / §14
  where     : TINYGPT-CONSOL/GATE_tinygpt_consol.md;
              TINYGPT-CONSOL/LIMIT_tinygpt_consol.md;
              docs/NATIVE_AI_ARTY_A7_BLUEPRINT/14_FINAL_ACCEPTANCE_CHECKLIST.md;
              LOOP_STATE tinygpt_consol / HS-22
  claim      : tinygpt_consol PASS_NARROW / allow_loop_done_eng
  evidence   : fit=FAIL LIMIT; consol DSP=0 TinyGPT hier=0; new_bit=null;
               GATE/LIMIT explicitly hs22_closed=false; §14 Teacher-off / Native V1 still OPEN
  why it matters: a reader could treat DONE_ENG as HS-22 silicon LM-on-answer-path PASS
  fix        : Keep PASS_NARROW + POST_ROUTE_FIT_LIMIT; leave HS-22/§14 OPEN until a real
               TinyGPT+shared-pool SoC P&R (or redesigned unknown) is evidenced
```

```
[MINOR] Additive 264 and cofit_proj 132 are not a measured TinyGPT+consol co-P&R
  where     : TINYGPT-CONSOL/FIT_BUDGET_TINYGPT_CONSOL.json fit_arithmetic;
              GATE / METRICS evidence_class POST_ROUTE_FIT_LIMIT
  claim      : TinyGPT cannot stack on consol (264>135); cofit_proj 132≤135
  evidence   : 132 and 132 are each post-route EVIDENCE; sum and max() are
               ENGINEERING_INFERENCE; no combined bitstream (new_bit=null) — correctly LIMIT;
               FIT_BUDGET labels cofit_class ENGINEERING_INFERENCE_from_bram_consolidate_not_TinyGPT_evidence
  why it matters: skimmers may treat 264 as one P&R util or treat cofit 132 as TinyGPT fitted
  fix        : retain LIMIT; do not sell cofit_proj as TinyGPT; no invent bit for label
```

---

## Forbidden-route search (negative)

| Route | Status |
|-------|--------|
| Sell BRAM 264>135 as fit PASS | **Did not fire** — fit_verdict=FAIL / LIMIT |
| Sell cofit_proj 132 as TinyGPT | **Did not fire** — labeled ENGINEERING_INFERENCE; TinyGPT ABSENT |
| Invent TinyGPT / pe_alive / new SoC bit | **Did not fire** — bit_count=0; hier 0; DSP 0 |
| Frozen LM-06 / 01R / 02M / A0.3 overwrite | **Not found** — live SHA MATCH (consol/UA/LM06) |
| BOARD_PASS self-declare | **Not declared** |
| Close HS-22 from this gate | **Blocked** — hs22_closed=false |
| Parent RTL write for this gate | **Not found** — vivado-gate fit archive only |

---

## PASS_NARROW acceptance (this VERIFY)

| Criterion (user LIMIT) | Met? |
|------------------------|------|
| No TinyGPT+consol SoC bit | **YES** (null / *.bit=0) |
| Consol DSP=0 TinyGPT ABSENT | **YES** (util + hier) |
| Additive 264>135 | **YES** (re-derived) |
| Cofit proj not sold as TinyGPT | **YES** (labeled ENGINEERING_INFERENCE) |
| HS-22 OPEN | **YES** |
| Claimed PASS_NARROW allowed | **YES** (`allow_loop_done_eng: true`) |

---

## Explicit non-claims

- Not HS-22 silicon LM-on-answer-path / pe_alive  
- Not a co-placed TinyGPT+consol bitstream  
- Not semantic HS-02 / held-out retrieval  
- Not §14 Teacher-off / Native V1  
- Not `NATIVE_V1_MINI_AI_BOARD_PASS` / BOARD_PASS  
- Not cofit_proj as measured TinyGPT fabric  

---

## NOT VERIFIED

- Real TinyGPT+shared-pool SoC place-and-route under exclusive phase ownership (NEEDS_EXPERIMENT; separate implementer unknown)  
- Board re-program with a TinyGPT-bearing consol SoC (none exists this gate)  
- Whether a reduced non-LM-06 answer core could fit in headroom 3 (not sized; full LM-06 footprint 132 was the falsifier for additive stack)  
- Live rehash of frozen 01R/02M/A0.3/mig this session (file-backed MATCH in SHA256.txt; consol/UA/LM06 live-verified)

---

## Verdict lines

```text
AUDIT: 2 FINDINGS
tinygpt_consol = PASS_NARROW
Evidence_class = POST_ROUTE_FIT_LIMIT
LIMIT = TinyGPT ABSENT on consol; naive 264>135; cofit_proj not TinyGPT
CONTROL_consol = 83A438B5 MATCH
frozen = MATCH
HS-22 = OPEN
allow_loop_done_eng = true
board_pass = false
loop_flipped = false
NATIVE_V1_MINI_AI_BOARD_PASS = NOT EVIDENCED
```
