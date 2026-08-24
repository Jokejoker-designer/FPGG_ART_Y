# VERIFY_ONLY: lm06_soc_path (a7-vivado-gate)

```text
GATE: lm06_soc_path
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
| BRAM tiles | **64** / 135 | `lm06_soc_util.rpt` Block RAM Tile | **PASS** (≤135) |
| RAMB36 / RAMB18 | 64 / 0 | same | OK |
| WNS | **0.365** ns | `lm06_soc_timing.rpt` Design Timing Summary | **PASS** (≥0) |
| TNS | **0.000** ns | same | **PASS** (=0) |
| WHS | **0.015** ns | same | hold OK |
| THS | **0.000** ns | same | hold OK |
| LUT / FF / DSP | 7202 / 8060 / **0** | `lm06_soc_util.rpt` | DSP=0 **PASS** |
| Weight fabric | **PRESENT** | hier `u_lm06_wtile` RAMB36=32 + `u_lm06_wpp` RAMB36=32 | **PASS** |
| PE lanes fabric | **16** | hier `u_sc` × `g_lane[0..15].u_lane` | **PASS** |
| PE LUT/FF under `u_sc` | 1048 / 1856 | same hier | EVIDENCE |
| Act scratch `u_a` | **ABSENT** | hier instance count = 0 | **LIMIT** |
| New SoC bit SHA256 | `D61BA6D454F4AC1B4980D3869866A6742E12C02C9D08C2ECD45897CCD9053FA3` | live `Get-FileHash` | **MATCH** archive |
| CONTROL SoC SHA | `D65F3524BE1BD53D6B461CD8CD872DDCF8DE04EC4B7B0C8FB4CA4F959559A4DF` | live hash INTEGRATE SoC | **RETAINED MATCH** |
| Frozen LM06/01R/02M/A0.3 | MATCH | live hash `build/out/*.bit` vs expect | **PASS** |
| BOARD_PASS | false | — | not declared |

## Explicit checks

1. **Post-route WNS/TNS:** Design Timing Summary `0.365 / 0.000`; all user constraints met — PASS  
2. **BRAM64 = weight cut:** `u_lm06_wtile` 32 + `u_lm06_wpp` 32 = 64; util Block RAM Tile = 64 — PASS  
3. **PE16 fabric:** 16× `g_lane[*].u_lane` rows; `u_sc` LUT=1048 FF=1856 — PASS  
4. **Frozen MATCH:** LM06/01R/02M/A0.3 + CONTROL SoC live SHA MATCH — PASS (HS-20)  
5. **LIMIT `u_a` ABSENT:** no hier instance `u_a`; WEIGHT_CUT_ONLY — LIMIT retained  
6. **No BOARD_PASS / no silicon program this verify**

## Verdict

**PASS_NARROW** — post-route SoC+weight-fabric numeric gates (BRAM64 / WNS+0.365 / TNS0 / DSP0 / PE16 / weight PRESENT / frozen MATCH / `u_a` ABSENT LIMIT) re-confirmed; **no BOARD_PASS**.

Artifact: `results/A7-NATIVE-GRAPH/LM06-SOC/GATE_lm06_soc_path_vivado_verify.md`  
Implementer gate: `GATE_lm06_soc_path.md` / `FIT_BUDGET_LM06_SOC.json`
