GATE: ng02_ng03_silicon_log
CHANGED: archived xsdb transcript for NG-02 then NG-03 reprogram
WHY: auditor MAJOR — JTAG claimed without log
TESTS: xsdb connect; fpga -f arty_a7_ng02.bit; fpga -f arty_a7_ng03.bit
EXPECTED: NG02_PROGRAM_OK and NG03_PROGRAM_OK
ACTUAL: both OK (see JTAG_NG02_NG03_xsdb.log)
PASS/FAIL: PASS
ARTIFACT: results/A7-NATIVE-GRAPH/STATUS/JTAG_NG02_NG03_xsdb.log
SHA256: 2FA94B90CFFDDE3F7B69A3E334297CE2868CB6578E7652762EF3725A6FAD2EF7
NEXT GATE: ng06
