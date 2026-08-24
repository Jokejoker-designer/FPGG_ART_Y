# VERIFY_ONLY: perfmon (a7-ng-xsim-verify)

**Mode:** VERIFY_ONLY  
**Result:** PASS  
**Marker:** `A7NG_PERFMON_XSIM_PASS`  
**Evidence class:** XSIM (not BOARD)

## Controls

| Check | Result |
|-------|--------|
| Live share SHA | `4413C74B442CA5A4CD9D0EE6E71BE71EE3067677BB42F327BB90EDAAFB3B9EB6` MATCH |
| Share regress `tb_a7ng_multi_agent_share` | `A7NG06_SHARE_XSIM_PASS` |
| PERFMON TB `run_a7ng_perfmon.tcl` | `A7NG_PERFMON_XSIM_PASS` / `A7NG_PERFMON_XSIM_OK` |
| Dump vs implementer bag | bit-exact (cycles=67 jobs=16 … lane busy_acc=2×16) |

## Logs

- `results/A7-NATIVE-GRAPH/PERFMON/xsim_perfmon_verify.log`
- `results/A7-NATIVE-GRAPH/PERFMON/xsim_share_control_verify.log`

## Note

Observer-only instrumentation confirmed; share RTL untouched. No golden edit. No BOARD_PASS. No LOOP_STATE flip (parent/orchestrator).
