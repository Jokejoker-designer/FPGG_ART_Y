# VERIFY_ONLY: lm06_ua_core (a7-ng-xsim-verify)

**Mode:** VERIFY_ONLY  
**Result:** **PASS_NARROW** (confirm) — SoC `D2C6CF4B…` ≠ CONTROL `D61BA6D4…`; named `u_a` PRESENT; frozen LM-06/01R/02M/A0.3 MATCH  
**Not claimed:** Native V1 BOARD_PASS, semantic HS-02 retrieval, full TinyGPT/DSP core, HS-22 silicon closed  
**XSim marker:** **ABSENT** (`tests/xsim/native_graph` missing for this gate; no `A7NG_*_XSIM_PASS`)  
**Evidence class:** POST_ROUTE_SOC (vivado-gate); XSim N/A this gate  
**ts_utc:** 2026-08-21T23:19:10Z

## Bitstream distinction (required)

| Role | Path | SHA256 | Status |
|------|------|--------|--------|
| **New UA SoC (this gate)** | `results/A7-NATIVE-GRAPH/LM06-UA/arty_a7_ng_lm06_ua_soc.bit` | `D2C6CF4B28706B24CE513E2B7A09A4018EB9BB01EBB864FA3A5375B11DB9A92C` | live rehash **MATCH** |
| **CONTROL weight-cut** | `results/A7-NATIVE-GRAPH/LM06-SOC/arty_a7_ng_lm06_soc.bit` | `D61BA6D454F4AC1B4980D3869866A6742E12C02C9D08C2ECD45897CCD9053FA3` | live rehash **MATCH**; **≠ new UA SoC** |
| Frozen LM-06 | `build/out/arty_a7_lm06.bit` | `67C37DD51AED30F82B5B72EC9EF0736DDABA534ED1D724D0ADCAFD2B4282E3BA` | live rehash **MATCH** |
| Frozen 01R / 02M / A0.3 | `build/out/*.bit` | per `frozen_sha_verify.txt` | **MATCH** (all three) |

Do **not** overwrite frozen `arty_a7_lm06.bit` or CONTROL weight-cut `D61BA6D4…`. New bit is act+weight composition archive only.

## Scientific frame (verify)

| Field | Value |
|-------|-------|
| OBSERVATION | vivado-gate PASS_NARROW; BRAM=128 WNS=+0.257 TNS=0; wt 64 + claimed u_a 64; SHA D2C6CF4B… |
| UNKNOWN | Independent verify: new≠CONTROL? u_a PRESENT? frozen MATCH? invent XSim / BOARD_PASS? |
| H_CANDIDATE | Live rehash D2C6CF4B≠D61BA6D4; timing named `u_a/mem_reg_*`; frozen MATCH; stay PASS_NARROW ACT+WEIGHT |
| H_RIVAL | Sell CONTROL as new SoC; fake u_a; overwrite frozen; invent XSim marker; claim BOARD_PASS / HS-22 closed |
| FALSIFIER | new SHA==CONTROL; any frozen MATCH=False; hier/timing with zero `u_a`; A7NG_*_XSIM_PASS without TB |
| UNIT | post-route util/timing/hier + bit SHA (not query cycles) |
| CONTROL | weight-cut D61BA6D4…; frozen LM-06/01R/02M/A0.3 |
| METRICS | marker ABSENT; BRAM/WNS/TNS/wt/u_a match reports; new≠CONTROL; frozen MATCH; board_pass=false |

## Checks

| Check | Result |
|-------|--------|
| XSim TB under `tests/xsim/native_graph` for lm06_ua_core | **ABSENT** |
| XSim log / `A7NG_*_XSIM_PASS` marker | **ABSENT** |
| `lm06_ua_util.rpt` Block RAM Tile | **128 / 135** — MATCH gate |
| `lm06_ua_timing.rpt` WNS / TNS / WHS / THS | **0.257 / 0.000 / 0.024 / 0.000** — MATCH gate |
| Slice LUT / FF / DSP | **7209 / 8075 / 0** — MATCH gate |
| Weight hier RAMB36 `u_lm06_wtile` / `u_lm06_wpp` | **32 / 32** (total 64) — MATCH gate |
| Act `u_a` PRESENT | Timing paths `u_a/mem_reg_*` RAMB36E1 (named hierarchy); residual BRAM **128−64=64** — MATCH gate PRESENT |
| Hier util named `u_a` row | **ABSENT** (Vivado pure-RAM quirk — same LIMIT note as GATE) |
| PE lanes `u_sc` | LUT=1047 FF=1856; **16×** `g_lane[0..15]` — MATCH gate |
| New UA SoC bit SHA rehash | **MATCH** `D2C6CF4B…B9A92C` |
| CONTROL weight-cut SHA rehash | **MATCH** `D61BA6D4…053FA3` and **≠ new UA SoC** |
| Frozen LM-06 / 01R / 02M / A0.3 rehash | **MATCH** (all four) |
| Inflate to BOARD_PASS / full TinyGPT+DSP / semantic HS-02 / HS-22 closed | **REFUSED** (LIMIT ACT_PLUS_WEIGHT; DSP=0) |
| RTL / golden / frozen bits edited this verify | **No** |

## Artifacts consulted (read-only)

- `results/A7-NATIVE-GRAPH/LM06-UA/GATE_lm06_ua_core.md`
- `results/A7-NATIVE-GRAPH/LM06-UA/FIT_BUDGET_LM06_UA.json`
- `results/A7-NATIVE-GRAPH/LM06-UA/lm06_ua_util.rpt`
- `results/A7-NATIVE-GRAPH/LM06-UA/lm06_ua_timing.rpt`
- `results/A7-NATIVE-GRAPH/LM06-UA/lm06_ua_util_hier.rpt`
- `results/A7-NATIVE-GRAPH/LM06-UA/frozen_sha.txt`
- `results/A7-NATIVE-GRAPH/LM06-UA/frozen_sha_verify.txt` (this verify live rehash)
- `results/A7-NATIVE-GRAPH/LM06-UA/LIMIT_ua_core.md`
- `rtl/board/arty_a7_ng_lm06_ua_soc_top.sv` (`act_ram128k16 u_a` instance — read-only)

## Explicit non-claims

- No XSim functional proof for lm06_ua_core  
- No Native V1 BOARD_PASS  
- No semantic HS-02 / retrieval accuracy on board  
- No full TinyGPT core / DSP≈154 on SoC (DSP=0 this cut)  
- New bit does not replace CONTROL weight-cut D61BA6D4… or frozen `arty_a7_lm06.bit`  
- No LOOP_STATE flip by this verifier (orchestrator / evidence-auditor)  
