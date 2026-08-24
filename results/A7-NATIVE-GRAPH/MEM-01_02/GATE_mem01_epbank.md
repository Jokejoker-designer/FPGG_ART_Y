GATE: mem01_epbank (integrate unblock)
CHANGED: a7ng_episode_bank.sv
WHY: real flush/reload episode BRAM↔DDR beyond address stub; frozen 02M untouched
TESTS: tests/xsim/run_a7ng_episode_bank.tcl
EXPECTED: A7NG_MEM01_EPBANK_XSIM_PASS
ACTUAL: A7NG_MEM01_EPBANK_XSIM_PASS
PASS/FAIL: PASS
ARTIFACT: results/A7-NATIVE-GRAPH/MEM-01_02/
SHA256: EE19AAE8B0028D4CA6D8E8D04911DFB3BE8AE2A72FA12EB2FF432EF79A78AD34
NEXT GATE: mem02_index_bank (same pattern) then integrate_fit re-estimate
