# VERIFY_ONLY: tinygpt_soc (a7-ng-xsim-verify)

**Mode:** VERIFY_ONLY  
**Result:** **PASS_NARROW** (confirm) — additive BRAM **260 > 135** LIMIT honest; frozen MATCH; **no invented TinyGPT bit**  
**Not claimed:** HS-22 closed, semantic HS-02, BOARD_PASS, new TinyGPT/DSP SoC bit, XSim functional pass  
**XSim marker:** **ABSENT** (no TB under `tests/xsim/native_graph` for this fit gate; no `A7NG_*_XSIM_PASS`)  
**Evidence class:** POST_ROUTE_FIT_LIMIT (vivado-gate); XSim N/A  
**ts_utc:** 2026-08-22T02:21:08Z

## Scientific frame (verify)

| Field | Value |
|-------|-------|
| OBSERVATION | vivado-gate PASS_NARROW LIMIT; UA BRAM=128 headroom=7; LM-06 BRAM=132 DSP=154; TinyGPT hier ABSENT on UA; `TINYGPT-SOC/*.bit` count=0 |
| UNKNOWN | Independent confirm: additive BRAM honesty? frozen MATCH? invent TinyGPT bit / XSim / BOARD_PASS? |
| H_CANDIDATE | Live rehash frozen+CONTROL MATCH; re-read util → 128+132=260>135; bit_count=0; stay PASS_NARROW LIMIT; HS-22 OPEN |
| H_RIVAL | Invent TinyGPT SoC bit; sell util>device as PASS; invent A7NG_*_XSIM_PASS; overwrite frozen; claim BOARD_PASS / HS-22 closed |
| FALSIFIER | BRAM math ≠ reports; any frozen MATCH=False; new `.bit` under TINYGPT-SOC; XSim marker without TB |
| UNIT | post-route util/timing + live SHA (≠ clock cycles / query bags) |
| CONTROL | UA `4451AFD9…`; frozen LM-06 `67C37DD5…` + 01R/02M/A0.3 |
| METRICS | bram_ua, bram_lm06, bram_sum, dsp_*, wns/tns, frozen_match, tinygpt_hier_hits, new_bit_count, board_pass |

## Re-derived checks

| Check | Measured | Verdict |
|-------|----------|---------|
| `control_ua_util.rpt` Block RAM Tile | **128 / 135** (headroom **7**) | MATCH gate |
| `control_ua_util.rpt` DSP / LUT / FF | **0 / 7196 / 8091** | MATCH gate |
| `control_ua_timing_repair.rpt` WNS/TNS/WHS/THS | **0.244 / 0.000 / 0.032 / 0.000** | MATCH gate |
| `frozen_lm06_utilization_route.rpt` BRAM / DSP | **132 / 154** | MATCH gate |
| `frozen_lm06_timing_route.rpt` WNS/TNS | **0.179 / 0.000** | MATCH gate |
| Additive BRAM | **128 + 132 = 260** vs device **135** (overshoot **125**) | **FAIL → LIMIT** honest |
| Additive DSP | **0 + 154 = 154** vs **240** | OK alone; irrelevant under BRAM FAIL |
| TinyGPT hier on UA util/timing (`tiny_gpt`/`tinygpt`/`mac_array`/`gemv`/`u_mac`/`pe_alive`) | **0 hits** each | **ABSENT LIMIT** |
| New TinyGPT SoC `.bit` under `TINYGPT-SOC/` | **count=0** | **no invent** |
| CONTROL UA live SHA | `4451AFD9…EA67F40E` | **MATCH** |
| Repair bit live SHA | same `4451AFD9…` | **MATCH** |
| Frozen LM-06 / 01R / 02M / A0.3 live SHA | all MATCH | **MATCH** (HS-20) |
| XSim TB / `A7NG_*_XSIM_PASS` | ABSENT | not invented |
| BOARD_PASS / HS-22 closed | false / OPEN | **REFUSED inflate** |
| RTL / golden / frozen bits edited this verify | No | PASS |

## Artifacts consulted (read-only)

- `GATE_tinygpt_soc.md`, `GATE_tinygpt_soc_vivado_verify.md`, `LIMIT_tinygpt_bram_fit.md`
- `FIT_BUDGET_TINYGPT_SOC.json`, `frozen_sha_control.txt`
- `control_ua_util.rpt`, `control_ua_util_repair.rpt`, `control_ua_timing_repair.rpt`
- `frozen_lm06_utilization_route.rpt`, `frozen_lm06_timing_route.rpt`
- Live rehash → `frozen_sha_verify.txt` (this verify)

## Explicit non-claims

- No XSim functional proof for TinyGPT-on-SoC  
- No new bitstream with TinyGPT/DSP/`pe_alive`  
- No HS-22 silicon LM-on-answer-path closed  
- No semantic HS-02 / held-out retrieval  
- No Native V1 BOARD_PASS  
- No LOOP_STATE flip by this verifier (orchestrator / evidence-auditor)
