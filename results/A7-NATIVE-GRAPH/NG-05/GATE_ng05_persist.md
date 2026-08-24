GATE: ng05_persist
CHANGED: rtl/native_graph/learn/a7ng_prior_persist.sv; NG_DDR_PRIOR_BASE; axi mem prior region
WHY: teacher-off BRAM loss must reload FPGA-owned priors from DDR; forget clears both; host has no weight port
TESTS: tests/xsim/run_a7ng05_persist.tcl
EXPECTED: A7NG05_PERSIST_XSIM_PASS (train=6, kill BRAM=0, reload=6, forget=0, retrain=-3, freeze hold)
ACTUAL: A7NG05_PERSIST_XSIM_PASS @ 936 ns
PASS/FAIL: PASS
ARTIFACT: results/A7-NATIVE-GRAPH/NG-05/
SHA256: see PERSIST_SHA256.json
NEXT GATE: ng02_ng03_silicon_log
