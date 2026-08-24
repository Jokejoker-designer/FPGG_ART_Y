# VERIFY_ONLY: lm06_soc_path (a7-ng-xsim-verify)

**Mode:** VERIFY_ONLY  
**Result:** **PASS_NARROW** (confirm) — SoC `D61BA6D4…` ≠ CONTROL `D65F3524…`; frozen LM-06 MATCH; weight fabric PRESENT (cut)  
**Not claimed:** Native V1 BOARD_PASS, semantic HS-02 retrieval, full LM-06 act/`u_a`+GPT core  
**XSim marker:** **ABSENT** (`tests/xsim/native_graph` missing for this gate; no `A7NG_*_XSIM_PASS`)  
**Evidence class:** POST_ROUTE_SOC (vivado-gate); XSim N/A this gate

## Bitstream distinction (required)

| Role | Path | SHA256 | Status |
|------|------|--------|--------|
| **New SoC (this gate)** | `results/A7-NATIVE-GRAPH/LM06-SOC/arty_a7_ng_lm06_soc.bit` | `D61BA6D454F4AC1B4980D3869866A6742E12C02C9D08C2ECD45897CCD9053FA3` | live rehash **MATCH** |
| **CONTROL SoC (integrate_fit)** | `results/A7-NATIVE-GRAPH/INTEGRATE/arty_a7_ng_integrate_fit_soc.bit` | `D65F3524BE1BD53D6B461CD8CD872DDCF8DE04EC4B7B0C8FB4CA4F959559A4DF` | live rehash **MATCH**; **≠ new SoC** |
| Frozen LM-06 | `build/out/arty_a7_lm06.bit` | `67C37DD51AED30F82B5B72EC9EF0736DDABA534ED1D724D0ADCAFD2B4282E3BA` | live rehash **MATCH** |
| Frozen 01R / 02M / A0.3 | `build/out/*.bit` | per `frozen_sha_verify.txt` | **MATCH** (all three) |

Do **not** overwrite frozen `arty_a7_lm06.bit`. New SoC is a weight-cut composition archive only.

## Scientific frame (verify)

| Field | Value |
|-------|-------|
| OBSERVATION | vivado-gate PASS_NARROW; BRAM=64 WNS=+0.365 TNS=0; wt `u_lm06_wtile`+`u_lm06_wpp`; SHA D61BA6D4… |
| UNKNOWN | Independent verify: SoC≠CONTROL? frozen LM-06 MATCH? invent XSim / BOARD_PASS? |
| H_CANDIDATE | Live rehash confirms D61BA6D4≠D65F3524; frozen MATCH; stay PASS_NARROW WEIGHT_CUT |
| H_RIVAL | Sell CONTROL as new SoC; overwrite frozen LM-06; invent XSim marker; claim BOARD_PASS / full HS-02 |
| FALSIFIER | new SHA==CONTROL; any frozen MATCH=False; A7NG_*_XSIM_PASS without TB |
| UNIT | post-route util/timing/hier rows + bit SHA (not query cycles) |
| CONTROL | SoC D65F3524…; frozen LM-06/01R/02M/A0.3 |
| METRICS | marker ABSENT; BRAM/WNS/TNS/wt hier match reports; SoC≠CONTROL; frozen MATCH; board_pass=false |

## Checks

| Check | Result |
|-------|--------|
| XSim TB under `tests/xsim/native_graph` for lm06_soc_path | **ABSENT** |
| XSim log / `A7NG_*_XSIM_PASS` marker | **ABSENT** |
| `lm06_soc_util.rpt` Block RAM Tile | **64 / 135** — MATCH gate |
| `lm06_soc_timing.rpt` WNS / TNS / WHS / THS | **0.365 / 0.000 / 0.015 / 0.000** — MATCH gate |
| Slice LUT / FF / DSP | **7202 / 8060 / 0** — MATCH gate |
| Weight hier RAMB36 `u_lm06_wtile` / `u_lm06_wpp` | **32 / 32** (total 64) — MATCH gate |
| PE lanes `u_sc` | LUT=1048 FF=1856 — MATCH gate |
| New SoC bit SHA rehash | **MATCH** `D61BA6D4…053FA3` |
| CONTROL SoC SHA rehash | **MATCH** `D65F3524…A4DF` and **≠ new SoC** |
| Frozen LM-06 / 01R / 02M / A0.3 rehash | **MATCH** (all four) |
| Inflate to BOARD_PASS / full LM-06 core / semantic HS-02 | **REFUSED** (LIMIT WEIGHT_CUT_ONLY + act ABSENT) |
| RTL / golden / frozen bits edited this verify | **No** |

## Artifacts consulted (read-only)

- `results/A7-NATIVE-GRAPH/LM06-SOC/GATE_lm06_soc_path.md`
- `results/A7-NATIVE-GRAPH/LM06-SOC/FIT_BUDGET_LM06_SOC.json`
- `results/A7-NATIVE-GRAPH/LM06-SOC/lm06_soc_util.rpt`
- `results/A7-NATIVE-GRAPH/LM06-SOC/lm06_soc_timing.rpt`
- `results/A7-NATIVE-GRAPH/LM06-SOC/lm06_soc_util_hier.rpt`
- `results/A7-NATIVE-GRAPH/LM06-SOC/frozen_sha.txt`
- `results/A7-NATIVE-GRAPH/LM06-SOC/frozen_sha_verify.txt` (this verify live rehash)
- `results/A7-NATIVE-GRAPH/LM06-SOC/LIMIT_weight_cut.md`

## Explicit non-claims

- No XSim functional proof for lm06_soc_path  
- No Native V1 BOARD_PASS  
- No semantic HS-02 / retrieval accuracy on board  
- No full frozen LM-06 bitstream glued into SoC (`u_a` / GPT core ABSENT this cut)  
- New bit does not replace CONTROL SoC D65F3524… or frozen `arty_a7_lm06.bit`  
- No LOOP_STATE flip by this verifier (orchestrator / evidence-auditor)  
