# RESULTS — wf_global_topk_00

**Gate:** `wf_global_topk_00`
**Agent:** `a7-ng-topk-frontier`
**Law:** `a7ng-topk-wavefront-global-v1`
**Evidence class:** XSim — **not BOARD**

## Hypothesis outcome

| Field | Result |
|-------|--------|
| H_CANDIDATE | **SUPPORTED** — `G_(t+1)=TopK(G_t ∪ TopK(W_t))` via reused `a7ng_topk` 16→8 |
| H_RIVAL | **FALSIFIED** on counterexample — per-wave-only differs from global (8/8 slots) |
| FALSIFIER | Not triggered — rank-9 `0xDEADBEEF` score 135 enters `G_final` slot 7 |

## Tests

| Test | Result |
|------|--------|
| Counterexample W1+W2 non-sequential `node_id` | PASS |
| Per-wave-only oracle must differ | PASS (8 slots) |
| Three-wave accumulation | PASS |
| `merge_count` after counterexample | 2 |
| XSim marker | **A7NG_WF_GLOBAL_TOPK_XSIM_PASS** |

## Command

```text
cd tests/xsim
vivado -mode batch -source run_a7ng_wf_global_topk.tcl
```

Wall time ~8 s (Vivado 2026.1).

## Counterexample (preregistered)

| Wave | Key candidate | Score | Role |
|------|---------------|------:|------|
| W1 | `0xA000..0xA007` | 200..130 | Local top-8 |
| W2 | `0xDEADBEEF` | 135 | Beats W1 8th (130); global rank 8 |
| W2-only | — | — | Would lose all W1 high scores (8/8 differ) |

## Integration hook

`a7ng_ddr_wavefront_top.sv`: per-wave `a7ng_topk` retained; `a7ng_topk_wavefront_global` accumulates `G_final`; `top1_id_o` / `top1_score_o` now reflect global result.

## Not claimed

- BOARD_PASS
- DDR/MIG traffic re-measurement
- HS-02 / metadata-fetch ordering (future SOA gate)
- `a7ng_topk-global-v1` primitive change (SHA frozen)
