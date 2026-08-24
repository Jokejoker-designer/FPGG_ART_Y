# Vivado-gate verify — tinygpt_soc

**Mode:** VERIFY_ONLY — re-derive additive BRAM fit from archived post-route CONTROLs (no new place/route; no frozen overwrite)  
**Verified_at_utc:** 2026-08-22T02:20:30+00:00  

## Provenance

| Artifact | Path |
|----------|------|
| CONTROL UA util | `control_ua_util.rpt` / `control_ua_util_repair.rpt` |
| CONTROL UA timing | `control_ua_timing_repair.rpt` L141 (WNS=+0.244 TNS=0) |
| Frozen LM-06 util | `frozen_lm06_utilization_route.rpt` |
| Frozen LM-06 timing | `frozen_lm06_timing_route.rpt` L141 (WNS=+0.179 TNS=0) |
| SHA control | `frozen_sha_control.txt` + live Get-FileHash |

## Live SHA recompute (this VERIFY)

| Label | SHA256 | Verdict |
|-------|--------|---------|
| CONTROL UA (`LM06-UA` + repair) | `4451AFD9B07D8FF52791CCBF6338862FF36B721DF9FBB9BD19EC726BEA67F40E` | **MATCH** |
| Frozen LM-06 | `67C37DD51AED30F82B5B72EC9EF0736DDABA534ED1D724D0ADCAFD2B4282E3BA` | **MATCH** |
| Frozen 01R / 02M / A0.3 | per `frozen_sha_control.txt` | **MATCH** |

## Gate rows (re-derived)

| Check | Measured | Provenance | Verdict |
|-------|----------|------------|---------|
| WNS UA ≥ 0 | +0.244 ns | post-route timing | PASS (CONTROL) |
| TNS UA = 0 | 0.000 | post-route timing | PASS |
| WHS / THS UA | +0.032 / 0.000 | post-route timing | PASS |
| BRAM UA ≤ 135 | **128** / 135 (headroom **7**) | util Block RAM Tile | PASS (CONTROL alone) |
| LM-06 TinyGPT BRAM | **132** / 135 | frozen util | CONTROL footprint |
| Additive TinyGPT+UA BRAM ≤ 135 | **128+132=260** > 135 | arithmetic | **FAIL** → LIMIT |
| DSP UA / LM-06 / sum | 0 / 154 / 154 ≤ 240 | util | PASS alone; irrelevant under BRAM FAIL |
| TinyGPT on UA hier | 0 hits | util/timing grep | ABSENT LIMIT |
| New TinyGPT SoC bit | null (0 `.bit` in TINYGPT-SOC/) | archive | LIMIT |
| Frozen LM/01R/02M/A0.3 | MATCH | live SHA | PASS HS-20 |
| BOARD_PASS | false | — | PASS (not claimed) |

## Cleanup

No new Vivado batch this VERIFY. Note: external `vivado` pid 25604 + `vivado_pid25604.str` present in repo root (not started by this VERIFY; left alone).

## Verdict

**PASS_NARROW** / `fit_verdict=FAIL` / LIMIT — CONTROL UA BRAM128 + frozen LM-06 TinyGPT BRAM132 → **260 > 135**; frozen **MATCH**; **no BOARD_PASS**; HS-22 remains OPEN.
