# VERIFY_ONLY: integrate_fit FULL SoC reopen (a7-ng-xsim-verify)

**Mode:** VERIFY_ONLY  
**Result:** PASS_NARROW (confirm) — **not** BOARD_PASS / not HS-02 blind exam / not LM-06 weight fabric  
**XSim marker:** **ABSENT** (no `tests/xsim/native_graph` TB; no `A7NG_*_XSIM_PASS`)  
**Evidence class:** POST_ROUTE_SOC (vivado-gate); XSim N/A this gate

## Bitstream distinction (required)

| Role | Path | SHA256 | Status |
|------|------|--------|--------|
| **SoC (this reopen)** | `arty_a7_ng_integrate_fit_soc.bit` | `D65F3524BE1BD53D6B461CD8CD872DDCF8DE04EC4B7B0C8FB4CA4F959559A4DF` | live rehash **MATCH** |
| **Proxy CONTROL (prior narrow)** | `arty_a7_ng_integrate_fit_own_cut.bit` | `D2FC41A7869E7C4FF9B2E852C0E6E3A328E8C87EE518ACC03091BD29A3D23CA3` | live rehash **MATCH**; **≠ SoC** |
| Frozen LM-06 / 01R / 02M / A0.3 | `build/out/*.bit` | per `frozen_sha_verify_soc.txt` | **MATCH** (all four) |

Do **not** program proxy `D2FC41A7…` as the HS-02 vehicle. SoC bit is `D65F3524…`.

## Scientific frame (verify)

| Field | Value |
|-------|-------|
| OBSERVATION | vivado-gate PASS_NARROW FULL SoC; BRAM=0 WNS=0.952 TNS=0 PE=16 fabric; SHA D65F3524…; proxy D2FC41A7… retained |
| UNKNOWN | Independent verify: XSim/markers? SoC≠proxy? frozen intact? inflate beyond PASS_NARROW? |
| H_CANDIDATE | No XSim; post-route SoC numbers + SoC≠proxy + frozen MATCH stand; stay PASS_NARROW |
| H_RIVAL | Sell proxy as SoC; invent XSim marker; freeze overwrite; claim BOARD_PASS / blind exam |
| FALSIFIER | SoC SHA==proxy; any frozen MATCH=False; A7NG_*_XSIM_PASS without TB |
| UNIT | post-route util/timing/hier rows + bit SHA (not query cycles) |
| CONTROL | proxy own_cut; LM-06 / 01R / 02M / A0.3 frozen bits |
| METRICS | marker ABSENT; BRAM/WNS/TNS/PE match reports; SoC≠proxy; frozen MATCH |

## Checks

| Check | Result |
|-------|--------|
| XSim TB under `tests/xsim/native_graph` for integrate_fit | **ABSENT** (`tests/xsim/native_graph` empty/missing) |
| XSim log / `A7NG_*_XSIM_PASS` marker | **ABSENT** |
| `fit_soc_util.rpt` Block RAM Tile | **0 / 135** — MATCH gate |
| `fit_soc_timing.rpt` WNS / TNS / WHS / THS | **0.952 / 0.000 / 0.012 / 0.000** — MATCH gate |
| Slice LUT / FF / DSP | **5695 / 5903 / 0** — MATCH gate |
| PE lanes `u_sc` / `g_lane[0..15]` | **16** (LUT=1046 FF=1856 under `u_sc`) — MATCH gate |
| SoC bit SHA rehash | **MATCH** `D65F3524…A4DF` |
| Proxy CONTROL SHA rehash | **MATCH** `D2FC41A7…3CA3` and **≠ SoC** |
| Frozen LM-06 / 01R / 02M / A0.3 rehash | **MATCH** (all four) |
| Inflate to BOARD_PASS / HS-02 silicon exam / LM-06 weight fabric present | **REFUSED** (LIMIT stands) |
| RTL / golden / frozen bits edited this verify | **No** |

## Logs / controls

- `results/A7-NATIVE-GRAPH/INTEGRATE/GATE_integrate_fit_soc.md` (implementer / vivado-gate)
- `results/A7-NATIVE-GRAPH/INTEGRATE/FIT_BUDGET_SOC.json` (`evidence_class=POST_ROUTE_SOC`)
- `results/A7-NATIVE-GRAPH/INTEGRATE/fit_soc_util.rpt`
- `results/A7-NATIVE-GRAPH/INTEGRATE/fit_soc_timing.rpt`
- `results/A7-NATIVE-GRAPH/INTEGRATE/fit_soc_util_hier.rpt`
- `results/A7-NATIVE-GRAPH/INTEGRATE/frozen_sha_verify_soc.txt` (this verify rehash)
- Prior proxy verify retained: `VERIFY_integrate_fit.md` (POST_ROUTE_PROXY)

## Explicit non-claims

- No XSim functional proof for integrate_fit  
- No Native V1 BOARD_PASS  
- No HS-02 blind teacher-off exam (UART stub only; exam DEFERRED)  
- No LM-06 weight fabric on this SoC bit (arb+compose only; HS-22 OPEN)  
- Proxy BRAM=130 ownership cut ≠ this SoC (BRAM=0 MIG path)  
- No LOOP_STATE flip by this verifier (orchestrator / auditor)  
- WM-00 OOC WNS=−290.499 remains OPEN  
