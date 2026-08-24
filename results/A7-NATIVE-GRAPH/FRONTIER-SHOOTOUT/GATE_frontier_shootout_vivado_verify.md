# GATE frontier_shootout — a7-vivado-gate VERIFY_ONLY

**Gate:** `frontier_shootout`  
**Agent:** `a7-vivado-gate`  
**Mode:** `VERIFY_ONLY`  
**Result:** **PASS**  
**Date:** 2026-08-22  
**Board:** Arty A7-100T `xc7a100tcsg324-1`  
**BOARD_PASS claimed:** **no**  
**Evidence class:** OOC post-synth util (archived Vivado 2026.1) + live SHA rehash — not post-route / not silicon

## Gate table (measured)

| Metric | Value | Provenance | Gate | Verdict |
|--------|------:|------------|------|---------|
| OOC LUT A_bucket | **1169** | `util_A_bucket.rpt` Slice LUTs; `OOC_UTIL.csv`; `vivado_ooc.log` OOC_ROW | table present | **PASS** |
| OOC FF A_bucket | **3242** | same | report | measured |
| OOC LUT B_systolic | **5848** | `util_B_systolic.rpt`; CSV; OOC_ROW | table present | **PASS** |
| OOC FF B_systolic | **3130** | same | report | measured |
| OOC LUT C_twolevel | **7936** | `util_C_twolevel.rpt`; CSV; OOC_ROW | table present | **PASS** |
| OOC FF C_twolevel | **3150** | same | report | measured |
| DSP A/B/C | **0** / 240 each | util_*.rpt | DSP=0 | **PASS** |
| BRAM A/B/C | **0** / 135 each | util_*.rpt | report | measured |
| M8 WNS | NA_SYNTH_ONLY | COMPARISON_TABLE / closeout | not claimed | **NA** (honest) |
| OOC marker | `FRONTIER_SHOOTOUT_OOC_DONE` | `vivado_ooc.log` L616 | present | **PASS** |
| Frozen LM-06/01R/02M/A0.3 | MATCH | live SHA256 rehash | untouched | **PASS** |
| Top-8 law / bucket ctrl | MATCH | live vs CONTROL_SHA | untouched | **PASS** |
| Bitstream / JTAG | — | — | — | **SILICON_DEFERRED** |

## OOC LUT table A/B/C (confirmed identical across sources)

| Arm | Module | LUT | FF | Sources |
|-----|--------|----:|---:|---------|
| A_bucket | `a7ng_frontier_buckets` | 1169 | 3242 | util rpt / OOC_UTIL.csv / vivado_ooc.log / COMPARISON_TABLE M7 |
| B_systolic | `a7ng_frontier_systolic_pq` | 5848 | 3130 | same |
| C_twolevel | `a7ng_frontier_twolevel` | 7936 | 3150 | same |

`OOC_UTIL.csv` SHA256 = `48E6C9815FFBBC845206F3006D4BC5D9BF4B18D4B6EEB82CB7825B3A5362899B` (MATCH archive).

## Frozen bit integrity (this session rehash)

| Lane | Path | SHA256 | Verdict |
|------|------|--------|---------|
| LM-06 | `build/out/arty_a7_lm06.bit` | `67C37DD51AED30F82B5B72EC9EF0736DDABA534ED1D724D0ADCAFD2B4282E3BA` | MATCH |
| 01R | `build/out/arty_a7_eam01r.bit` | `57D1DF1BF86338A896876F6FBE204B1705128FFEC0A96F0582CF7EF90E9EF6CF` | MATCH |
| 02M | `build/out/arty_a7_eam02m.bit` | `DB3BC58A6CC697FD0C290F97B5D6AD171AE7721A6C8A1E2DB2E87C5A84CFE696` | MATCH |
| A0.3 | `build/out/arty_a7_eam03e_a03.bit` | `05E478FF53D8CEBE5CFDF79E1046E986F077F6E0117C714CDA794B38142BEC09` | MATCH |
| A0.3 signed | `results/A7-EAM-03E/A03_SIGNED/arty_a7_eam03e_a03.bit` | `05E478FF53D8CEBE5CFDF79E1046E986F077F6E0117C714CDA794B38142BEC09` | MATCH |
| topk law | `rtl/native_graph/topk/a7ng_topk.sv` | `F671FCB1B8FB891EE77A9AC3D5A0BA24AE4DBB8109A6645F2250F611AA197636` | MATCH |
| bucket ctrl | `rtl/native_graph/frontier/a7ng_frontier_buckets.sv` | `CE38FEC3562343C64AB718243CE5F4B815A128524EBA2903BE20CD5ACDD2C565` | MATCH |

Dump: `results/A7-NATIVE-GRAPH/FRONTIER-SHOOTOUT/vivado_verify_sha_frozen.txt`

## Explicit non-claims

- Not BOARD_PASS  
- Not post-route WNS/TNS for any arm (M8 = NA_SYNTH_ONLY)  
- Not integrate_fit / full-chip fit  
- Not JTAG program / silicon ladder  
- Did not re-run OOC synth this VERIFY (numbers from archived reports + CSV consistency check)  
- Did not edit goldens or frozen bits  

## NEXT

Orchestrator / remaining VERIFY trio. No LOOP flip by vivado-gate. No BOARD_PASS.
