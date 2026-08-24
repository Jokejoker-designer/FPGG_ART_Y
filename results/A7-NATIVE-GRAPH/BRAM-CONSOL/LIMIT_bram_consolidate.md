# LIMIT / NARROW — bram_consolidate

**Gate:** `bram_consolidate`  
**Agent:** `a7-ng-memory-arch`  
**Device:** Digilent Arty A7-100T `xc7a100tcsg324-1`  
**Evidence_class:** `POST_ROUTE_PROXY` + co-fit `ENGINEERING_INFERENCE`  
**board_pass:** false  
**hs22_closed:** false  

## What PASS_NARROW means here

| Claim | Status |
|-------|--------|
| Measured consol shared pool BRAM ≤135 Prefer WNS≥0 | **YES** — 132 tiles, WNS=+0.586 |
| Co-fit projection TinyGPT+remainder ≤135 under WM share | **YES** — shared max(128,132)=132 |
| Additive TinyGPT+UA without consol | still **260>135 LIMIT** (unchanged CONTROL) |
| Prefer soft ≤130 | **NOT met** (132) — documented, not sold as soft-prefer PASS |
| Headroom ≥132 free tiles | **NO** — headroom_after=3; co-fit path used instead |
| HS-22 TinyGPT on answer path | **OPEN** |
| Full SoC TinyGPT+DSP+UA co-P&R | **ABSENT** (proxy only) |

## Why not FAIL

Falsifiers did not fire: frozen LM-06/UA/mig MATCH; no util>135 as PASS; no pe_alive invent; no BOARD_PASS.

## Why not full PASS / HS-22 close

Consol block proves **tile-capacity** of one WM-shared pool sized to TinyGPT footprint. It does **not** instantiate TinyGPT MAC/DSP, UART pe_alive, or semantic answer path. HS-22 remains OPEN until a real answer-path fit is evidenced.

## Lever choice

**WM phase-share of wt+act** (not DDR spill this gate). Digilent AXI `mig.prj` left MATCH/untouched. Future DDR spill of residual banks remains a separate unknown if soft Prefer≤130 or encoder co-fit is required.
