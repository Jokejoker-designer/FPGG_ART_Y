GATE: ng06_wide_dispatch
CHANGED: rtl/native_graph/share/a7ng_multi_agent_share.sv; rtl/native_graph/share/a7ng_wide_dispatch_ooc_top.sv; tests/xsim/tb_a7ng_wide_dispatch.sv; tests/xsim/run_a7ng06_wide.tcl; vivado/tcl/native_graph/measure_ng06r_wide_ooc.tcl; constraints/a7ng_wide_dispatch_ooc.xdc; results/A7-NATIVE-GRAPH/NG-06R-WIDE/*
WHY: Repair invalid closeout — TB per-way ungated sims; pop_* DEBUG; compact pair-k allocator; OOC 100 MHz WNS>=0
TESTS: run_a7ng06_wide.tcl (ALWAYS/SPARSE/BURSTY × 1/4/8/16); measure_ng06r_wide_ooc.tcl
EXPECTED: A7NG06R_WIDE_LADDER_PASS; util16>=80% starve=0; OOC WNS>=0 TNS=0; marker NG06R_WIDE_ENGINEERING_PASS
ACTUAL: LADDER_PASS ALWAYS util16=100 max_jpc=16 starve=0; OOC WNS=+0.215 TNS=0; LUT=1359 FF=175 BRAM=0 DSP=0
PASS/FAIL: PASS
ARTIFACT: results/A7-NATIVE-GRAPH/NG-06R-WIDE/closeout.md
SHA256: 4413C74B442CA5A4CD9D0EE6E71BE71EE3067677BB42F327BB90EDAAFB3B9EB6 (a7ng_multi_agent_share.sv)
NEXT: STOP
BRANCH: NG-06R-WIDE
AGENT: a7-ng-scientific
MARKER: NG06R_WIDE_ENGINEERING_PASS
NOTE: Engineering gate only — not BOARD_PASS; HOLD forbids next-gate auto-dispatch
