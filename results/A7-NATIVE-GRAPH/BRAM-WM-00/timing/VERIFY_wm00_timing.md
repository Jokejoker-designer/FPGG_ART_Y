# VERIFY_ONLY: wm00_timing (a7-ng-xsim-verify)

**Mode:** VERIFY_ONLY  
**Result:** PASS_NARROW  
**Marker:** `A7NG_BRAM_WM00_XSIM_PASS`  
**Evidence class:** XSIM (not BOARD)  
**Gate:** `wm00_timing` (LOOP_STATE first OPEN)

## Scientific frame (VERIFY)

| Slot | Value |
|------|-------|
| OBSERVATION | Implementer claimed systolic Top-8 + lossless XSim + OOC WNS≥0 |
| UNKNOWN | Independent re-sim: still lossless + Top-8 exact with frozen MATCH? |
| H_CANDIDATE | Re-run yields `A7NG_BRAM_WM00_XSIM_PASS`; FILL256 DROP=0; TOP8 31..24; frozen MATCH |
| H_RIVAL | Lossless regress / Top-8 mismatch / frozen SHA drift |
| FALSIFIER | Missing marker; FILL256 DROP>0; TOP8 ≠ 31..24; frozen MATCH=False |
| UNIT | WM query/seed bag (8-bag suite) |
| CONTROL | Prior BRAM-WM-00 bags + implementer `GATE_wm00_timing.md` SHAs |
| METRICS | Marker, DROP, TOP8 nodes, learn_drop, frozen SHA MATCH |

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
| Live RTL vs implementer SHA | evidence `A99C6C73…` MATCH; top `0B76BCF9…` MATCH |
| Schema | `F0FE426E…` MATCH |
| LM-06 / 01R / 02M / A0.3 | MATCH |

## DROP=0 bags (capacity / under-capacity)

| Bag | DROP | Note |
|-----|-----:|------|
| FILL256 | **0** | capacity fill — falsifier if DROP>0 |
| LEARN | **0** | learn_drop final metric |
| TOP8 / 16PE / SCHEMA / DUAL_OWNER | n/a or 0 | no capacity overflow path |

OVERFLOW and FRONTIER intentionally DROP>0 (counted, not silent).

## Logs / controls

- `results/A7-NATIVE-GRAPH/BRAM-WM-00/timing/xsim_wm00_verify.log`
- `results/A7-NATIVE-GRAPH/BRAM-WM-00/timing/frozen_sha_verify.txt`
- Marker: `results/A7-NATIVE-GRAPH/BRAM-WM-00/timing/A7NG_BRAM_WM00_XSIM_PASS.md`
- Implementer: `results/A7-NATIVE-GRAPH/BRAM-WM-00/timing/GATE_wm00_timing.md`

## Note

Independent re-sim bit-exact vs implementer bag lines after systolic Top-8 pipeline. No RTL/golden edit. OOC WNS/TNS cited from implementer archive only (vivado-gate owns re-measure). No BOARD_PASS. No LOOP_STATE flip (parent/orchestrator).
