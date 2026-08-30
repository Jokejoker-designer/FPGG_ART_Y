# QSTAR-HEURISTIC-V0 — started on grok-orch

**Guide:** `research/QSTAR_NATIVE_FPGA_RESEARCH_GUIDE_2026-08-29.md`  
**Tree:** `research/native-ai-v1-grok-orch-00` @ `140345e`  
**PROGRAM:** NO. **Not** existence SoC. **Not** OpenAI Q*. **Not** golden 664/744.

## Shipped this turn

| Artifact | Role |
|----------|------|
| `python/qstar/heuristic_v0.py` | Host search: 8 macros, `compose_score` sat16, 32 B nodes, retrieve→verify→generate |
| `tests/qstar/test_heuristic_v0.py` | Independent goldens (`QSTAR_TRACE_HASH`, `best_action`) |
| `rtl/qstar/qstar_pkg.sv` | ACTION_N=8, cost constants, `qstar_priority = sat16(-cost)` |
| `rtl/qstar/qstar_ctrl.sv` | Supervisor FSM — **ADDON-LAB**, no DMA, no SoC instantiate |
| `tests/xsim/tb_qstar_ctrl_v0.sv` | Isolated TB |

## Explicitly not built (guide §25)

`qstar_dma`, large heap, 1024-way token Q-head, second MIG master.

## Next (same lane)

1. `xvlog`/`xelab` `tb_qstar_ctrl_v0` on this tree.  
2. Serial Q-head 128→8 (`qstar_qhead_serial.sv`) — **not** glued to TinyGPT logits.  
3. Adapter to existing `a7ng_frontier_buckets` (reuse, don't duplicate).  
4. Slice recovery study (16→4 lanes) **before** COFIT-SILICON.  
5. Never merge into `arty-a7-online-lm-board` until existence `pred=664`.
