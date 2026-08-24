GATE: mem_schema_v1
CHANGED:
  rtl/native_graph/memory/a7ng_mem_schema_v1.{sv,svh,h,md}
  rtl/native_graph/memory/{a7ng_shard_fetch,a7ng_bram_hotset,a7ng_ddr_store,a7ng_episode_bank}.sv
  rtl/native_graph/pkg/a7ng_pkg.sv (NG_EDGE/EPISODE_REC_BYTES aliases)
  rtl/board/arty_a7_ng03_top.sv (uses a7ng_node_byte_addr)
  python/native_graph/mem_schema_v1.py
  tests/native_graph/test_mem_schema_v1.py
  tests/xsim/{tb,run}_a7ng_mem_schema_v1.*
  docs/native_graph/RESOURCE_BUDGET.md (schema table)
  results/A7-NATIVE-GRAPH/NG-03/DDR_MAP.md (edge/episode strides)
WHY: freeze one Node/Edge/EpisodeRecordV1 layout (size/offsets/LE/version) so RTL/Python/TB stop inventing magic strides (feedback P2 / WM §6 / PLAN C1)
TESTS:
  python -m pytest tests/native_graph/test_mem_schema_v1.py -v
  tests/xsim/run_a7ng_mem_schema_v1.tcl (SV golden — xvlog not on PATH this host; TCL+TB archived)
EXPECTED: schema version=1; sizes 16/32/32; golden round-trip PASS; conflicting <<3 gone
ACTUAL: pytest 10 passed; hotset <<3 removed; consumers use a7ng_*_byte_addr / REC_BYTES
PASS/FAIL: PASS
ARTIFACT: results/A7-NATIVE-GRAPH/MEM_SCHEMA_V1/
SHA256: F0FE426EB7B6968392458F7377BB86D579F768FFE66ABE2A4D8E8FD8D57DEB85 (a7ng_mem_schema_v1.sv)
NEXT GATE: bram_wm_00 (blocked_by reset_00 already DONE_ENG) / orchestrator dispatch — no TermGen/integrate_fit/TRAIN-V2 this gate
NO BOARD_PASS.
