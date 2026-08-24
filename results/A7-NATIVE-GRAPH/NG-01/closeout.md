# NG-01 closeout — 16-lane scorer

**Law:** `a7ng-scorer-v0`  
**Board:** Arty A7-100T `xc7a100tcsg324-1` @ 100 MHz  
**Evidence class:** XSim + post-route = **EVIDENCE**

## Gates

| Gate | Requirement | Result |
|------|-------------|--------|
| XSim | `A7NG01_XSIM_PASS` | **PASS** |
| Physical lanes | 16 distinct `u_lane` | **16/16** (`keep_hierarchy`) |
| WNS | ≥ 0 ns | **+2.400 ns** |
| TNS | = 0 ns | **0.000** |
| DSP | 0 preferred | **0** |
| BRAM | ≤ 8 | **0** |
| LUT / FF | measured | **618 / 411** |

## Artifacts

| File | Role |
|------|------|
| `golden_a7ng01.json` | Pre-registered score bag |
| `a7ng01_timing_route.rpt` | Post-route timing |
| `a7ng01_utilization_route.rpt` | Post-route util |
| `SHA256.txt` | Bitstream hash |
| `manifest.json` | Machine summary |
| `build/out/arty_a7_ng01_scorer.bit` | Bit (not frozen LM/01R/02M/A0.3) |

## RTL

- `rtl/native_graph/pkg/a7ng_pkg.sv` — sat_add widen-before-add  
- `rtl/native_graph/scorer/a7ng_scorer_{lane,array}.sv` — 2-stage PE, II=1 after fill  
- `rtl/board/arty_a7_ng01_scorer_top.sv` — timing shell  

## Not claimed

No DDR graph. No Top-K. No silicon UART ladder. No Native V1 BOARD_PASS.  
AI does **not** declare BOARD_PASS (`AGENTS.md`).
