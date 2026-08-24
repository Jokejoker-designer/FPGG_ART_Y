# GATE ng02r_flow — a7-vivado-gate VERIFY_ONLY

**Gate:** `ng02r_flow` / NG-02R-FLOW  
**Agent:** `a7-vivado-gate`  
**Mode:** `VERIFY_ONLY`  
**Result:** **PASS**  
**Date:** 2026-08-22  
**Board:** Arty A7-100T `xc7a100tcsg324-1`  
**BOARD_PASS claimed:** **no**

## TESTS (measured)

| Test | Provenance | Verdict |
|------|------------|---------|
| xvlog `-sv` pkg+scorer+topk+core+frontier | Vivado 2026.1 VRFC, exit 0 | **PASS** |
| OOC `synth_design -top a7ng_ng02_core` | post-synth estimate | **PASS** (0 err / 0 crit / 5 warn) |
| DSP = 0 | post-synth util rpt | **PASS** (`DSPs \| 0`) |
| Slice LUTs / FF | post-synth util rpt | LUT **11302** / FF **9041** (info only) |
| Full impl / bitstream / JTAG | — | **SILICON_DEFERRED** (full rebuild not cheap; leaf synth sufficient for VERIFY_ONLY) |
| Frozen 01R / 02M / LM-06 / A0.3 not overwritten | file SHA + mtime | **PASS** |
| `a7ng_topk.sv` law unchanged vs NG-02R-TOPK | SHA256 match | **PASS** |

### xvlog (this session)

Log: `results/A7-NATIVE-GRAPH/NG-02R-FLOW/vivado_verify_xvlog.log`  
SHA256: `459A3D92587F8FEC98A816B0FA37551F1ED64C926830D2FEE96E56BA8E04E9A3`

### synth leaf (this session)

Log: `results/A7-NATIVE-GRAPH/NG-02R-FLOW/vivado_verify_synth_leaf.log`  
Util: `results/A7-NATIVE-GRAPH/NG-02R-FLOW/vivado_verify_synth_leaf_util.rpt`  
Marker: `SYNTH_LEAF_PASS` / `DSP_CELLS=0`

### Implementer XSim (pre-existing; not re-run by vivado-gate)

`xsim_flow.log` → `A7NG02R_FLOW_XSIM_PASS` (100k cycles; DROP=DUP=REORDER=CONS=READY_BUSY=0)

## Frozen bit integrity

| Lane | Evidence | SHA256 | Verdict |
|------|----------|--------|---------|
| 01R | `results/A7-EAM-01R/bit_01r.sha256` mtime 2026-08-18 | `57D1DF1BF86338A896876F6FBE204B1705128FFEC0A96F0582CF7EF90E9EF6CF` | not overwritten |
| 02M | `build/out/arty_a7_eam02m.bit` = recorded | `DB3BC58A6CC697FD0C290F97B5D6AD171AE7721A6C8A1E2DB2E87C5A84CFE696` | MATCH |
| LM-06 | `build/out/arty_a7_lm06.bit` = `build_manifest.json` | `67C37DD51AED30F82B5B72EC9EF0736DDABA534ED1D724D0ADCAFD2B4282E3BA` | MATCH |
| A0.3 | `A03_SIGNED/arty_a7_eam03e_a03.bit` = ladder | `05E478FF53D8CEBE5CFDF79E1046E986F077F6E0117C714CDA794B38142BEC09` | MATCH |

## RTL SHA256 (live = closeout)

| File | SHA256 |
|------|--------|
| `rtl/native_graph/topk/a7ng_ng02_core.sv` | `241AB11FD2CE008C84B9C9FBB9C6B70145825050FE1835C1489233823AD7B009` |
| `rtl/native_graph/frontier/a7ng_frontier_buckets.sv` | `CE38FEC3562343C64AB718243CE5F4B815A128524EBA2903BE20CD5ACDD2C565` |
| `rtl/native_graph/topk/a7ng_topk.sv` (law untouched) | `F671FCB1B8FB891EE77A9AC3D5A0BA24AE4DBB8109A6645F2250F611AA197636` |

## Explicit non-claims

- Not BOARD_PASS  
- Not integrate_fit / WNS/TNS post-route for full SoC  
- SILICON_DEFERRED for NG-02R-FLOW bitstream  

## NEXT

Orchestrator: continue VERIFY trio / `--dispatch` next OPEN after auditor; P1 backlog still `ng06_wide_dispatch` after flow closed.
