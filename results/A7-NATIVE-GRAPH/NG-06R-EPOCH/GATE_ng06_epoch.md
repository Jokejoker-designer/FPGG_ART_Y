GATE: ng06_epoch
CHANGED:
  rtl/native_graph/share/a7ng_multi_agent_share.sv — query_epoch/path_epoch on queue/grant/hot; DROP_STALE dequeue (no ctx kill)
  rtl/native_graph/prune/a7ng_ctx_prune.sv — fire_query/path_epoch vs active; DROP_STALE ignore fire; node_alive=1
  rtl/native_graph/share/a7ng_wide_dispatch_ooc_top.sv — epoch port tie-offs (active=1)
  tests/xsim/tb_a7ng_epoch.sv + run_a7ng06_epoch.tcl — mixed-epoch ≥100k × seed bags
  tests/xsim/tb_a7ng_{ctx_prune,multi_agent_share,wide_dispatch}.sv — epoch wiring
  docs/native_graph/TEST_MATRIX.md — NG06R-E1/E2/E3
WHY: Phase B1 H-epoch — stale expand stop without permanent semantic kill (HS-06/07)
TESTS: run_a7ng06_epoch.tcl + run_a7ng06_share.tcl regress
EXPECTED: DROP_STALE>0 under mixed-epoch; alive=256; priors intact; node_alive=1; matched-epoch share PASS
ACTUAL:
  share seed0 DROP_STALE=396171 grants=204167 alive=256 prior_ok=1 bumps=48
  share seed1 DROP_STALE=396545 grants=204353 alive=256 prior_ok=1
  share seed2 DROP_STALE=395506 grants=203879 alive=256 prior_ok=1
  prune seed0 DROP_STALE=50026 bombs=25166 node_alive=1 bumps=24
  prune seed1 DROP_STALE=49855 bombs=25178 node_alive=1
  A7NG04_PRUNE_PASS; A7NG06_SHARE_XSIM_PASS multi=1 drop_stale=0 (matched)
PASS/FAIL: PASS (XSIM engineering; not BOARD_PASS)
ARTIFACT: results/A7-NATIVE-GRAPH/NG-06R-EPOCH/
SHA256: 4413C74B442CA5A4CD9D0EE6E71BE71EE3067677BB42F327BB90EDAAFB3B9EB6 (a7ng_multi_agent_share.sv)
  prune 187452537BB094CF94CF598C0F854A1433BAEFB28894252960EF0ED70D36C86D
MARKER: NG06R_EPOCH_ENGINEERING_PASS
EVIDENCE_CLASS: XSIM
UNKNOWN: H-epoch (query/path epoch DROP_STALE)
H_RIVAL: HS-07 wipe / permanent ctx kill — FALSIFIED (alive=256, prior_ok=1, node_alive=1)
CONTROL: prior wide SHA 4C604278… superseded by epoch-port share; N_WAY matched-epoch regress PASS
NEXT GATE: reset_00 (logical generation) / ng04_stale_event unblock — parent --dispatch
BRANCH: NG-06R-EPOCH
AGENT: a7-ng-scientific
NOTE: No TermGen / BRAM-WM / reset scrub FSM / integrate_fit / TRAIN-V2 / HNSW / frozen overwrite
