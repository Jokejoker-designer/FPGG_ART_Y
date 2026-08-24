# VERIFY_ONLY: hs02_lm_path (a7-ng-xsim-verify)

**Mode:** VERIFY_ONLY  
**Result:** **PASS_NARROW** (confirm) — repair SoC `4451AFD9…` ≠ prior FAIL `D2C6CF4B…`; frozen LM-06/01R/02M/A0.3 **MATCH**  
**Not claimed:** Native V1 BOARD_PASS, semantic HS-02 / HS-22, TinyGPT/DSP present, XSim functional proof, invented `lm_path`  
**XSim marker:** **ABSENT** (`tests/xsim/native_graph` missing for this gate; no `A7NG_*_XSIM_PASS`)  
**Evidence class:** BOARD_UART_LM_PATH_PROBE (vivado-gate); XSim N/A this gate  
**ts_utc:** 2026-08-22T00:48:24Z

## Bitstream distinction (required)

| Role | Path | SHA256 | Status |
|------|------|--------|--------|
| **Repair SoC (this cycle)** | `results/A7-NATIVE-GRAPH/LM06-UA/arty_a7_ng_lm06_ua_soc.bit` | `4451AFD9B07D8FF52791CCBF6338862FF36B721DF9FBB9BD19EC726BEA67F40E` | live rehash **MATCH** |
| **Repair archive** | `results/A7-NATIVE-GRAPH/HS02-LMPATH/arty_a7_ng_lm06_ua_soc_repair.bit` | `4451AFD9B07D8FF52791CCBF6338862FF36B721DF9FBB9BD19EC726BEA67F40E` | live rehash **MATCH** (= live SoC) |
| **PRIOR FAIL CONTROL** | `results/A7-NATIVE-GRAPH/HS02-LMPATH/CONTROL_prior_D2C6CF4B_arty_a7_ng_lm06_ua_soc.bit` | `D2C6CF4B28706B24CE513E2B7A09A4018EB9BB01EBB864FA3A5375B11DB9A92C` | live rehash **MATCH**; **≠ repair** |
| Frozen LM-06 | `build/out/arty_a7_lm06.bit` | `67C37DD51AED30F82B5B72EC9EF0736DDABA534ED1D724D0ADCAFD2B4282E3BA` | live rehash **MATCH** |
| Frozen 01R / 02M / A0.3 | `build/out/*.bit` | per `frozen_sha_verify.txt` | **MATCH** (all three) |

`REPAIR_NE_PRIOR_FAIL=True` (`4451AFD9…` ≠ `D2C6CF4B…`). Frozen bits not overwritten.

## `lm_path` policy (this agent)

- **Do not invent `lm_path`.** This verifier does **not** open COM12, forge UART bytes, or assert `lm_path` from RTL inspection alone.
- Board-visible `lm_path` remains **vivado-gate / HLB provenance only** (`board_probe_repair.json`, `GATE_hs02_lm_path_repair.md`). Cite: `rx=91B9` exam_mode=1 flags bit5 — **not** an xsim claim.
- XSim field: `lm_path=NOT_INVENTED_BY_XSIM`.

## Scientific frame (verify)

| Field | Value |
|-------|-------|
| OBSERVATION | vivado-gate PASS_NARROW repair; SHA 4451AFD9…; prior HLB FAIL on D2C6CF4B… |
| UNKNOWN | Independent verify: repair≠FAIL control? frozen MATCH? invent lm_path / XSim / BOARD_PASS? |
| H_CANDIDATE | Live rehash 4451AFD9≠D2C6CF4B; frozen MATCH; stay PASS_NARROW; lm_path not invented |
| H_RIVAL | Sell D2C6 as repair; overwrite frozen; invent lm_path=1; invent XSim marker; claim BOARD_PASS |
| FALSIFIER | repair SHA==D2C6; any frozen MATCH=False; A7NG_*_XSIM_PASS without TB; this agent invents lm_path |
| UNIT | bit SHA + frozen SHA (not query cycles) |
| CONTROL | prior FAIL D2C6CF4B… archived; frozen LM-06/01R/02M/A0.3 |
| METRICS | marker ABSENT; repair≠FAIL; frozen MATCH; board_pass=false; lm_path not invented |

## Checks

| Check | Result |
|-------|--------|
| XSim TB under `tests/xsim/native_graph` for hs02_lm_path | **ABSENT** |
| XSim log / `A7NG_*_XSIM_PASS` marker | **ABSENT** |
| Repair SoC bit SHA rehash | **MATCH** `4451AFD9…EA67F40E` |
| Prior FAIL CONTROL SHA rehash | **MATCH** `D2C6CF4B…1DB9A92C` and **≠ repair** |
| Frozen LM-06 / 01R / 02M / A0.3 rehash | **MATCH** (all four) |
| `lm06_ua_timing_repair.rpt` WNS / TNS / WHS / THS | **0.244 / 0.000 / 0.032 / 0.000** — MATCH gate |
| `lm06_ua_util_repair.rpt` BRAM / LUT / FF / DSP | **128 / 7196 / 8091 / 0** — MATCH gate |
| Invent `lm_path` / forge UART | **REFUSED** |
| Inflate to BOARD_PASS / TinyGPT+DSP / semantic HS-22 | **REFUSED** (LIMIT TinyGPT ABSENT; DSP=0) |
| RTL / golden / frozen bits edited this verify | **No** |

## Artifacts consulted (read-only)

- `results/A7-NATIVE-GRAPH/HS02-LMPATH/GATE_hs02_lm_path_repair.md`
- `results/A7-NATIVE-GRAPH/HS02-LMPATH/sha256_repair.txt`
- `results/A7-NATIVE-GRAPH/HS02-LMPATH/frozen_sha_control_repair.txt`
- `results/A7-NATIVE-GRAPH/HS02-LMPATH/board_probe_repair.json` (cite only; not re-probed)
- `results/A7-NATIVE-GRAPH/HS02-LMPATH/lm06_ua_timing_repair.rpt`
- `results/A7-NATIVE-GRAPH/HS02-LMPATH/lm06_ua_util_repair.rpt`
- `results/A7-NATIVE-GRAPH/HS02-LMPATH/frozen_sha_verify.txt` (this verify live rehash)
- `results/A7-NATIVE-GRAPH/LM06-UA/arty_a7_ng_lm06_ua_soc.bit`
- `results/A7-NATIVE-GRAPH/HS02-LMPATH/CONTROL_prior_D2C6CF4B_arty_a7_ng_lm06_ua_soc.bit`

## Explicit non-claims

- No XSim functional proof for hs02_lm_path  
- No invented `lm_path` value by this agent  
- No Native V1 BOARD_PASS  
- No semantic HS-02 / retrieval accuracy  
- No TinyGPT core / DSP≈154 (DSP=0)  
- Repair bit does not replace prior FAIL CONTROL archive or frozen `arty_a7_lm06.bit`  
- No LOOP_STATE flip by this verifier (orchestrator / evidence-auditor / HLB)  
