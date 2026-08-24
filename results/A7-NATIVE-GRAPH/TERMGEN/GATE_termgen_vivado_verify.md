# GATE termgen — a7-vivado-gate VERIFY_ONLY

**Gate:** `termgen`  
**Agent:** `a7-vivado-gate`  
**Mode:** `VERIFY_ONLY`  
**Result:** **PASS**  
**Date:** 2026-08-22  
**Board:** Arty A7-100T `xc7a100tcsg324-1`  
**BOARD_PASS claimed:** **no**  
**Evidence class:** OOC post-synth util + timing (archived Vivado 2026.1, Design State = Synthesized) + live SHA rehash — not post-route / not silicon

## Gate table (measured)

| Metric | Value | Provenance | Gate | Verdict |
|--------|------:|------------|------|---------|
| OOC LUT | **12610** | `ooc_util.rpt` Slice LUTs | report | measured |
| OOC FF | **8112** | `ooc_util.rpt` Slice Registers | report | measured |
| OOC DSP | **0** | `ooc_util.rpt` DSPs; `ooc_synth.log` `TERMGEN_OOC_DSP=0` | DSP=0 | **PASS** |
| OOC WNS | **+2.617 ns** | `ooc_timing.rpt` Design Timing Summary; Design State=Synthesized | WNS>=0 (post-synth) | **PASS** (estimate) |
| OOC TNS | **0.000 ns** | same | TNS=0 | **PASS** (estimate) |
| OOC WHS | **0.275 ns** | same | hold report | measured (non-negative) |
| OOC THS | **0.000 ns** | same | hold report | measured |
| OOC marker | `TERMGEN_OOC_DONE` | `ooc_synth.log` | present | **PASS** |
| Primary lane SHA | `DD637EDA…22DF5218` | live rehash vs `SHA256.txt` | MATCH | **PASS** |
| Top-8 law / bucket ctrl | MATCH | live vs archive | untouched | **PASS** |
| Frozen LM-06/01R/02M/A0.3 | MATCH | live SHA256 rehash | untouched | **PASS** |
| Bitstream / JTAG | — | — | — | **SILICON_DEFERRED** |

## OOC sources confirmed identical

| Source | LUT | FF | DSP | WNS |
|--------|----:|---:|----:|----:|
| `ooc_util.rpt` / `ooc_timing.rpt` | 12610 | 8112 | 0 | 2.617 |
| `ooc_synth.log` TERMGEN_OOC_* | — | — | 0 | 2.617 |
| implementer `manifest.json` / `GATE_termgen.md` | 12610 | 8112 | 0 | 2.617 |

## Frozen bit integrity (this session rehash)

Dump: `results/A7-NATIVE-GRAPH/TERMGEN/vivado_verify_sha_frozen.txt` — **ALL_MATCH=True**

| Lane | Path | SHA256 | Verdict |
|------|------|--------|---------|
| LM-06 | `build/out/arty_a7_lm06.bit` | `67C37DD51AED30F82B5B72EC9EF0736DDABA534ED1D724D0ADCAFD2B4282E3BA` | MATCH |
| 01R | `build/out/arty_a7_eam01r.bit` | `57D1DF1BF86338A896876F6FBE204B1705128FFEC0A96F0582CF7EF90E9EF6CF` | MATCH |
| 02M | `build/out/arty_a7_eam02m.bit` | `DB3BC58A6CC697FD0C290F97B5D6AD171AE7721A6C8A1E2DB2E87C5A84CFE696` | MATCH |
| A0.3 | `build/out/arty_a7_eam03e_a03.bit` | `05E478FF53D8CEBE5CFDF79E1046E986F077F6E0117C714CDA794B38142BEC09` | MATCH |
| topk law | `rtl/native_graph/topk/a7ng_topk.sv` | `F671FCB1B8FB891EE77A9AC3D5A0BA24AE4DBB8109A6645F2250F611AA197636` | MATCH |
| bucket ctrl | `rtl/native_graph/frontier/a7ng_frontier_buckets.sv` | `CE38FEC3562343C64AB718243CE5F4B815A128524EBA2903BE20CD5ACDD2C565` | MATCH |
| termgen lane | `rtl/native_graph/scorer/a7ng_termgen_lane.sv` | `DD637EDAC060D407F44E81C6DD83FE3995150B4CDD275EEF2820757F22DF5218` | MATCH |
| scorer lane/array | control SHAs in `SHA256.txt` | MATCH archive | MATCH |

## Explicit non-claims

- Not BOARD_PASS  
- Not post-route WNS/TNS (Design State = Synthesized only)  
- Not integrate_fit / full-chip fit  
- Not JTAG program / silicon ladder  
- Not end-to-end candidates/s throughput claim  
- Did not re-run OOC synth this VERIFY (numbers from archived reports + log consistency)  
- Did not edit goldens or frozen bits  

## NEXT

Orchestrator / remaining VERIFY trio. No LOOP flip by vivado-gate. No BOARD_PASS.
