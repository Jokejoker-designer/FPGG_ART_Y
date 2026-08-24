# CLOSEOUT — wf_global_topk_00

**Gate:** `wf_global_topk_00`
**Agent:** `a7-ng-topk-frontier`
**Status:** **PASS** (XSim)
**Marker:** `A7NG_WF_GLOBAL_TOPK_XSIM_PASS`
**Law:** `a7ng-topk-wavefront-global-v1`
**Archive:** `results/A7-NATIVE-GRAPH/WF-GLOBAL-TOPK-00/`

## Unknown closed

Does wavefront integration preserve proven global Top-K law across waves via `G_(t+1)=TopK(G_t ∪ TopK(W_t))`?

**Answer:** YES on preregistered counterexample streams (XSim evidence).

## Implementation

| Item | Choice |
|------|--------|
| Accumulator | `rtl/native_graph/topk/a7ng_topk_wavefront_global.sv` |
| Merge primitive | Unchanged `a7ng_topk` 16→8 (`a7ng-topk-global-v1`) |
| Lane map | Slots 0..7 = `G_t`; slots 8..15 = `TopK(W_t)` |
| Integration | `a7ng_ddr_wavefront_top.sv` — `top1_*` and new `global_topk_*` outputs |
| TB | `tests/xsim/tb_a7ng_wf_global_topk.sv` |

## Evidence

- `PREREGISTER.md` (before RTL)
- `RESULTS.md`
- `xsim_wf_global_topk.log` → `A7NG_WF_GLOBAL_TOPK_XSIM_PASS fails=0`
- `SHA256.txt` — `a7ng_topk.sv` SHA matches NG-02R

## Carried risk closed

`lm06_wm_00.carried_risk_r1` / `ddr_wavefront_00` per-wave-only Top-K superseded by global accumulator for retrieval claims.

## NEXT gate recommendation

Per `LOOP_STATE.json` queue after `wf_global_topk_00`: **`lm06_wm_ladder`** remains BLOCKED on human re-open; no auto-chain. Parent may dispatch next OPEN engineering gate per `16_MASTERPLAN_EXECUTION_PATH.md` (e.g. descriptor_contract / ddr_cue_soa if queued).
