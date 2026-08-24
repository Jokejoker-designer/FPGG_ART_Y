# GATE wf_global_topk_00 — a7-vivado-gate VERIFY_ONLY

**Gate:** `wf_global_topk_00`  
**Agent:** `a7-vivado-gate`  
**Mode:** `VERIFY_ONLY`  
**Result:** **PASS_NARROW**  
**Date:** 2026-08-22 (re-verify ~19:20 +07 post machine-off)  
**Board:** Arty A7-100T `xc7a100tcsg324-1`  
**BOARD_PASS claimed:** **no**  
**Evidence class:** XSim + OOC post-route util/timing on unit leaf (not SoC / not silicon)

## Re-verify session (2026-08-22 ~18:40–19:20 +07)

| Check | Result | Provenance |
|-------|--------|------------|
| XSim marker | **PASS** `A7NG_WF_GLOBAL_TOPK_XSIM_PASS fails=0` | `xsim_wf_global_topk.log` |
| Unit OOC synth/route | **PASS** 0 errors, 0 critical warnings | `vivado_ooc.log` `GLOBAL_ACCUM_RESULT=DONE` |
| Unit hold | **PASS** WHS=+0.232 ns, THS=0 | `global_timing_route.rpt` |
| DSP | **PASS** 0 | `global_util_route.rpt` |
| RTL SHA unchanged | **PASS** | see RTL SHA256 table |

## Verdict rationale

Implementer PASS criterion is **XSim only** (`PREREGISTER.md` L77–83). OOC synth/place/route completed for both targets with **0 errors / 0 critical warnings**. **DSP=0** on both. Negative WNS/TNS are **informational OOC findings** (no `HD.CLK_SRC`, leaf tops, bitonic `a7ng_topk` comb paths) — not a blocker for this correctness gate. No bitstream, no COM12.

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
| Synth/route | DONE | `vivado_ooc.log` | 0 err | **PASS** |

## OOC (2) `a7ng_ddr_wavefront_top` (patched) — post-route

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
| Synth/route | DONE | `vivado_ooc.log` | 0 err | **PASS** |

## RTL SHA256 (live)

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

- `run_wf_global_topk_ooc.tcl`  
- `global_*` / `wavefront_*` util + timing `.rpt`  
- `vivado_ooc.log` → marker `A7NG_WF_GLOBAL_TOPK_OOC_DONE`
