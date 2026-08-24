# GATE wm00_timing — a7-vivado-gate VERIFY_ONLY

**Gate:** `wm00_timing`  
**Agent:** `a7-vivado-gate`  
**Mode:** `VERIFY_ONLY`  
**Result:** **PASS_NARROW**  
**Date:** 2026-08-22  
**Verified_at_utc:** 2026-08-22T01:15:52+00:00  
**Board:** Arty A7-100T `xc7a100tcsg324-1`  
**BOARD_PASS claimed:** **no**  
**SoC / full-chip claim:** **no**  
**Evidence class:** OOC post-route timing/util (archived Vivado 2026.1) + live SHA rehash — not silicon

## Gate table (measured)

| Metric | Value | Provenance | Gate threshold | Verdict |
|--------|------:|------------|----------------|---------|
| **OOC WNS @100 MHz** | **+0.069 ns** | post-route `timing/timing_route.rpt` Design Timing Summary | WNS ≥ 0 ns | **PASS** |
| **OOC TNS** | **0.000 ns** | same | TNS = 0 ns | **PASS** |
| Constraints | All user specified timing constraints are met | same L144 | met | **PASS** |
| WHS | 0.186 ns | same | report | OK |
| THS | 0.000 ns | same | report | OK |
| LUT / FF | 2990 / 7493 | post-route `timing/util_route.rpt` | report | measured |
| BRAM Tile | **0** / 135 | same | report | measured |
| DSP | **0** / 240 | same | DSP=0 | **PASS** |
| CONTROL WNS | **−290.499 ns** | `timing/CONTROL_timing_route_wns_neg290.rpt` | archived prior FAIL | **MATCH prior** |
| CONTROL TNS | −108584.445 ns | same | archived | **MATCH prior** |
| ΔWNS vs CONTROL | +290.568 ns | derived | improvement | measured |
| Frozen LM-06/01R/02M/A0.3 | MATCH | live SHA256 rehash | untouched | **PASS** |
| Schema SHA | F0FE426E… MATCH | live rehash | untouched | **PASS** |
| Bitstream / JTAG | — | — | — | **SILICON_DEFERRED** |

## Timing honesty

Post-route Design Timing Summary (`timing_route.rpt` L141–144):

```text
WNS(ns)      TNS(ns)  ...  WHS(ns)  THS(ns)
  0.069        0.000  ...  0.186    0.000
All user specified timing constraints are met.
```

CONTROL archive (`CONTROL_timing_route_wns_neg290.rpt` L141):

```text
WNS(ns)      TNS(ns)
-290.499  -108584.445
```

Implementer claim WNS=+0.069 / TNS=0.000 vs prior −290.499: **verified identical.** This VERIFY does **not** promote OOC WM-only bankability to SoC 100 MHz or BOARD_PASS.

## Frozen bit integrity (this session rehash)

| Lane | Path | SHA256 | Verdict |
|------|------|--------|---------|
| LM-06 | `build/out/arty_a7_lm06.bit` | `67C37DD51AED30F82B5B72EC9EF0736DDABA534ED1D724D0ADCAFD2B4282E3BA` | MATCH |
| 01R | `build/out/arty_a7_eam01r.bit` | `57D1DF1BF86338A896876F6FBE204B1705128FFEC0A96F0582CF7EF90E9EF6CF` | MATCH |
| 02M | `build/out/arty_a7_eam02m.bit` | `DB3BC58A6CC697FD0C290F97B5D6AD171AE7721A6C8A1E2DB2E87C5A84CFE696` | MATCH |
| A0.3 | `build/out/arty_a7_eam03e_a03.bit` | `05E478FF53D8CEBE5CFDF79E1046E986F077F6E0117C714CDA794B38142BEC09` | MATCH |
| schema | `rtl/native_graph/memory/a7ng_mem_schema_v1.sv` | `F0FE426EB7B6968392458F7377BB86D579F768FFE66ABE2A4D8E8FD8D57DEB85` | MATCH |
| evidence | `rtl/native_graph/memory/a7ng_wm00_evidence.sv` | `A99C6C7324167A49013ED110B03F6735AF195C0CEF94478B90C3E11B747D0740` | MATCH (gate claim) |
| top | `rtl/native_graph/memory/a7ng_wm00_top.sv` | `0B76BCF9CC289E9EC877F0A8ABE594658A32D8D667AFCF0EEF844C703D932E25` | MATCH (gate claim) |

Dump: `results/A7-NATIVE-GRAPH/BRAM-WM-00/timing/vivado_verify_sha_frozen.txt`

## Report provenance

| File | Role |
|------|------|
| `timing/timing_route.rpt` | post-route OOC timing (WNS/TNS authoritative) |
| `timing/util_route.rpt` | post-route OOC util |
| `timing/CONTROL_timing_route_wns_neg290.rpt` | prior FAIL CONTROL |
| `timing/run_wm00_timing_ooc.tcl` | OOC recipe (implementer; not re-run this VERIFY) |
| `timing/vivado_ooc.log` | Vivado 2026.1 batch log; marker `A7NG_BRAM_WM00_TIMING_OOC_DONE` |

## Explicit non-claims

- Not BOARD_PASS  
- Not SoC / LM-06 integrate / full-chip 100 MHz  
- Not `BRAM_WORKING_MEMORY_ARCH_PASS` (§45)  
- Not JTAG program / silicon ladder  
- Did not re-run OOC impl this VERIFY (numbers from archived post-route reports + live SHA)  
- Did not edit goldens or frozen bits  
- No LOOP flip by vivado-gate  

## NEXT

Orchestrator / remaining VERIFY trio (xsim / auditor). No BOARD_PASS.
