GATE: integrate_lite
CHANGED: arty_a7_ng_integrate_lite.bit
WHY: prove graph+mem bank fit without glue frozen LM/01R/02M
TESTS: vivado/tcl/build_a7ng_integrate_lite.tcl
EXPECTED: WNS>=0 bit archived
ACTUAL: WNS=3.268 LUT/FF/BRAM/DSP=23/23/0/0
PASS/FAIL: PASS (lite only — NOT Native V1 integrate_fit)
ARTIFACT: results/A7-NATIVE-GRAPH/INTEGRATE/
SHA256: 574C7E417D8FE768A142B74DA2AE7D63194BF58E32D40CEDC2ED49FDDD2516B8
NEXT GATE: integrate_fit (LM phase-share + 01R/02M cutover still required)
