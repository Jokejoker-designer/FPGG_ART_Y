# NG-05 closeout — local edge/node prior learning

**Law:** `a7ng-learn-v0`  
**Module:** `rtl/native_graph/learn/a7ng_local_learn.sv`

| Gate | Result |
|------|--------|
| XSim | **A7NG05_LEARN_XSIM_PASS** |
| Host inject weights | forbidden (reward-only input) |
| freeze blocks update | T2 |
| forget clears | T3 |
| learn_en=0 blocks | T4 |
| retrain changes mapping | T5 |

Teacher-off **persistence across power-cycle** still needs DDR-backed prior (MEM path) — not claimed here.
No BOARD_PASS.
