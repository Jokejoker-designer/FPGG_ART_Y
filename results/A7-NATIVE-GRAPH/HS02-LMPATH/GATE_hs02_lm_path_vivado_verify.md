# VERIFY_ONLY: hs02_lm_path (a7-vivado-gate)

```text
GATE: hs02_lm_path
MODE: VERIFY_ONLY (no re-impl; no re-program; re-derive from archived post-route + live SHA)
AGENT: a7-vivado-gate
DATE: 2026-08-22
BOARD: Arty A7-100T xc7a100tcsg324-1
EVIDENCE_CLASS: POST_ROUTE_SOC + BOARD_UART_LM_PATH_PROBE (prior repair)
BOARD_PASS: false
```

## Re-derived numbers (provenance = repair post-route reports on disk)

| Metric | Value | Source | Gate |
|--------|------:|--------|------|
| BRAM tiles | **128** / 135 | `lm06_ua_util_repair.rpt` Block RAM Tile | **PASS** (≤135) |
| RAMB36 / RAMB18 | 128 / 0 | same | OK |
| WNS | **0.244** ns | `lm06_ua_timing_repair.rpt` Design Timing Summary L141 | **PASS** (≥0) |
| TNS | **0.000** ns | same | **PASS** (=0) |
| WHS | **0.032** ns | same | hold OK |
| THS | **0.000** ns | same | hold OK |
| LUT / FF / DSP | 7196 / 8091 / **0** | `lm06_ua_util_repair.rpt` | DSP=0 **PASS** |
| TinyGPT / mac_array / gemv / DSP core | **ABSENT** | util has no TinyGPT/mac/gemv; DSP=0; `LIMIT_tinygpt_absent.md` | **LIMIT** |
| Repair SoC bit SHA256 | `4451AFD9B07D8FF52791CCBF6338862FF36B721DF9FBB9BD19EC726BEA67F40E` | live `Get-FileHash` repair + LM06-UA + build/out | **MATCH** |
| CONTROL prior FAIL SHA | `D2C6CF4B28706B24CE513E2B7A09A4018EB9BB01EBB864FA3A5375B11DB9A92C` | live hash HS02 CONTROL archive | **RETAINED**; NEW≠CTRL |
| Frozen LM06/01R/02M/A0.3 | MATCH | live hash `build/out/*.bit` vs expect | **PASS** |
| BOARD_PASS | false | — | not declared |

## Explicit checks

1. **Post-route WNS/TNS:** Design Timing Summary `0.244 / 0.000`; all user constraints met — PASS  
2. **BRAM128:** util Block RAM Tile=128 / device 135 (94.81%) — PASS  
3. **SHA 4451AFD9…:** live hash of `HS02-LMPATH/arty_a7_ng_lm06_ua_soc_repair.bit`, `LM06-UA/arty_a7_ng_lm06_ua_soc.bit`, and `build/out/arty_a7_ng_lm06_ua_soc.bit` all equal claimed SHA — MATCH  
4. **Frozen MATCH:** LM06 / EAM01R / EAM02M / A03 live SHA MATCH expect; not overwritten — PASS  
5. **TinyGPT ABSENT LIMIT:** DSP=0; no TinyGPT/mac_array/gemv in util; LIMIT doc retained — LIMIT (not FAIL)  
6. **No BOARD_PASS / no silicon program this verify**

## Prior board probe (not re-run this verify)

| Field | Value | Provenance |
|-------|-------|------------|
| UART rx | 91B9 | `board_probe_repair.json` |
| exam_mode | 1 | same |
| lm_path | 1 | same (bit5) |
| mig_calib | 1 | same |

## Verdict

**PASS_NARROW** — post-route repair SoC numeric gates (BRAM128 / WNS+0.244 / TNS0 / DSP0 / SHA 4451AFD9 MATCH / frozen MATCH / TinyGPT ABSENT LIMIT) re-confirmed; **no BOARD_PASS**.

Artifact: `results/A7-NATIVE-GRAPH/HS02-LMPATH/GATE_hs02_lm_path_vivado_verify.md`  
Implementer gate: `GATE_hs02_lm_path_repair.md` / `LIMIT_tinygpt_absent.md`  
Frozen verify: `frozen_sha_verify.txt`
