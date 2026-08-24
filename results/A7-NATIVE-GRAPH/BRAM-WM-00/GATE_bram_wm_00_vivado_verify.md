# GATE bram_wm_00 — a7-vivado-gate VERIFY_ONLY

**Gate:** `bram_wm_00`  
**Agent:** `a7-vivado-gate`  
**Mode:** `VERIFY_ONLY`  
**Result:** **PASS** (util + frozen integrity; timing FAIL recorded honestly)  
**Date:** 2026-08-22  
**Board:** Arty A7-100T `xc7a100tcsg324-1`  
**BOARD_PASS claimed:** **no**  
**Evidence class:** OOC post-route util/timing (archived Vivado 2026.1 reports) + live SHA rehash

## Gate table (measured)

| Metric | Value | Provenance | Gate threshold | Verdict |
|--------|------:|------------|----------------|---------|
| BRAM Tile | **0** / 135 | post-route OOC `util_route.rpt` | BRAM=0 claim | **PASS** |
| BRAM Tile | **0** / 135 | post-synth OOC `util_synth.rpt` | same | **PASS** |
| DSP | **0** / 240 | post-route OOC | DSP=0 | **PASS** |
| LUT | 10238 / 63400 (16.15%) | post-route OOC | report only | measured |
| FF | 7359 / 126800 (5.80%) | post-route OOC | report only | measured |
| **WNS @100 MHz** | **−290.499 ns** | post-route OOC `timing_route.rpt` | WNS ≥ 0 ns | **FAIL** (not hidden) |
| TNS | −108584.445 ns | post-route OOC | TNS = 0 ns | **FAIL** |
| WHS | 0.160 ns | post-route OOC | report | OK |
| THS | 0.000 ns | post-route OOC | report | OK |
| Frozen LM-06/01R/02M/A0.3 | MATCH | live SHA256 rehash | untouched | **PASS** |
| Bitstream / JTAG | — | — | — | **SILICON_DEFERRED** |

## Timing honesty (do not hide)

Design Timing Summary (clk period 10.000 ns):

```text
WNS(ns)      TNS(ns)  ...  WHS(ns)  THS(ns)
-290.499  -108584.445 ...  0.160    0.000
Timing constraints are not met.
```

Worst path: `u_ev/slot_reg[0][node][4]` → `u_ev/slot_reg[7][qepoch][2]` — Slack (VIOLATED) **−290.499 ns**.

Implementer claimed `ooc_wns_ns=-290.499` / `FAIL_100MHz_COMB`. **Verified identical.** This VERIFY does **not** reclassify timing as PASS. Pipeline deferred; §45 timing item not claimed.

## Frozen bit integrity (this session rehash)

| Lane | Path | SHA256 | Verdict |
|------|------|--------|---------|
| LM-06 | `build/out/arty_a7_lm06.bit` | `67C37DD51AED30F82B5B72EC9EF0736DDABA534ED1D724D0ADCAFD2B4282E3BA` | MATCH |
| 01R | `build/out/arty_a7_eam01r.bit` | `57D1DF1BF86338A896876F6FBE204B1705128FFEC0A96F0582CF7EF90E9EF6CF` | MATCH |
| 02M | `build/out/arty_a7_eam02m.bit` | `DB3BC58A6CC697FD0C290F97B5D6AD171AE7721A6C8A1E2DB2E87C5A84CFE696` | MATCH |
| A0.3 | `build/out/arty_a7_eam03e_a03.bit` | `05E478FF53D8CEBE5CFDF79E1046E986F077F6E0117C714CDA794B38142BEC09` | MATCH |
| schema | `rtl/native_graph/memory/a7ng_mem_schema_v1.sv` | `F0FE426EB7B6968392458F7377BB86D579F768FFE66ABE2A4D8E8FD8D57DEB85` | MATCH |
| primary | `rtl/native_graph/memory/a7ng_wm00_top.sv` | `1F7F39506DF0D0F21F0F7E60B658047AE38ACB11E5B0924E005413B2B8B8AD98` | MATCH |

Dump: `results/A7-NATIVE-GRAPH/BRAM-WM-00/vivado_verify_sha_frozen.txt`

## Report provenance

| File | Role |
|------|------|
| `util_synth.rpt` | post-synth estimate util |
| `util_route.rpt` | post-route OOC util (BRAM=0 authoritative for this VERIFY) |
| `timing_route.rpt` | post-route OOC timing (WNS FAIL) |
| `run_wm00_ooc.tcl` | OOC recipe (implementer; not re-run this VERIFY) |

## Explicit non-claims

- Not BOARD_PASS  
- Not WNS/TNS timing PASS  
- Not integrate_fit / full-chip fit  
- Not JTAG program / silicon ladder  
- Not `BRAM_WORKING_MEMORY_ARCH_PASS` (§45)  
- No golden edited  

## NEXT

Orchestrator / remaining VERIFY trio. No LOOP flip by vivado-gate. No BOARD_PASS.
