# VERIFY_ONLY: bram_wm_00 (a7-ng-xsim-verify)

**Mode:** VERIFY_ONLY  
**Result:** PASS  
**Marker:** `A7NG_BRAM_WM00_XSIM_PASS`  
**Evidence class:** XSIM (not BOARD)

## Checks

| Check | Result |
|-------|--------|
| Re-run `tests/xsim/run_a7ng_wm00.tcl` (xvlog+xelab+xsim) | `A7NG_BRAM_WM00_XSIM_PASS` / `A7NG_BRAM_WM00_XSIM_OK` exit 0 |
| FILL256 capacity | PASS `count=256 drop=0 ddr_bytes=4096` |
| OVERFLOW (intentional DROP) | PASS `drop=1` (not silent) |
| FRONTIER | PASS `count=64 drop=1` |
| TOP8 | PASS `nodes=31..24` |
| LEARN | PASS `count=32 coal=1 wr=16 bytes=512`; `learn_drop=0` |
| 16PE | PASS `grants=16`; `lm_grant=0` |
| DUAL_OWNER | PASS `dual_cnt=2` |
| SCHEMA | PASS NodeRecordV1 version=1 |
| Live RTL/bits vs archive SHA | ALL MATCH (`frozen_sha_verify.txt`) |
| LM-06 / 01R / 02M / A0.3 | MATCH |
| mem_schema_v1 | `F0FE426E…` MATCH |

## DROP=0 bags (capacity / under-capacity)

| Bag | DROP | Note |
|-----|-----:|------|
| FILL256 | **0** | capacity fill — falsifier if DROP>0 |
| LEARN | **0** | learn_drop final metric |
| TOP8 / 16PE / SCHEMA / DUAL_OWNER | n/a or 0 | no capacity overflow path |

OVERFLOW and FRONTIER intentionally DROP>0 (counted, not silent) — not capacity DROP=0 bags.

## Logs / controls

- `results/A7-NATIVE-GRAPH/BRAM-WM-00/xsim_wm00_verify.log`
- `results/A7-NATIVE-GRAPH/BRAM-WM-00/frozen_sha_verify.txt`
- Marker: `results/A7-NATIVE-GRAPH/BRAM-WM-00/A7NG_BRAM_WM00_XSIM_PASS.md`
- Implementer: `results/A7-NATIVE-GRAPH/BRAM-WM-00/GATE_bram_wm_00.md`

## Note

Independent re-sim bit-exact vs implementer bag lines. No RTL/golden edit. No BOARD_PASS. No LOOP_STATE flip (parent/orchestrator).
