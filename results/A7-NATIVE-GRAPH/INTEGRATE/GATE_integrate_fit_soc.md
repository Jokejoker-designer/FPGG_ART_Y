# GATE: integrate_fit — PASS_NARROW (FULL SoC reopen)

```text
GATE: integrate_fit
CHANGED: rtl/board/arty_a7_ng_integrate_soc_top.sv;
         rtl/native_graph/integrate/a7ng_lm_graph_arb.sv;
         rtl/native_graph/integrate/a7ng_exam_uart_stub.sv;
         vivado/tcl/native_graph/measure_integrate_fit_soc.tcl;
         NEW bit soc only (proxy own_cut retained)
WHY: ONE UNKNOWN — real MIG+LM-arb+graph/cache+PE DONT_TOUCH+UART stub
     meet BRAM<=device WNS>=0 TNS=0 with PE measured post-route?
TESTS: measure_integrate_fit_soc.tcl (post-route)
EXPECTED: BRAM<=135 (prefer<=130) AND WNS>=0 AND TNS=0; PE>=16 fabric;
          bit SHA != proxy D2FC41A7…; frozen MATCH; no BOARD_PASS
ACTUAL (post-route provenance):
  LUT=5695 FF=5903 BRAM_Tile=0/135 DSP=0
  WNS=0.952 ns  TNS=0.000  WHS=0.012  THS=0.000
  PE lanes=16 (fit_soc_util_hier.rpt u_sc g_lane[0..15]; LUT=1046 FF=1856)
  bit SHA256=D65F3524BE1BD53D6B461CD8CD872DDCF8DE04EC4B7B0C8FB4CA4F959559A4DF
  proxy CONTROL SHA D2FC41A7… MATCH retained
  frozen LM/01R/02M/A0.3 MATCH
PASS/FAIL: PASS_NARROW — numeric BRAM/WNS/TNS + PE fabric met on FULL SoC top;
           LIMIT: LM-06 weight fabric ABSENT (arb+compose only; HS-22 OPEN);
           UART exam stub present; blind HS-02 exam DEFERRED to teacher_off_exam;
           residual66+shared64 ownership BRAM model not re-forced (BRAM=0 real MIG path)
ARTIFACT: results/A7-NATIVE-GRAPH/INTEGRATE/GATE_integrate_fit_soc.md
NEXT: auditor VERIFY_ONLY; teacher_off_exam may use this SoC+UART stub (not proxy);
      never overwrite frozen; no BOARD_PASS; do not program proxy as HS-02
```

## Measured rows (provenance = post-route SoC)

| Item | Value | Provenance | Gate |
|------|------:|------------|------|
| Device BRAM | 135 | xc7a100t | — |
| SoC BRAM | **0** | fit_soc_util.rpt | **PASS** (prefer ≤130) |
| SoC WNS/TNS | 0.952 / 0.000 | fit_soc_timing.rpt | **PASS** |
| SoC WHS/THS | 0.012 / 0.000 | fit_soc_timing.rpt | hold OK |
| LUT / FF / DSP | 5695 / 5903 / 0 | fit_soc_util.rpt | OK / DSP=0 |
| PE / lanes | **16** | fit_soc_util_hier.rpt `u_sc` 16×`g_lane` | **PASS** (fabric) |
| PE LUT/FF under `u_sc` | 1046 / 1856 | same hier rpt | EVIDENCE |
| MIG | instantiated | arty_a7_ng_integrate_soc_top + NG-03 wrap | EVIDENCE |
| LM-06 weight fabric | ABSENT | by design (132 BRAM alone) | **LIMIT** |
| LM arb + evidence compose | present | u_arb + u_compose | EVIDENCE path stub |
| UART exam stub | present | u_exam status 0x91 HS-02 flags | stub; exam DEFERRED |
| Dual-owner | 0 by construction | a7ng_lm_graph_arb | OK |
| Proxy own_cut | D2FC41A7… | retained CONTROL | MATCH |
| Frozen LM/01R/02M/A0.3 | MATCH | frozen_sha_soc.txt | HS-20 OK |

## Scientific frame

| Slot | Value |
|------|-------|
| OBSERVATION | proxy own_cut BRAM130 WNS+1.365 LUT≈182; PE optimized away; not HS-02 path |
| UNKNOWN | real integrated design meet BRAM/WNS/TNS + PE measured + UART stub? |
| H_CANDIDATE | full SoC (or honest LIMIT) ≠ proxy SHA D2FC41A7… |
| H_RIVAL | retick proxy as SoC; program proxy for teacher-off |
| FALSIFIER | frozen overwrite; PE sold as 16 when optimized away; BOARD_PASS self-declared |
| RESULT | H_CANDIDATE **SUPPORTED (NARROW)** — SoC bit D65F3524…; PE=16 fabric; H_RIVAL **did not fire**; LIMIT LM-06 fabric / blind exam deferred |

## Explicit non-claims

- Not `NATIVE_V1_MINI_AI_BOARD_PASS` / not AI-declared BOARD_PASS  
- Not full LM-06 weight fabric on this bit (HS-22 still OPEN for §14 LM path)  
- Not silicon HS-02 blind exam (UART stub only; teacher_off_exam next)  
- Not WM-00 bankable (WNS=−290.499 OOC still OPEN)  
- Not residual66+shared64 forced-RAMB ownership cut (that remains proxy CONTROL)  
- Proxy bit must **not** be programmed as HS-02 vehicle  
