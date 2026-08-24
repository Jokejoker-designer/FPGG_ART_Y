# VERIFY_ONLY: hs02_semantic (a7-vivado-gate)

```text
GATE: hs02_semantic
MODE: VERIFY_ONLY (no re-impl; no re-program; live SHA + archived post-route)
AGENT: a7-vivado-gate
DATE: 2026-08-22
BOARD: Arty A7-100T xc7a100tcsg324-1
EVIDENCE_CLASS: POST_ROUTE_SOC + BOARD_UART_SEMANTIC_LIMIT (HLB prior)
BOARD_PASS: false
```

## Scientific frame (VERIFY_ONLY)

| Field | Value |
|-------|-------|
| OBSERVATION | HLB PASS_NARROW + TinyGPT ABSENT LIMIT; CONTROL SoC claimed 4451AFD9 |
| UNKNOWN | Does live rehash confirm SoC 4451AFD9 MATCH, TinyGPT ABSENT, frozen MATCH? |
| H_CANDIDATE | Live SHA 4451AFD9 MATCH; DSP=0 / no TinyGPT hier; frozen LM/01R/02M/A0.3 MATCH |
| H_RIVAL | SoC drift; TinyGPT sold present; frozen overwrite |
| FALSIFIER | any SOC MATCH=False; DSP>0 or TinyGPT hit; any frozen MATCH=False |
| UNIT | bit SHA + util DSP (not query cycles) |
| CONTROL | HS02-LMPATH repair SoC + frozen LM-06/01R/02M/A0.3 |
| METRICS | soc_sha_match; frozen_all_match; dsp; tinygpt_hits; wns/tns |

## Re-derived numbers

| Metric | Value | Source | Gate |
|--------|------:|--------|------|
| SoC SHA256 | `4451AFD9B07D8FF52791CCBF6338862FF36B721DF9FBB9BD19EC726BEA67F40E` | live Get-FileHash LM06-UA + HS02 repair + build/out | **MATCH** |
| BRAM tiles | **128** / 135 | `HS02-LMPATH/lm06_ua_util_repair.rpt` | **PASS** |
| WNS | **0.244** ns | `HS02-LMPATH/lm06_ua_timing_repair.rpt` L141 | **PASS** (≥0) |
| TNS | **0.000** ns | same | **PASS** (=0) |
| WHS / THS | **0.032** / **0.000** ns | same | hold OK |
| LUT / FF / DSP | 7196 / 8091 / **0** | util repair | DSP=0 **PASS** |
| TinyGPT / mac_array / gemv | **ABSENT** (0 hits) | util+hier grep; pe_alive=0 board probe | **LIMIT** |
| Frozen LM06/01R/02M/A0.3 | MATCH | live hash `build/out/*.bit` | **PASS** |
| UART CONTROL (not re-probed) | rx `91B9` lm_path=1 pe_alive=0 | `board_probe_semantic.json` | archived |
| BOARD_PASS | false | — | not declared |

## Explicit checks

1. **SoC 4451AFD9 MATCH:** LM06-UA, HS02-LMPATH repair archive, and build/out all live-hash equal — **MATCH**
2. **TinyGPT ABSENT:** DSP=0; TinyGPT/mac_array/gemv hits=0; LIMIT docs retained; pe_alive=0 — **LIMIT** (not FAIL)
3. **Frozen MATCH:** LM06 / EAM01R / EAM02M / A03 live SHA MATCH expect — **PASS**
4. **No BOARD_PASS / no silicon program this verify**

## Verdict

**PASS_NARROW** — SoC `4451AFD9…` MATCH; TinyGPT ABSENT LIMIT; frozen MATCH; post-route WNS+0.244 TNS0 BRAM128 DSP0; **no BOARD_PASS**. Held-out semantic retrieval remains LIMIT (no TinyGPT answer path).

Artifact: `results/A7-NATIVE-GRAPH/HS02-SEMANTIC/GATE_hs02_semantic_vivado_verify.md`  
Frozen verify: `frozen_sha_verify.txt`  
HLB audit: `AUDIT_hs02_semantic.md`
