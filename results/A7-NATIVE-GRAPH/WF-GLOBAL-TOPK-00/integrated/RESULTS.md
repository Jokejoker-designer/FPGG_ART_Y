# RESULTS — wf_global_topk_integrated_00

**Gate:** `wf_global_topk_integrated_00`  
**Agent:** `a7-ng-topk-frontier`  
**Law:** `a7ng-topk-wavefront-global-v1`  
**Evidence class:** MIG_XSIM_WAVEFRONT_INTEGRATED — **not BOARD**

## Hypothesis outcome

| Field | Result |
|-------|--------|
| H_CANDIDATE | **SUPPORTED** — integrated `a7ng_ddr_wavefront_top` + `a7ng_topk_wavefront_global` preserves cross-wave Top-8 |
| H_RIVAL | **FALSIFIED** — per-wave-only differs from global (8/8 slots) |
| FALSIFIER | Not triggered — W1 8th `id=10@161` absent from `G_final`; `merge_count=2` |

## Audit fixes closed

| Finding | Fix |
|---------|-----|
| `lane_pop` forward-ref | Already fixed: `lane_pop` declared before `wave_scored_q` always_ff (`a7ng_ddr_wavefront_top.sv`) |
| Integrated path not in XSim | `tb_a7ng_wf_global_topk_integrated.sv` + MIG project archived |
| PREREGISTER/TB mismatch | `PREREGISTER.md` counterexample table aligned; unit TB unchanged |

## Integrated counterexample (schema-locked DDR)

| Wave | Content | Role |
|------|---------|------|
| W1 | `node_id` 0..15, standard NodeRecordV1 pack | Local 8th = `10@161` |
| W2 | `node_id` 16..31, standard pack | Cross-wave merge displaces W1 8th |
| Global `G_final` | `9,11,25,27@165` + `13,15,29,31@163` | W1 8th `10@161` **absent** |
| Per-wave-only (W2) | `25,27@165` + `29,31@163` + `17,19@162` + `24,26@161` | **8/8 differ** from global |

## Command

```text
cd tests/xsim
C:/2026.1/Vivado/bin/vivado.bat -mode batch -source run_a7ng_wf_global_topk_integrated.tcl
```

Wall time ~6.5 min (MIG calib + 32-record query). `beat_mm=0`.

## XSim marker

`A7NG_WF_GLOBAL_TOPK_INTEGRATED_XSIM_PASS` (`xsim_wf_global_topk_integrated.log`)

## Not claimed

- BOARD_PASS / silicon
- HS-02 / retrieval / SOA ordering
- `a7ng_topk.sv` primitive change (SHA frozen `F671FCB1…`)
