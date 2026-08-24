# GATE: integrate_fit — PASS_NARROW (ownership-audited ≤130 cut)

```text
GATE: integrate_fit
CHANGED: vivado/tcl/native_graph/measure_integrate_fit_own_cut.tcl;
         BRAM_OWNERSHIP_POST_ROUTE.md; NEW bit own_cut only
WHY: ONE UNKNOWN — ownership-audited tile cut (drop concurrent A0.3 +
     DDR-spill 2 of u_a) meet Prefer<=130 + R6 numeric on xc7a100t?
TESTS: measure_integrate_fit_own_cut.tcl (post-route)
EXPECTED: BRAM<=130 AND WNS>=0 AND TNS=0; frozen SHA MATCH; ownership dual=0
ACTUAL (post-route provenance):
  residual66 + shared_cut64 + a03=0 + banks0 + MIG_cited0
    = Block RAM Tile 130 / 135 (96.30%)
  WNS=1.365 ns  TNS=0.000  WHS=0.067  THS=0.000
  LUT=182 FF=61 DSP=0  RAMB36E1=130  RAMB18=0
  bit SHA256=D2FC41A7869E7C4FF9B2E852C0E6E3A328E8C87EE518ACC03091BD29A3D23CA3
  prior u_a_phase_share full-66+A0.3 = 135 LIMIT (FALSIFIED) — unchanged
PASS/FAIL: PASS_NARROW — numeric BRAM/WNS/TNS met on ownership cut;
           narrow: no concurrent A0.3; MIG not re-instantiated (NG-03 BRAM=0);
           DDR corruption not silicon; DDR spill is capacity proxy not law RTL;
           WM-00 OOC WNS=-290.499 remains OPEN (not in this top)
ARTIFACT: results/A7-NATIVE-GRAPH/INTEGRATE/GATE_integrate_fit.md
NEXT: auditor / functional DDR spill RTL + optional concurrent-encoder lever;
      never overwrite frozen LM/01R/02M/A0.3; no BOARD_PASS
```

## Measured rows (provenance)

| Item | Value | Provenance | Gate |
|------|------:|------------|------|
| Device BRAM | 135 | xc7a100t | — |
| Ownership-cut BRAM | **130** | fit_own_cut_util.rpt post-route | **PASS** (prefer ≤130) |
| Ownership-cut WNS/TNS | 1.365 / 0.000 | fit_own_cut_timing.rpt | **PASS** |
| Ownership-cut WHS/THS | 0.067 / 0.000 | fit_own_cut_timing.rpt | hold OK |
| LUT / FF / DSP | 182 / 61 / 0 | fit_own_cut_util.rpt | OK |
| PE / lanes | 16 | scorer array keep | OK |
| Dual-owner write | FSM exclusive | generated top | **0 by construction** |
| MIG BRAM | 0 | NG-03 closeout (cited) | OK cited |
| DDR corruption | not measured | — | **NARROW** |
| Phase-share full-66+A0.3 | 135 | prior fit_phase_share | LIMIT (dead lever) |
| WM-00 timing | WNS=−290.499 | BRAM-WM-00 OOC | **OPEN — not bankable** |
| MAS OOC LUT | ~824% | FIT_NOTE_NG06 | excluded |
| Frozen LM/01R/02M/A0.3 | MATCH | frozen_sha_control.txt | HS-20 OK |

## Scientific frame

| Slot | Value |
|------|-------|
| OBSERVATION | u_a_phase_share FALSIFIED; share LUT OOC ~824%; WM-00 timing OPEN |
| UNKNOWN | ownership-audited ≤130 cut meet R6 numeric? |
| H_CANDIDATE | ownership-audited tile cut meets Prefer≤130 + WNS≥0 TNS=0 |
| H_RIVAL | fit only via illegal collapse / frozen overwrite / host answer |
| FALSIFIER | util>device w/o LIMIT; WNS\<0 as PASS; frozen SHA change |
| RESULT | H_CANDIDATE **SUPPORTED (NARROW)** on post-route proxy; H_RIVAL **did not fire** (frozen MATCH; no host answer path) |

## Explicit non-claims

- Not Native V1 BOARD_PASS  
- Not full MIG+LM-06 functional SoC bitstream  
- Not concurrent A0.3 + LM + graph  
- Not WM-00 100 MHz bankable (WNS=−290.499 remains OPEN)  
- Not DDR act-spill law closed (tile count proxy only)  
