# VERIFY_ONLY: integrate_fit (a7-ng-xsim-verify)

**Mode:** VERIFY_ONLY  
**Result:** PASS_NARROW (confirm) — **not** full R6 / not BOARD_PASS / not DONE_ENG  
**XSim marker:** **ABSENT** (no `tests/xsim/native_graph` TB; no `A7NG_*_XSIM_PASS`)  
**Evidence class:** POST_ROUTE_PROXY (vivado-gate); XSim N/A this gate

## Scientific frame (verify)

| Field | Value |
|-------|-------|
| OBSERVATION | vivado-gate logged PASS_NARROW; BRAM=130 WNS=1.365 TNS=0; frozen MATCH claimed |
| UNKNOWN | Independent verify: XSim/markers? frozen SHA intact? inflate to full R6? |
| H_CANDIDATE | No XSim for this gate; post-route numbers + frozen MATCH stand; stay PASS_NARROW |
| H_RIVAL | Hidden XSim marker / frozen overwrite / PASS_NARROW sold as full R6 SoC |
| FALSIFIER | XSim marker without TB; any frozen MATCH=False; claim MIG+DDR silicon / concurrent A0.3 |
| UNIT | post-route util/timing rows + bit SHA (not clock-cycle queries) |
| CONTROL | LM-06 / 01R / 02M / A0.3 frozen bits; own_cut bit SHA |
| METRICS | XSim absent; BRAM/WNS/TNS match reports; frozen MATCH; no R6 inflation |

## Checks

| Check | Result |
|-------|--------|
| XSim TB under `tests/xsim/native_graph` for integrate_fit | **ABSENT** |
| XSim log / `A7NG_*_XSIM_PASS` marker | **ABSENT** |
| `fit_own_cut_util.rpt` Block RAM Tile | **130 / 135 (96.30%)** — MATCH gate |
| `fit_own_cut_timing.rpt` WNS / TNS / WHS / THS | **1.365 / 0.000 / 0.067 / 0.000** — MATCH gate |
| LUT / FF / DSP (util) | **182 / 61 / 0** — MATCH gate |
| own_cut bit SHA rehash | **MATCH** `D2FC41A7…D23CA3` |
| Frozen LM-06 / 01R / 02M / A0.3 rehash | **MATCH** (all four) |
| Inflate PASS_NARROW → full R6 (MIG+scratch+cache+episode/index+LM arbitrate on one SoC bit) | **REFUSED** |
| RTL / golden / frozen bits edited this verify | **No** |

## Logs / controls

- `results/A7-NATIVE-GRAPH/INTEGRATE/GATE_integrate_fit.md` (implementer / vivado-gate)
- `results/A7-NATIVE-GRAPH/INTEGRATE/FIT_BUDGET.json` (`evidence_class=POST_ROUTE_PROXY`)
- `results/A7-NATIVE-GRAPH/INTEGRATE/fit_own_cut_util.rpt`
- `results/A7-NATIVE-GRAPH/INTEGRATE/fit_own_cut_timing.rpt`
- `results/A7-NATIVE-GRAPH/INTEGRATE/frozen_sha_verify.txt` (this verify rehash)
- Prior: `results/A7-NATIVE-GRAPH/INTEGRATE/frozen_sha_control.txt`

## Explicit non-claims

- No XSim functional proof for integrate_fit  
- No full R6 integrated SoC (MIG re-instance, DDR corruption silicon, concurrent A0.3, WM-00 bankable)  
- No Native V1 BOARD_PASS  
- No LOOP_STATE flip (parent/orchestrator / auditor)  
- WM-00 OOC WNS=−290.499 remains OPEN  
- Prior `u_a_phase_share` remains FALSIFIED (135 LIMIT)  
