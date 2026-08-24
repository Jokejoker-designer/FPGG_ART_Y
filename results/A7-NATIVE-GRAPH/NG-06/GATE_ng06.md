GATE: ng06
CHANGED: rtl/native_graph/share/a7ng_multi_agent_share.sv
WHY: 16 physical lanes + 256 logical contexts; RR no starvation; fail isolates one ctx (HS-09)
TESTS: tests/xsim/run_a7ng06_share.tcl
EXPECTED: A7NG06_SHARE_XSIM_PASS phys=16 logical=256
ACTUAL: A7NG06_SHARE_XSIM_PASS phys=16 logical=256
PASS/FAIL: PASS
ARTIFACT: results/A7-NATIVE-GRAPH/NG-06/
SHA256: BA90D407AB25010C88DB0A0C23EFBB4B6BAC1A541F40980E7F72FCF84A85B4D6
NEXT GATE: ng07
