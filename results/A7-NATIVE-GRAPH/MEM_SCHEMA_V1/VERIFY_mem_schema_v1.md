# VERIFY_ONLY: mem_schema_v1 (a7-ng-xsim-verify)

**Mode:** VERIFY_ONLY  
**Result:** PASS  
**Marker:** `A7NG_MEM_SCHEMA_V1_SV_GOLDEN_PASS` / pytest 10/10  
**Evidence class:** XSIM + PYTEST (not BOARD)

## Checks

| Check | Result |
|-------|--------|
| `python -m pytest tests/native_graph/test_mem_schema_v1.py -v` | **10 passed** |
| Schema strides Node/Edge/Episode | **16 / 32 / 32** (version=1, LE) |
| SV golden `run_a7ng_mem_schema_v1.tcl` (xvlog+xelab+xsim 2026.1) | `A7NG_MEM_SCHEMA_V1_SV_GOLDEN_PASS` / `A7NG_MEM_SCHEMA_V1_SV_OK` |
| Live `a7ng_mem_schema_v1.sv` SHA256 | `F0FE426EB7B6968392458F7377BB86D579F768FFE66ABE2A4D8E8FD8D57DEB85` MATCH vs GATE |
| Goldens edited | **No** (VERIFY_ONLY) |

## Logs

- `results/A7-NATIVE-GRAPH/MEM_SCHEMA_V1/pytest_mem_schema_v1_verify.log`
- `results/A7-NATIVE-GRAPH/MEM_SCHEMA_V1/xsim_mem_schema_v1_verify.log`
- Implementer GATE: `results/A7-NATIVE-GRAPH/MEM_SCHEMA_V1/GATE_mem_schema_v1.md`

## Note

Independent re-verify. No RTL/golden edit. No BOARD_PASS. No LOOP_STATE flip (parent/orchestrator).
