# VERIFY_ONLY: tinygpt_consol (a7-ng-xsim-verify)

**Mode:** VERIFY_ONLY  
**Result:** **PASS_NARROW** (confirm) — honest **LIMIT**; no invented TinyGPT bit; frozen **MATCH**; **HS-22 OPEN**  
**fit_verdict:** **FAIL** (TinyGPT/DSP/pe_alive ABSENT on consol CONTROL; naive additive BRAM 264>135)  
**Not claimed:** HS-22 closed, TinyGPT answer-path SoC bit, pe_alive, BOARD_PASS, Native V1, XSim functional pass, cofit proj as TinyGPT fabric  
**XSim marker:** **ABSENT** (`tests/xsim/native_graph` missing; no `A7NG_*_XSIM_PASS`)  
**Evidence class:** `POST_ROUTE_FIT_LIMIT` (implementer); XSim N/A  
**ts_utc:** 2026-08-22T02:54:59Z

## Scientific frame (verify)

| Field | Value |
|-------|-------|
| OBSERVATION | vivado-gate PASS_NARROW LIMIT; consol CONTROL BRAM132 DSP0 TinyGPT hier0; new bit null; frozen MATCH claimed |
| UNKNOWN | Independent confirm: LIMIT honesty? no invented TinyGPT bit? frozen MATCH? HS-22 inflate? |
| H_CANDIDATE | Re-read util/timing + live rehash → TinyGPT ABSENT; null bit; MATCH; hs22_closed=false; stay PASS_NARROW |
| H_RIVAL | Invent TinyGPT consol .bit; sell cofit proj132 as TinyGPT; close HS-22; invent A7NG_*_XSIM_PASS; overwrite frozen |
| FALSIFIER | new .bit forged; hier TinyGPT>0 sold as PASS; frozen MATCH=False; hs22_closed=true; BOARD_PASS |
| UNIT | post-route util/timing + live SHA (≠ query cycles) |
| CONTROL | consol 83A438B5…; UA 4451AFD9…; frozen LM-06 67C37DD5… + 01R/02M/A0.3; mig.prj 870FA6EE… |
| METRICS | bram_consol/lm06, dsp, naive_additive, cofit_proj, tinygpt_hier, new_bit, frozen_match, hs22_closed |

## LIMIT honesty (required)

| Claim surface | Verdict |
|---------------|---------|
| TinyGPT / DSP / pe_alive on consol CONTROL | **ABSENT LIMIT** — hier hits **0**; DSP **0/240** |
| New TinyGPT+consol SoC bitstream | **null** — **0** `.bit` under `TINYGPT-CONSOL/`; no `*tinygpt*consol*.bit` invented |
| Naive additive consol+LM06 BRAM | **132+132=264 > 135** — honest **FAIL** if stacked without share |
| Co-fit projection 132≤135 | **ENGINEERING_INFERENCE** only (prior BRAM-CONSOL) — **not** TinyGPT evidence |
| Consol headroom for additive TinyGPT bank | **3** tiles — cannot ADD LM-06 TinyGPT BRAM132 |
| Sell consol capacity proxy as TinyGPT / HS-22 | **REFUSED** |

Primary LIMIT artifact: `LIMIT_tinygpt_consol.md` — **consistent** with util + SHA + null bit.

## Re-derived checks

| Check | Measured | Verdict |
|-------|----------|---------|
| control_consol_util.rpt Block RAM Tile | **132 / 135** (97.78%) | MATCH gate |
| control_consol_util.rpt RAMB36E1 / RAMB18 | **132 / 0** | MATCH |
| control_consol_util.rpt DSP | **0 / 240** | MATCH ABSENT |
| control_consol_util.rpt Slice LUTs / FF | **141 / 23** | MATCH |
| TinyGPT hier (`tiny_gpt`/`mac_array`/`gemv`/`pe_alive`) | **0** hits | MATCH ABSENT |
| control_consol_timing.rpt WNS/TNS | **0.586 / 0.000** | MATCH |
| control_consol_timing.rpt WHS/THS | **0.069 / 0.000** | MATCH |
| frozen_lm06 util BRAM / DSP | **132 / 154** | MATCH footprint CONTROL |
| frozen_lm06 timing WNS/TNS | **0.179 / 0.000** | MATCH (standalone ≠ consol SoC) |
| Naive additive BRAM | **264 / 135** | MATCH LIMIT FAIL arithmetic |
| Co-fit proj | **132** (not sold as TinyGPT) | HONEST label retained |
| New TinyGPT+consol .bit | **null** (0 files) | **NO INVENT** |
| Consol CONTROL live SHA | `83A438B5…A7D3AEF` | **MATCH** |
| CONTROL UA live SHA | `4451AFD9…EA67F40E` | **MATCH** |
| Frozen LM-06 / 01R / 02M / A0.3 | all MATCH | **MATCH** (HS-20) |
| mig.prj live SHA | `870FA6EE…52190D` | **MATCH** |
| XSim TB / `A7NG_*_XSIM_PASS` | ABSENT | not invented |
| BOARD_PASS / HS-22 closed | false / **OPEN** | **REFUSED inflate** |
| RTL / golden / frozen bits edited this verify | No (read-only + verify artifacts) | PASS |

Live rehash → `frozen_sha_verify.txt` (`FROZEN_ALL_MATCH=True`).

## Explicit non-claims

- No XSim functional proof for TinyGPT-on-consol  
- No HS-22 silicon LM-on-answer-path / pe_alive  
- No new integrated TinyGPT+shared-pool bitstream  
- No BOARD_PASS / Native V1 / §14 close  
- No LOOP_STATE flip by this verifier (orchestrator / evidence-auditor)

## Artifacts consulted (read-only)

- `GATE_tinygpt_consol.md`, `LIMIT_tinygpt_consol.md`, `LIMIT_tinygpt_soc_prior.md`
- `FIT_BUDGET_TINYGPT_CONSOL.json`, `METRICS.json`, `VERDICT.txt`, `SHA256.txt`, `frozen_sha_control.txt`
- `control_consol_util.rpt`, `control_consol_util_hier.rpt`, `control_consol_timing.rpt`
- `frozen_lm06_utilization_route.rpt`, `frozen_lm06_timing_route.rpt`
- Live rehash → `frozen_sha_verify.txt` (this verify)
