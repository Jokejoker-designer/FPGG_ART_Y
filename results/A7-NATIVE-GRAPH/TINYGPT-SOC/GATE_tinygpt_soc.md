# GATE: tinygpt_soc — PASS_NARROW / LIMIT — 2026-08-22

```text
GATE: tinygpt_soc
UNKNOWN: can_TinyGPT_fit_with_wt_ua_BRAM_le_135
TESTS: post-route util/timing CONTROL UA + frozen LM-06; live SHA256 MATCH; hier TinyGPT ABSENT
EXPECTED: new bit TinyGPT/DSP+pe_alive OR honest LIMIT if device full; frozen MATCH; no BOARD_PASS
ACTUAL: additive BRAM 260>135; headroom 7; TinyGPT ABSENT on UA; frozen MATCH; no new TinyGPT SoC bit
PASS/FAIL: PASS_NARROW (fit=FAIL / LIMIT)
ARTIFACT: results/A7-NATIVE-GRAPH/TINYGPT-SOC/GATE_tinygpt_soc.md
SHA256: 4451AFD9B07D8FF52791CCBF6338862FF36B721DF9FBB9BD19EC726BEA67F40E (CONTROL UA; no new TinyGPT bit)
```

## Scientific frame

| Slot | Value |
|------|-------|
| OBSERVATION | UA SoC has weights+u_a+PE but no TinyGPT/DSP answer path; BRAM headroom ≈7 |
| UNKNOWN | can TinyGPT (or minimal frozen-law answer/core path) fit with WNS≥0 TNS=0 BRAM≤135 without overwriting frozen LM-06 release bit? |
| H_CANDIDATE | new bit with named TinyGPT/DSP or documented equivalent + pe_alive path |
| H_RIVAL | invent pe_alive; claim fit without fabric; overwrite frozen |
| FALSIFIER | util > device sold as PASS; BOARD_PASS; frozen SHA change |
| CONTROL | 4451AFD9…; frozen LM MATCH 67C37DD5… |
| UNIT | one post-route SoC composition (BRAM tiles), ≠ clock cycle |
| METRICS | bram_ua, bram_lm06, bram_sum, dsp_sum, wns/tns both controls, frozen_match, tinygpt_hier_hits |

## Measured (post-route provenance)

| Metric | Value | Provenance | Gate |
|--------|------:|------------|------|
| CONTROL UA SHA256 | `4451AFD9…EA67F40E` | live Get-FileHash LM06-UA + repair | **MATCH** |
| UA WNS / TNS | +0.244 / 0.000 | `control_ua_timing_repair.rpt` L141 | **PASS** (CONTROL retained) |
| UA WHS / THS | +0.032 / 0.000 | same | **PASS** |
| UA LUT / FF / DSP | 7196 / 8091 / 0 | `control_ua_util.rpt` | CONTROL |
| UA Block RAM | **128 / 135** (headroom **7**) | util | CONTROL |
| TinyGPT hier on UA | **0** | hier grep | **ABSENT LIMIT** |
| Frozen LM-06 SHA256 | `67C37DD5…4282E3BA` | `build/out/arty_a7_lm06.bit` | **MATCH** (HS-20) |
| LM-06 LUT / FF | 37555 / 35864 | `frozen_lm06_utilization_route.rpt` | CONTROL footprint |
| LM-06 BRAM / DSP | **132 / 154** | same | CONTROL footprint |
| LM-06 WNS / TNS | +0.179 / 0.000 | `frozen_lm06_timing_route.rpt` L141 | met (standalone) |
| Additive BRAM | **260 / 135** | 128+132 | **FAIL** (HS-11) |
| Additive DSP | 154 / 240 | 0+154 | OK alone; irrelevant under BRAM FAIL |
| New TinyGPT SoC bit | **null** | not generated | **LIMIT** |
| Frozen 01R/02M/A0.3 | MATCH | `frozen_sha_control.txt` | **PASS** (HS-20) |
| BOARD_PASS | false | — | **PASS** (not declared) |

## Verdict on UNKNOWN

**CLOSED — PASS_NARROW / LIMIT.** H_CANDIDATE falsified: TinyGPT cannot fit **with** retained wt+u_a under BRAM≤135 (additive 260). H_RIVAL blocked (no invented pe_alive; no frozen overwrite; util>device not sold as PASS). HS-22 remains **OPEN**.

## Explicit non-claims

- HS-22 silicon LM-on-answer-path
- Semantic HS-02 held-out retrieval
- New bitstream with TinyGPT/DSP/pe_alive
- BOARD_PASS / Native V1

## NEXT

Orchestrator: mark `tinygpt_soc` DONE_ENG (honest LIMIT) after auditor allow; do **not** tick HS-22/§14 closed. Future unknown = memory consolidation / DDR-backed weights (separate gate), not inventing pe_alive on this CONTROL bit.
