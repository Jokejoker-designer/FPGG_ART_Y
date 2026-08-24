# GATE: tinygpt_consol — PASS_NARROW / LIMIT — 2026-08-22

```text
GATE: tinygpt_consol
UNKNOWN: can_TinyGPT_instantiate_on_consol_BRAM_le_135_WNS_ge_0
TESTS: live SHA MATCH consol/UA/LM06/01R/02M/A03/mig; consol util/timing; LM-06 footprint; TinyGPT hier ABSENT
EXPECTED: new TinyGPT+consol bit with pe_alive OR honest LIMIT; frozen MATCH; no BOARD_PASS
ACTUAL: consol CONTROL TinyGPT/DSP/pe_alive ABSENT; additive consol+TinyGPT BRAM 264>135; co-fit proj 132 ENGINEERING_INFERENCE only; no new bit
PASS/FAIL: PASS_NARROW (fit=FAIL / LIMIT)
ARTIFACT: results/A7-NATIVE-GRAPH/TINYGPT-CONSOL/GATE_tinygpt_consol.md
SHA256: 83A438B5342446C9E79A537196777B1BCF2468FC57F9379EA2CB8EFE0A7D3AEF (CONTROL consol; no new TinyGPT-consol bit)
```

## Scientific frame

| Slot | Value |
|------|-------|
| OBSERVATION | consol proxy co-fit capacity ≤135 (BRAM132 WNS+0.586) but no TinyGPT answer path; prior TinyGPT-SOC additive 260>135 |
| UNKNOWN | can TinyGPT/DSP (or frozen-law answer core) instantiate with consolidated memory ownership so post-route BRAM≤135 WNS≥0 TNS=0 with named TinyGPT/pe_alive evidence? |
| H_CANDIDATE | new bit with TinyGPT fabric + consol; frozen LM-06 file SHA still MATCH as control |
| H_RIVAL | pe_alive invent; capacity proxy sold as TinyGPT; overwrite frozen |
| FALSIFIER | util>135 sold as PASS; BOARD_PASS; frozen SHA change |
| CONTROL | consol 83A438B5…; UA 4451AFD9…; TinyGPT-SOC LIMIT archive |
| UNIT | one post-route composition (BRAM tiles / named fabric presence), ≠ clock cycle |
| METRICS | bram_consol, bram_lm06, bram_additive_naive, cofit_proj, dsp_consol, dsp_lm06, wns/tns, tinygpt_hier_hits, pe_alive, frozen_match |

## Measured (post-route provenance)

| Metric | Value | Provenance | Gate |
|--------|------:|------------|------|
| CONTROL consol SHA256 | `83A438B5…0A7D3AEF` | live Get-FileHash BRAM-CONSOL bit | **MATCH** |
| Consol WNS / TNS | +0.586 / 0.000 | `control_consol_timing.rpt` L141 | **PASS** (CONTROL retained) |
| Consol WHS / THS | +0.069 / 0.000 | same | **PASS** |
| Consol LUT / FF / DSP | 141 / 23 / **0** | `control_consol_util.rpt` | CONTROL |
| Consol Block RAM | **132 / 135** (headroom **3**) | util | CONTROL |
| TinyGPT hier on consol | **0** (`tiny_gpt`/`mac_array`/`gemv`/`pe_alive`) | util+hier grep | **ABSENT LIMIT** |
| Consol DSP48 hits | **0** | util | **ABSENT** |
| CONTROL UA SHA256 | `4451AFD9…EA67F40E` | live | **MATCH** |
| Frozen LM-06 SHA256 | `67C37DD5…4282E3BA` | `build/out/arty_a7_lm06.bit` | **MATCH** (HS-20) |
| LM-06 LUT / FF | 37555 / 35864 | `frozen_lm06_utilization_route.rpt` | CONTROL footprint |
| LM-06 BRAM / DSP | **132 / 154** | same | CONTROL TinyGPT footprint |
| LM-06 WNS / TNS | +0.179 / 0.000 | `frozen_lm06_timing_route.rpt` L141 | met (standalone; ≠ consol SoC) |
| Naive additive BRAM | **264 / 135** (132+132) | consol empty pool + TinyGPT wt | **FAIL** (HS-11) if stacked without share |
| Co-fit projection | **132** = max(132,132) | prior BRAM-CONSOL ENGINEERING_INFERENCE | **not** TinyGPT evidence |
| New TinyGPT+consol bit | **null** | not generated | **LIMIT** |
| pe_alive invented | **no** | 0 hier hits; no UART claim | **PASS** (H_RIVAL blocked) |
| Frozen 01R/02M/A0.3 | MATCH | `frozen_sha_control.txt` | **PASS** (HS-20) |
| BOARD_PASS | false | — | **PASS** (not declared) |
| HS-22 closed | false | TinyGPT ABSENT on consol | **OPEN** |

## Verdict on UNKNOWN

**CLOSED — PASS_NARROW / LIMIT.** H_CANDIDATE (new TinyGPT fabric + consol bit with pe_alive) **not evidenced** — consol CONTROL remains empty shared-pool proxy (DSP=0, TinyGPT hier=0). Naive stack oversubscribes (264>135). Co-fit projection ≤135 remains prior ENGINEERING_INFERENCE only — **must not** be sold as TinyGPT (H_RIVAL). Frozen SHA **MATCH**. HS-22 remains **OPEN**.

## Explicit non-claims

- HS-22 silicon LM-on-answer-path / pe_alive
- TinyGPT MAC/DSP fabric on consol CONTROL
- Semantic HS-02 held-out retrieval
- BOARD_PASS / Native V1 / §14
- Capacity proxy = TinyGPT

## NEXT

Orchestrator: mark `tinygpt_consol` DONE_ENG (honest LIMIT) after auditor allow; do **not** tick HS-22/§14 closed. Future unknown = real TinyGPT+shared-pool SoC P&R (separate RTL implementer), not inventing pe_alive on CONTROL 83A438B5.
