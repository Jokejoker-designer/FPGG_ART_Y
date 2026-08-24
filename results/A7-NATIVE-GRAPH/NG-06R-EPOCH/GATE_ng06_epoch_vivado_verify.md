# GATE ng06_epoch — a7-vivado-gate VERIFY_ONLY

**Gate:** `ng06_epoch` / NG-06R-EPOCH  
**Agent:** `a7-vivado-gate`  
**Mode:** `VERIFY_ONLY`  
**Result:** **PASS**  
**Date:** 2026-08-22  
**Board:** Arty A7-100T `xc7a100tcsg324-1`  
**BOARD_PASS claimed:** **no**  
**Evidence class:** post-synth estimate + xvlog (not board)

## TESTS (measured)

| Test | Provenance | Verdict |
|------|------------|---------|
| xvlog `-sv` share+prune+ooc_top+tb_epoch+tb_prune | Vivado 2026.1 VRFC, exit 0 | **PASS** |
| OOC `synth_design -top a7ng_wide_dispatch_ooc_top` | post-synth estimate | **PASS** (0 err / 0 crit) |
| OOC `synth_design -top a7ng_ctx_prune` | post-synth estimate | **PASS** (0 err / 0 crit / 56 warn) |
| OOC `synth_design -top a7ng_multi_agent_share` | post-synth estimate | **PASS** (0 err / 0 crit / 1372 warn) |
| DSP = 0 (all three leaves) | post-synth util / `DSP_CELLS` | **PASS** |
| Full impl / bitstream / JTAG | — | **SILICON_DEFERRED** |
| Frozen 01R / 02M / LM-06 / A0.3 not overwritten | file SHA256 | **PASS** |

### xvlog (this session)

Log: `results/A7-NATIVE-GRAPH/NG-06R-EPOCH/vivado_verify_xvlog.log`  
SHA256: `CC4A0B455DA6089880B9E495ABD4705853152350D4375B9D8B02814AAC2D6B54` (VRFC exit 0).

### synth leaf (this session)

| Top | Log | Util | LUT / FF / DSP |
|-----|-----|------|----------------|
| `a7ng_wide_dispatch_ooc_top` | `vivado_verify_synth_leaf_run.log` | `vivado_verify_synth_leaf_share_util.rpt` | **1579** / **152** / **0** |
| `a7ng_ctx_prune` | same | `vivado_verify_synth_leaf_prune_util.rpt` | **35** / **74** / **0** |
| `a7ng_multi_agent_share` | `vivado_verify_synth_leaf_mas_run.log` | `vivado_verify_synth_leaf_mas_util.rpt` | **522451** / **36121** / **0** |

Markers: `SYNTH_LEAF_SHARE_PASS` / `SYNTH_LEAF_PRUNE_PASS` / `SYNTH_LEAF_MAS_PASS` / `SYNTH_LEAF_PASS`  
Note: MAS LUT **824%** of xc7a100t is a **fit finding** for later `integrate_fit` — not a BOARD claim and not a VERIFY_ONLY DSP fail. Functional share evidence remains XSim (`NG06R_EPOCH_ENGINEERING_PASS`).

### Implementer XSim (pre-existing; not re-run by vivado-gate)

`run_epoch_batch.log` / bag logs → `NG06R_EPOCH_ENGINEERING_PASS` / `A7NG06R_EPOCH_XSIM_PASS` bags; Evidence_class=XSIM.

## Frozen bit integrity

| Lane | Path | SHA256 | Verdict |
|------|------|--------|---------|
| 01R | `build/out/arty_a7_eam01r.bit` | `57D1DF1BF86338A896876F6FBE204B1705128FFEC0A96F0582CF7EF90E9EF6CF` | MATCH |
| 02M | `build/out/arty_a7_eam02m.bit` | `DB3BC58A6CC697FD0C290F97B5D6AD171AE7721A6C8A1E2DB2E87C5A84CFE696` | MATCH |
| LM-06 | `build/out/arty_a7_lm06.bit` | `67C37DD51AED30F82B5B72EC9EF0736DDABA534ED1D724D0ADCAFD2B4282E3BA` | MATCH |
| A0.3 | `results/A7-EAM-03E/A03_SIGNED/arty_a7_eam03e_a03.bit` | `05E478FF53D8CEBE5CFDF79E1046E986F077F6E0117C714CDA794B38142BEC09` | MATCH |

## RTL SHA256 (live = closeout `SHA256.txt`)

| File | SHA256 | Match |
|------|--------|-------|
| `rtl/native_graph/share/a7ng_multi_agent_share.sv` | `4413C74B442CA5A4CD9D0EE6E71BE71EE3067677BB42F327BB90EDAAFB3B9EB6` | YES |
| `rtl/native_graph/prune/a7ng_ctx_prune.sv` | `187452537BB094CF94CF598C0F854A1433BAEFB28894252960EF0ED70D36C86D` | YES |
| `rtl/native_graph/share/a7ng_wide_dispatch_ooc_top.sv` | `042EC05936E61546957A6014F2B54EF09B2CB7F3C5765742F3FF9BB92569D623` | YES |

## Explicit non-claims

- Not BOARD_PASS  
- Not integrate_fit / post-route WNS/TNS for full SoC  
- SILICON_DEFERRED for NG-06R-EPOCH bitstream / JTAG  
- MAS post-synth LUT overflow is info only under VERIFY_ONLY + SILICON_DEFERRED  

## NEXT

Orchestrator / auditor: continue VERIFY trio; `allow_loop_done_eng` remains auditor-owned. No LOOP_STATE flip by vivado-gate.
