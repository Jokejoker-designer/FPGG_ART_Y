# Vivado-gate verify — tinygpt_consol

**Mode:** VERIFY_ONLY — re-derive consol CONTROL TinyGPT ABSENT + naive additive BRAM 264 LIMIT from archived post-route CONTROLs (no new place/route; no frozen overwrite; no BOARD_PASS)  
**Verified_at_utc:** 2026-08-22T02:55:00+00:00  

## Provenance

| Artifact | Path |
|----------|------|
| CONTROL consol util | `control_consol_util.rpt` / `control_consol_util_hier.rpt` |
| CONTROL consol timing | `control_consol_timing.rpt` Design Timing Summary (WNS=+0.586 TNS=0) |
| Frozen LM-06 util | `frozen_lm06_utilization_route.rpt` |
| Frozen LM-06 timing | `frozen_lm06_timing_route.rpt` Design Timing Summary (WNS=+0.179 TNS=0) |
| SHA control | `frozen_sha_control.txt` + live Get-FileHash → `frozen_sha_verify.txt` |
| Implementer GATE | `GATE_tinygpt_consol.md` / `METRICS.json` / `FIT_BUDGET_TINYGPT_CONSOL.json` |

## Live SHA recompute (this VERIFY)

| Label | SHA256 | Verdict |
|-------|--------|---------|
| CONTROL consol | `83A438B5342446C9E79A537196777B1BCF2468FC57F9379EA2CB8EFE0A7D3AEF` | **MATCH** |
| CONTROL UA | `4451AFD9B07D8FF52791CCBF6338862FF36B721DF9FBB9BD19EC726BEA67F40E` | **MATCH** |
| Frozen LM-06 | `67C37DD51AED30F82B5B72EC9EF0736DDABA534ED1D724D0ADCAFD2B4282E3BA` | **MATCH** |
| Frozen 01R / 02M / A0.3 / mig.prj | per `frozen_sha_verify.txt` | **MATCH** |

## Gate rows (re-derived)

| Check | Measured | Provenance | Verdict |
|-------|----------|------------|---------|
| WNS consol ≥ 0 | +0.586 ns | post-route timing | PASS (CONTROL retained) |
| TNS consol = 0 | 0.000 | post-route timing | PASS |
| WHS / THS consol | +0.069 / 0.000 | post-route timing | PASS |
| BRAM consol ≤ 135 | **132** / 135 (headroom **3**) | util Block RAM Tile | PASS (CONTROL alone) |
| DSP consol | **0** | util | TinyGPT/DSP **ABSENT** |
| LUT / FF consol | 141 / 23 | util | CONTROL proxy |
| TinyGPT hier on consol | **0** (`tiny_gpt`/`tinygpt`/`mac_array`/`gemv`/`pe_alive`) | util+hier grep | **ABSENT LIMIT** |
| LM-06 TinyGPT BRAM / DSP | **132** / **154** | frozen util | CONTROL footprint |
| LM-06 WNS / TNS | +0.179 / 0.000 | frozen timing | met (standalone ≠ consol SoC) |
| Naive additive consol+TinyGPT BRAM ≤ 135 | **132+132=264** > 135 (overshoot **129**) | arithmetic | **FAIL** → LIMIT |
| Co-fit projection | **132** = max(132,132) | prior BRAM-CONSOL ENGINEERING_INFERENCE | **not** TinyGPT evidence |
| New TinyGPT+consol bit | null (0 `.bit` in TINYGPT-CONSOL/) | archive | LIMIT |
| pe_alive invented | false (0 hier hits) | grep | PASS (H_RIVAL blocked) |
| Frozen LM/01R/02M/A0.3/mig | MATCH | live SHA | PASS HS-20 |
| BOARD_PASS | false | — | PASS (not claimed) |
| HS-22 closed | false | TinyGPT ABSENT on consol | **OPEN** |

## Cleanup

No new Vivado batch this VERIFY. No `xsim.dir` / `vivado_pid*.str` left by this agent. No board reprogram.

## Verdict

**PASS_NARROW** / `fit_verdict=FAIL` / LIMIT — consol CONTROL TinyGPT/DSP/pe_alive **ABSENT**; naive additive **264 > 135**; cofit proj 132 not sold as TinyGPT; frozen **MATCH**; **no BOARD_PASS**; HS-22 remains OPEN.
