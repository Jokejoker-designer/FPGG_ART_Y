# CLOSEOUT — wf_global_topk_integrated_00

**Gate:** `wf_global_topk_integrated_00`  
**Agent:** `a7-ng-topk-frontier`  
**Result:** **PASS**  
**Result class:** PASS_NARROW  
**Evidence class:** MIG_XSIM_WAVEFRONT_INTEGRATED  
**Marker:** `A7NG_WF_GLOBAL_TOPK_INTEGRATED_XSIM_PASS`  
**Law:** `a7ng-topk-wavefront-global-v1`

## ONE UNKNOWN closed

Does integrated `a7ng_ddr_wavefront_top` with global accumulator compile and pass XSim counterexample across waves?

**Answer: YES** — xvlog/xelab clean on full integrated project; MIG XSim `fails=0`; `merge_count=2`; W1 8th displaced; per-wave-only oracle fails 8/8.

## carried_risk_r1

**CLOSED** for integrated wavefront path (unit + integrated XSim). Not HS-02 / retrieval / BOARD.

## Artifacts

| Path | Role |
|------|------|
| `integrated/xsim_wf_global_topk_integrated.log` | XSim PASS marker |
| `integrated/xvlog_wf_global_topk_integrated.log` | Compile (no `lane_pop` VRFC) |
| `integrated/wf_global_topk_integrated_xsim.prj` | Integrated file list |
| `tests/xsim/tb_a7ng_wf_global_topk_integrated.sv` | Integrated TB |
| `integrated/SHA256.txt` | Manifest |

## Limits

- Schema-locked DDR pack (`expected_node_beat`) — integrated stream uses sequential `node_id` 0..31; unit TB retains stronger `0xA000`/`0xDEADBEEF` stream.
- Simulation-class only. Human declares BOARD_PASS.
