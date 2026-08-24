# GATE: ddr_feed (A7-BRAM-WM-01)

**Agent:** `a7-ng-memory-arch`  
**Evidence class:** XSIM (synthetic latency DDR — **not MIG**, **not BOARD**)  
**Marker:** `A7NG_DDR_FEED_XSIM_PASS`  
**Date:** 2026-08-22  
**Law id:** `a7ng-ddr-feed-wm01-v0`

## Scientific frame

| Field | Value |
|-------|-------|
| OBSERVATION | WM-00 lossless XSim with synthetic DDR; PE may stall without burst/pingpong/outstanding |
| UNKNOWN | does ping-pong DDR→WM feed with swept burst{1,4,8,16} × outstanding{1,2,4,8} reduce PE stall vs baseline single-issue? |
| H_CANDIDATE | double-buffer + burst + multi-outstanding improves effective recs/cycle / lowers stall fraction |
| H_RIVAL | synthetic model hides real MIG latency; numbers are artifactual |
| FALSIFIER | stall not reduced across sweep; DROP>0; LM-06/frozen SHA changed |
| UNIT | sweep cell (burst × outstanding × seed) — not cycles-as-queries |
| CONTROL | WM-00 top SHA `1F7F3950…` MATCH; mem_schema `F0FE426E…` MATCH; frozen LM-06/01R/02M/A0.3 MATCH |
| METRICS (preregistered) | PE stall fraction; effective records/cycle; buffer empty/full stalls; DDR bytes/bursts |

## Verdict

**PASS (engineering / XSIM).** H_CANDIDATE **SUPPORTED** under synthetic LATENCY=24: baseline (burst=1,out=1) stall_frac=**0.961544** → best (burst=4,out=8) stall_frac=**0.475410** (−50.6% relative); recs/cycle **0.038456 → 0.524590** (×13.6). DROP=0 all 32 cells. Frozen SHAs MATCH.

H_RIVAL **OPEN** (not falsified): model is fixed-latency synthetic, not Digilent MIG — do not promote as board bandwidth.

**No 100 MHz timing claim.** WM-00 OOC WNS=−290.499 remains OPEN. No BOARD_PASS. No LM-06. No PE count increase. No integrate_fit / TermGen / TRAIN-V2 / HNSW.

## CHANGED

| Path | Role |
|------|------|
| `rtl/native_graph/memory/a7ng_ddr_feed_lat_ddr.sv` | NEW — latency + burst + multi-outstanding synth DDR |
| `rtl/native_graph/memory/a7ng_ddr_feed_pp.sv` | NEW — ping/pong banks + stall telemetry |
| `rtl/native_graph/memory/a7ng_ddr_feed_top.sv` | NEW — glue + 16-PE pull (N_PE frozen) |
| `tests/xsim/tb_a7ng_ddr_feed.sv` | NEW — 4×4×2 sweep |
| `tests/xsim/run_a7ng_ddr_feed.tcl` | NEW |
| `docs/native_graph/RESOURCE_BUDGET.md` | DDR-FEED measured table |
| `docs/native_graph/TEST_MATRIX.md` | ddr_feed rows |

**NOT changed:** WM-00 RTL SHA; mem_schema; LM-06/01R/02M/A0.3 bits; PE count; integrate_fit.

## TESTS

| ID | Result |
|----|--------|
| Sweep 32 cells DROP=0 | PASS |
| Baseline stall_frac (1,1) | 0.961544 |
| Best stall_frac (4,8) | 0.475410 |
| Stall reduced ≥10% rel | PASS (−50.6%) |
| Frozen SHA control | MATCH all |
| Marker | `A7NG_DDR_FEED_XSIM_PASS` |

## Headline numbers (seed 0)

| burst | out | stall_frac | recs/cyc | cycles | ddr_bursts |
|------:|----:|-----------:|---------:|-------:|-----------:|
| 1 | 1 | 0.961544 | 0.038456 | 6657 | 256 |
| 1 | 8 | 0.721739 | 0.278261 | 920 | 256 |
| 4 | 8 | **0.475410** | **0.524590** | 488 | 64 |
| 8 | 4 | 0.475410 | 0.524590 | 488 | 32 |
| 16 | 2 | 0.475410 | 0.524590 | 488 | 16 |

Full table: `sweep_table.txt` / `xsim_ddr_feed.log`.

## SHA256 (primary)

`EE57D1BC1E216EEE5B9FFF6D42EA7B87254A5F57EDE7E0F65D298E35F2125D60  a7ng_ddr_feed_top.sv`  
(full list: `SHA256.txt`)

## NEXT

Parent verify trio / `--dispatch`. Likely `frontier_shootout` (was BLOCKED by ddr_feed). No BOARD_PASS.
