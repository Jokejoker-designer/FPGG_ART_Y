# GATE — bram_consolidate

```text
GATE: bram_consolidate
UNKNOWN: can one consolidation (DDR spill or WM share of wt and/or act) free enough BRAM that projected TinyGPT+remainder ≤135 Prefer WNS≥0 without overwriting frozen LM-06?
TESTS: post-route consol proxy SHARED_TILES=132 (WM phase-share); CONTROL UA/LM06/mig SHA MATCH; co-fit projection vs additive 260
EXPECTED: headroom≥132 OR co-fit PASS_NARROW; honest FAIL/PASS_NARROW/LIMIT; no BOARD_PASS; HS-22 not closed from proxy alone
ACTUAL: measured BRAM=132/135 WNS=+0.586 TNS=0; co-fit proj=132≤135 (collapses additive 260); frozen MATCH; mig.prj AXI MATCH untouched
PASS/FAIL: PASS_NARROW
ARTIFACT: results/A7-NATIVE-GRAPH/BRAM-CONSOL/
SHA256(consol.bit): 83A438B5342446C9E79A537196777B1BCF2468FC57F9379EA2CB8EFE0A7D3AEF
```

## Scientific frame

| Slot | Value |
|------|-------|
| OBSERVATION | TinyGPT cannot co-reside with full on-chip wt+u_a (UA BRAM128 headroom7; TinyGPT132; additive260>135) |
| UNKNOWN | one consolidation frees enough BRAM for TinyGPT+remainder ≤135 Prefer WNS≥0 without frozen overwrite? |
| H_CANDIDATE | post-route (or honest util + measured consol) shows headroom≥132 or co-fit PASS_NARROW |
| H_RIVAL | paper headroom without RTL; invent pe_alive; hand-edit mig.prj |
| FALSIFIER | frozen overwrite; BOARD_PASS; util>135 sold as PASS |
| CONTROL | UA `4451AFD9…`; TinyGPT LIMIT archive; mig.prj MATCH AXI |
| UNIT | one post-route composition (device BRAM tiles), ≠ clock cycle |
| LEVER (one) | **WM phase-share of wt AND act** into TinyGPT-sized shared pool (132) |

## Measured (POST_ROUTE_PROXY)

| Metric | Value | Provenance |
|--------|------:|------------|
| Consol BRAM tiles | **132 / 135** | `consol_util.rpt` |
| RAMB36E1 | 132 | cell count |
| WNS / TNS | **+0.586 / 0.000** | Tcl / `consol_timing.rpt` |
| WHS / THS | +0.069 / 0.000 | same |
| LUT / FF / DSP | 153 / 23 / 0 | util (proxy glue) |
| Additive CONTROL | 128+132=**260** | TinyGPT-SOC LIMIT |
| Co-fit projection | **132** = max(128,132) shared | ENGINEERING_INFERENCE + measured pool |
| Headroom after | 3 | 135−132 |
| Prefer ≤130 | not met (132) | documented; device ≤135 OK |
| Frozen LM-06 / UA / mig | **MATCH** | `frozen_sha_control.txt` |
| mig.prj PortInterface | AXI; app_*=0 | Digilent path; **untouched** (WM share ≠ DDR spill) |
| BOARD_PASS | false | — |
| HS-22 closed | **false** | TinyGPT answer-path not in this proxy |

## Verdict on UNKNOWN

**CLOSED as PASS_NARROW (co-fit path).** H_CANDIDATE supported for **capacity**: measured shared pool 132≤135 Prefer WNS≥0 collapses additive 260. Headroom≥132 path **not** claimed (headroom_after=3). H_RIVAL did not fire.

## Explicit non-claims

- Not full TinyGPT+UA SoC with DSP/answer path / pe_alive
- Not HS-22 LM-on-answer-path closed
- Not BOARD_PASS / Native V1
- Not Digilent MIG silicon DDR spill (lever was WM share; mig untouched)
- Prefer≤130 soft target not met — device hard limit ≤135 is met
