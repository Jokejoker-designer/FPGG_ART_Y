# VERIFY_ONLY: integrate_fit FULL SoC (a7-vivado-gate)

```text
GATE: integrate_fit
MODE: VERIFY_ONLY (no re-impl; re-derive from archived post-route)
AGENT: a7-vivado-gate
DATE: 2026-08-22
BOARD: Arty A7-100T xc7a100tcsg324-1
EVIDENCE_CLASS: POST_ROUTE_SOC
BOARD_PASS: false
```

## Re-derived numbers (provenance = post-route reports on disk)

| Metric | Value | Source | Gate |
|--------|------:|--------|------|
| BRAM tiles | **0** / 135 | `fit_soc_util.rpt` Block RAM Tile | **PASS** (≤135; prefer≤130) |
| RAMB36 / RAMB18 | 0 / 0 | same | OK |
| WNS | **0.952** ns | `fit_soc_timing.rpt` Design Timing Summary | **PASS** (≥0) |
| TNS | **0.000** ns | same | **PASS** (=0) |
| WHS | **0.012** ns | same | hold OK |
| THS | **0.000** ns | same | hold OK |
| LUT / FF / DSP | 5695 / 5903 / **0** | `fit_soc_util.rpt` | DSP=0 **PASS** |
| PE lanes fabric | **16** | `fit_soc_util_hier.rpt` `u_sc` × `g_lane[0..15].u_lane` | **PASS** |
| PE LUT/FF under `u_sc` | 1046 / 1856 | same hier | EVIDENCE |
| SoC bit SHA256 | `D65F3524BE1BD53D6B461CD8CD872DDCF8DE04EC4B7B0C8FB4CA4F959559A4DF` | live `Get-FileHash` vs `FIT_SOC_SHA256.txt` | **MATCH** |
| Proxy CONTROL SHA | `D2FC41A7869E7C4FF9B2E852C0E6E3A328E8C87EE518ACC03091BD29A3D23CA3` | live hash `arty_a7_ng_integrate_fit_own_cut.bit` | **RETAINED MATCH** |
| Frozen LM06/01R/02M/A0.3 | MATCH | live hash `build/out/*.bit` vs expect | **PASS** |
| LM-06 weight fabric | **ABSENT** | BRAM=0 + top comment HS-11; arb/compose only | **LIMIT** |
| BOARD_PASS | false | — | not declared |

## Explicit checks

1. **SoC ≠ proxy:** SoC SHA `D65F3524…` ≠ proxy `D2FC41A7…` — PASS  
2. **Proxy retained CONTROL:** own_cut bit present, SHA unchanged — PASS  
3. **PE not optimized away:** 16× `g_lane[*].u_lane` rows with non-zero LUT/FF — PASS (unlike proxy LUT≈182)  
4. **LM-06 weights ABSENT LIMIT:** no weight BRAM on this SoC bit; frozen LM-06 bit untouched — LIMIT retained  
5. **No BOARD_PASS / no silicon program this verify**

## Verdict

**PASS_NARROW** — post-route FULL SoC numeric gates (BRAM/WNS/TNS/DSP/PE=16 fabric) re-confirmed; proxy CONTROL retained; LM-06 weight fabric ABSENT = LIMIT; **no BOARD_PASS**.

Artifact: `results/A7-NATIVE-GRAPH/INTEGRATE/GATE_integrate_fit_soc_vivado_verify.md`  
Implementer gate: `GATE_integrate_fit_soc.md` / `FIT_BUDGET_SOC.json`
