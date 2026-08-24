GATE: reset_00
CHANGED:
  rtl/native_graph/memory/a7ng_epoch_mgr.sv — query/path epoch + training_generation owner
  rtl/native_graph/memory/a7ng_wm_authority.sv — stamp authority; pointer invalidate (no payload scrub)
  rtl/native_graph/memory/a7ng_learned_gen_view.sv — learned gen view (DDR surrogate)
  rtl/native_graph/memory/a7ng_reset_ctrl.sv — QUERY/SESSION/TRAIN FSM; HARD→error this gate
  rtl/native_graph/memory/a7ng_reset_verify.sv — auth_valid/workset/learn_vis/LM intact
  rtl/native_graph/memory/a7ng_reset00_top.sv — XSim glue
  tests/xsim/tb_a7ng_reset00.sv + run_a7ng_reset00.tcl — RST-01/RST-03/HARD
  docs/native_graph/{TEST_MATRIX,RESOURCE_BUDGET}.md
WHY: A7-NATIVE-RESET-00 logical path — authority cut without BRAM wipe / LM-06 touch
TESTS: run_a7ng_reset00.tcl
EXPECTED: QUERY auth=0+phys>0; TRAIN learn_vis=0+old_phys>0; LM SHA MATCH; HARD error
ACTUAL:
  RST-01 PASS auth=0 phys=8 work=0 ep=2 learn_vis=1 cyc=5
  RST-03 PASS gen=2 learn_vis=0 learn_phys=14 old_phys=13 new_vis=1 cyc=5
  HARD reject PASS; A7NG_RESET00_XSIM_PASS
  frozen LM-06/01R/02M/A0.3 MATCH; share 4413C74B… untouched
PASS/FAIL: PASS (XSIM engineering; not BOARD_PASS)
ARTIFACT: results/A7-NATIVE-GRAPH/RESET-00/
SHA256: CC774F32D8632F9099FB55E92FE81FD334FA514A49802CAE16915E031A17E532 (a7ng_reset_ctrl.sv)
MARKER: A7NG_RESET00_XSIM_PASS
EVIDENCE_CLASS: XSIM
UNKNOWN: logical invalidation without physical wipe / LM touch
H_RIVAL: old gen accepted OR LM wipe — FALSIFIED (learn_vis=0; LM MATCH)
CONTROL: LM-06 67C37DD5…; 01R/02M/A0.3 MATCH
NEXT GATE: parent --dispatch (mem_schema_v1 / bram_wm_00 still blocked_by reset until STATUS flip)
AGENT: a7-ng-memory-arch
NOTE: No TermGen / BRAM-WM pool / integrate_fit / TRAIN-V2 / HNSW / 800k DDR scrub / BOARD_PASS
