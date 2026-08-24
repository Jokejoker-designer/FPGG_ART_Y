# GATE — wm00_timing (A7-BRAM-WM-00 OOC timing close)

**Agent:** `a7-ng-memory-arch`  
**Gate:** `wm00_timing`  
**Date:** 2026-08-22  
**Board:** Digilent Arty A7-100T / xc7a100tcsg324-1  
**Evidence_class:** XSIM + OOC_POST_ROUTE (DERIVED) — **not BOARD**, not silicon

## Scientific frame (ONE UNKNOWN)

| Slot | Value |
|------|-------|
| OBSERVATION | WM-00 XSim lossless PASS; prior OOC WNS≈−290.499 not bankable |
| UNKNOWN | Can one timing-focused change (pipeline Top-8) raise OOC WNS≥0 and TNS=0 while keeping lossless XSim and frozen bits MATCH? |
| H_CANDIDATE | New archive with WNS≥0 TNS=0 + lossless marker |
| H_RIVAL | Claim bankable while WNS&lt;0; overwrite frozen |
| FALSIFIER | Lossless regress; frozen SHA change; BOARD_PASS language |
| UNIT | WM query/seed bag (TOP8 + prior 8-bag suite); OOC post-route timing summary |
| CONTROL | Prior BRAM-WM-00 lossless + `CONTROL_timing_route_wns_neg290.rpt` WNS=−290.499 |
| METRICS | WNS, TNS, LUT/FF/BRAM/DSP, XSim marker, frozen SHA |

## ONE change

Systolic pipeline in `a7ng_wm00_evidence.sv`: 1× dedupe cycle + K=8 compare/swap stages (one compare per cycle) + `ready_o` handshake. Exact Top-8 law unchanged (higher score, then lower node_id; same-node invalidate before insert). TB waits on `ev_ready_o`.

## Results

| Metric | Control | This gate | Grade |
|--------|---------|-----------|-------|
| XSim marker | `A7NG_BRAM_WM00_XSIM_PASS` | **PASS** (all 8 bags; TOP8 31..24) | EVIDENCE |
| OOC WNS @100 MHz | −290.499 FAIL | **+0.069** | EVIDENCE |
| OOC TNS | −108584.445 FAIL | **0.000** | EVIDENCE |
| Constraints | not met | **All user specified timing constraints are met** | EVIDENCE |
| LUT / FF / BRAM / DSP | 10238 / 7359 / 0 / 0 | **2990 / 7493 / 0 / 0** | EVIDENCE |
| Frozen LM-06/01R/02M/A0.3 | MATCH | **MATCH** | EVIDENCE |
| Schema SHA | F0FE426E… | **MATCH** | EVIDENCE |

## Verdict

```text
result: PASS_NARROW
H_CANDIDATE: SUPPORTED (OOC WNS>=0 TNS=0 + lossless XSim)
H_RIVAL: FALSIFIED (no WNS<0 claim; frozen MATCH)
BOARD_PASS: NOT DECLARED
BRAM_WORKING_MEMORY_ARCH_PASS (§45): NOT DECLARED
LIMIT: OOC WM-only @ create_clock 10ns; not full SoC / LM-06 integrate; not silicon
```

**PASS_NARROW** — unknown closed for WM-00 OOC bankability; do not conflate with NATIVE_V1 / BOARD_PASS / 100 MHz SoC claim.
