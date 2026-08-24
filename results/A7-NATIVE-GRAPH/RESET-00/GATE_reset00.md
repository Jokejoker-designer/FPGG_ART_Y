# GATE: reset_00 (A7-NATIVE-RESET-00)

**Agent:** `a7-ng-memory-arch`  
**Evidence class:** XSIM (not BOARD)  
**Marker:** `A7NG_RESET00_XSIM_PASS`  
**Date:** 2026-08-22

## Scientific frame

| Field | Value |
|-------|-------|
| OBSERVATION | query/path epoch DONE_ENG; training_generation / QUERY_RESET fast path not yet proven |
| UNKNOWN | can logical invalidation (epoch/generation + pointer reset) make old WM entries non-authoritative without physical BRAM wipe and without touching LM-06 frozen backbone? |
| H_CANDIDATE | QUERY_RESET / TRAIN generation bump suffices for authority cut (RESET plan §§2–7) |
| H_RIVAL | old generation still visible after bump; OR reset wipes LM-06 / archives (DESIGN ERROR) |
| FALSIFIER | stale entry accepted after generation bump; OR LM-06/frozen SHA changed |
| UNIT | reset event / training generation bag — not cycles-as-queries |
| CONTROL | frozen LM-06/01R/02M/A0.3 SHAs; share SHA untouched |
| METRICS | auth_valid==0 after QUERY; learn_vis==0 after TRAIN; old_phys>0; LM SHA MATCH; cycles/reset≈5 |

## Verdict

**PASS (engineering / XSIM).** H_CANDIDATE supported for this gate: logical QUERY + TRAIN cut authority without physical scrub. H_RIVAL (LM wipe / old gen accepted) **falsified** under these bags. HARD scrub intentionally **rejected** (sticky `reset_error`) — not claimed PASS.

`XSIM ≠ BOARD`. No BOARD_PASS.

## CHANGED

| Path | Role |
|------|------|
| `rtl/native_graph/memory/a7ng_epoch_mgr.sv` | NEW — query/path epoch + training_generation |
| `rtl/native_graph/memory/a7ng_wm_authority.sv` | NEW — WM stamp authority; ptr invalidate only |
| `rtl/native_graph/memory/a7ng_learned_gen_view.sv` | NEW — learned records tagged by generation |
| `rtl/native_graph/memory/a7ng_reset_ctrl.sv` | NEW — QUERY/SESSION/TRAIN FSM; HARD→error |
| `rtl/native_graph/memory/a7ng_reset_verify.sv` | NEW — RESET_VERIFY invariants |
| `rtl/native_graph/memory/a7ng_reset00_top.sv` | NEW — glue for XSim |
| `tests/xsim/tb_a7ng_reset00.sv` | NEW — RST-01 / RST-03 / HARD reject |
| `tests/xsim/run_a7ng_reset00.tcl` | NEW |
| `docs/native_graph/TEST_MATRIX.md` | RST-01/03/HARD/C1 rows |
| `docs/native_graph/RESOURCE_BUDGET.md` | measured cycles/reset |

**NOT changed:** LM-06/01R/02M/A0.3 bits; `a7ng_multi_agent_share.sv`; TermGen; BRAM-WM full pool; integrate_fit; TRAIN-V2; HNSW; DDR 800k scrub.

## TESTS

| ID | Result |
|----|--------|
| RST-01 QUERY | PASS `auth=0 phys=8 work=0 ep=2 learn_vis=1 cyc=5` |
| RST-03 TRAIN | PASS `gen=2 learn_vis=0 learn_phys=14 old_phys=13 new_vis=1 cyc=5` |
| HARD reject | PASS (error sticky) |
| Frozen SHA control | MATCH all four |
| Share control | MATCH `4413C74B…` |

## SHA256 (primary)

`CC774F32D8632F9099FB55E92FE81FD334FA514A49802CAE16915E031A17E532  a7ng_reset_ctrl.sv`  
(full list: `SHA256.txt`)

## NEXT

Parent `--dispatch` / auditor verify. Likely unblock `mem_schema_v1` / `bram_wm_00`. No BOARD_PASS.
