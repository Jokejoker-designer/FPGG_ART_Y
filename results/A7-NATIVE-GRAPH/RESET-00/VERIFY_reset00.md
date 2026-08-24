# VERIFY_ONLY: reset_00 (a7-ng-xsim-verify)

**Mode:** VERIFY_ONLY  
**Result:** PASS  
**Marker:** `A7NG_RESET00_XSIM_PASS`  
**Evidence class:** XSIM (not BOARD)

## Checks

| Check | Result |
|-------|--------|
| Re-run `tb_a7ng_reset00` / xvlog+xelab+xsim | `A7NG_RESET00_XSIM_PASS` / `A7NG_RESET00_XSIM_OK` |
| RST-01 QUERY | PASS `auth=0 phys=8 work=0 ep=2 learn_vis=1 cyc=5` |
| RST-03 TRAIN | PASS `gen=2 learn_vis=0 learn_phys=14 old_phys=13 new_vis=1 cyc=5` |
| HARD reject | PASS (error as designed) |
| `CONTROL lm_frozen_intact` | `1` |
| Live RTL/TB vs `SHA256.txt` | ALL MATCH (8 files) |
| LM-06 frozen bit | `67C37DD5…` MATCH |
| 01R / 02M / A0.3 frozen bits | MATCH |
| Share control `a7ng_multi_agent_share.sv` | `4413C74B…` MATCH (untouched) |

## Logs / controls

- `results/A7-NATIVE-GRAPH/RESET-00/xsim_reset00_verify.log`
- `results/A7-NATIVE-GRAPH/RESET-00/frozen_sha_verify.txt`
- Marker: `results/A7-NATIVE-GRAPH/RESET-00/A7NG_RESET00_XSIM_PASS.md`

## Note

Independent re-sim bit-exact vs implementer bag lines. No RTL/golden edit. No BOARD_PASS. No LOOP_STATE flip (parent/orchestrator).
