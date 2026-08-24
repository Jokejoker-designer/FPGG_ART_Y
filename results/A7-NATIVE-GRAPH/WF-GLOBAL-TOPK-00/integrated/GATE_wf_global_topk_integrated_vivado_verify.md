# GATE wf_global_topk_integrated_00 — a7-vivado-gate VERIFY_ONLY

**Gate:** `wf_global_topk_integrated_00`  
**Agent:** `a7-vivado-gate`  
**Mode:** `VERIFY_ONLY`  
**Result:** **PASS_NARROW**  
**Date:** 2026-08-22  
**Board:** Arty A7-100T `xc7a100tcsg324-1`  
**BOARD_PASS claimed:** **no**  
**Evidence class:** OOC post-route util + timing (not SoC / not silicon)

## Verdict rationale

Integrated implementer PASS is **XSim** (`A7NG_WF_GLOBAL_TOPK_INTEGRATED_XSIM_PASS`). This verify re-runs OOC synth/place/route on the **same patched RTL** (`lane_pop` fix + `a7ng_topk_wavefront_global` hook) used by the integrated TB. Both targets complete with **0 errors / 0 critical warnings**. **DSP=0** on both. Negative WNS/TNS are **informational OOC findings** (no `HD.CLK_SRC`, leaf tops, bitonic comb paths) — not a blocker for this correctness gate. No bitstream, no COM12.

## OOC (1) `a7ng_topk_wavefront_global` — post-route

| Metric | Value | Provenance | Gate | Verdict |
|--------|------:|------------|------|---------|
| WNS | **-47.161 ns** | `global_timing_route.rpt` | WNS>=0 | **FAIL** (OOC info) |
| TNS | **-17804.451 ns** | same | TNS=0 | **FAIL** (OOC info) |
| WHS | **+0.232 ns** | same | hold | measured |
| THS | **0.000 ns** | same | hold | measured |
| LUT | **10687** (16.86%) | `global_util_route.rpt` | — | measured |
| FF | **1202** | same | — | measured |
| BRAM | **0** | same | — | measured |
| DSP | **0** | same | DSP=0 | **PASS** |
| Synth/route | DONE | `vivado_ooc_complete.log` | 0 err | **PASS** |

## OOC (2) `a7ng_ddr_wavefront_top` (lane_pop fix + global hook) — post-route

| Metric | Value | Provenance | Gate | Verdict |
|--------|------:|------------|------|---------|
| WNS | **-49.463 ns** | `wavefront_timing_route.rpt` | WNS>=0 | **FAIL** (OOC info) |
| TNS | **-307116.906 ns** | same | TNS=0 | **FAIL** (OOC info) |
| WHS | **+0.146 ns** | same | hold | measured |
| THS | **0.000 ns** | same | hold | measured |
| LUT | **42053** (66.33%) | `wavefront_util_route.rpt` | fits xc7a100t | measured |
| FF | **34625** | same | — | measured |
| BRAM | **0** | same | — | measured |
| DSP | **0** | same | DSP=0 | **PASS** |
| Synth/route | DONE | `vivado_ooc_complete.log` | 0 err | **PASS** |

## RTL SHA256 (live — matches integrated closeout)

| File | SHA256 |
|------|--------|
| `a7ng_topk.sv` (law frozen) | `F671FCB1B8FB891EE77A9AC3D5A0BA24AE4DBB8109A6645F2250F611AA197636` |
| `a7ng_topk_wavefront_global.sv` | `D6D6882BD4C5505246C9B24CB95CEF66BE3BC1F0881545AEDCEC302B01C14B7B` |
| `a7ng_ddr_wavefront_top.sv` | `7971FB77193D5A0E365D1C44FEFF523D593BD7D591E014C7F4F891FF6F2613C7` |

## Explicit non-claims

- Not BOARD_PASS  
- Not WNS/TNS closure for full SoC integration  
- Not DDR/MIG traffic re-measurement  
- Not bitstream / JTAG  

## Artifacts

- `run_wf_global_topk_ooc.tcl` (parent) / `run_wf_integrated_wavefront_ooc.tcl`  
- `integrated/global_*` / `integrated/wavefront_*` util + timing `.rpt`  
- `integrated/vivado_ooc_complete.log` → marker `A7NG_WF_GLOBAL_TOPK_INTEGRATED_OOC_VERIFY_PASS`
