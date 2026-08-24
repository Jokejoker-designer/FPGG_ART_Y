# GATE: mig_h_rival (REPAIR)

**Agent:** `a7-ng-memory-arch`  
**Evidence class:** **MIG_XSIM** (Digilent AXI MIG + ddr3_model stall sweep); **not BOARD**  
**Date:** 2026-08-22  
**Law id:** `a7ng-mig-rival-v0`  
**Marker:** `A7NG_MIG_RIVAL_XSIM_PASS`

## Scientific frame

| Field | Value |
|-------|-------|
| OBSERVATION | Prior: xvlog PASS; xelab ACCESS_VIOLATION; MIG_SWEEP_ROW ABSENT; synthetic LAT=24 only |
| UNKNOWN | obtain ≥1 preregistered MIG-backed stall/throughput row (XSim after xelab fix OR board)? |
| H_CANDIDATE | MIG_SWEEP_ROW archived with Digilent AXI path |
| H_RIVAL | still only synthetic LAT=24 |
| FALSIFIER | invent GB/s; hand-edit mig.prj; BOARD_PASS |
| UNIT | sweep cell (burst × outstanding) — (1,1) and (4,8), TOTAL=64 |
| CONTROL | DDR-FEED synthetic; mig.prj SHA MATCH PortInterface=AXI; frozen LM-06/01R/02M/A0.3 MATCH |
| METRICS | PE stall_frac; recs/cycle; DROP; ddr_rd_bytes |

## Verdict

**PASS_NARROW.** H_RIVAL **FALSIFIED**.

- xelab fix: Vivado 2026.1 needs `-mt off -O0` (default → `EXCEPTION_ACCESS_VIOLATION` after static elab).  
- Digilent AXI `mig.prj` **unchanged** (SHA `870FA6EE…`; PortInterface=AXI; no `app_*`).  
- MIG_SWEEP_ROW archived: (1,1) stall=**0.958710**; (4,8) stall=**0.549296**; DROP=0.  
- H_CANDIDATE **supported** (rows on Digilent AXI path).  
- H_RIVAL ("synthetic only") **FALSIFIED**.  
- Synthetic CONTROL retained for comparison — do **not** claim synthetic 0.475410 = MIG.  
- **No BOARD_PASS. No HS-02. No invented GB/s.**

Falsifiers did **not** fire.

## Headline

| Claim | Grade |
|-------|-------|
| MIG (1,1)/(4,8) stall_frac | **EVIDENCE** MIG_XSIM (`MIG_SWEEP_ROW.md`) |
| Synthetic 0.961544→0.475410 | **CONTROL** only — not MIG equality |
| Digilent AXI mig.prj untouched | **EVIDENCE** SHA MATCH |
| Board PE stall / silicon | **ABSENT** (deferred) |
| BOARD_PASS | **REFUSED** |

## CHANGED (this repair)

| Path | Role |
|------|------|
| `tests/xsim/run_a7ng_ddr_feed_mig.tcl` | xelab `-mt off -O0` |
| `results/A7-NATIVE-GRAPH/MIG-RIVAL/**` | xelab_repair_O0, xsim_mig_rival, MIG_SWEEP_ROW, GATE/LIMIT/WAITING |
| `docs/native_graph/RESOURCE_BUDGET.md` | measured MIG stall rows |

**NOT changed:** `mig.prj`; frozen LM-06/01R/02M/A0.3 bits; synthetic DDR-FEED RTL.

## TESTS

| ID | Result |
|----|--------|
| xvlog MIG+feed+ddr3_model | PASS (`xvlog_repair.log`) |
| xelab default (no -O0) | FAIL tool ACCESS_VIOLATION (prior archive) |
| xelab `-mt off -O0` | PASS (`xelab_repair_O0.log`) |
| xsim runall | PASS — `A7NG_MIG_RIVAL_XSIM_PASS` |
| MIG_SWEEP_ROW cells | PASS — 2 rows DROP=0 |
| mig.prj hand-edit | PASS (no edit; SHA MATCH) |
| Frozen SHA control | MATCH all |
| BOARD_PASS / invent GB/s | REFUSED |

## SHA256 (primary)

`EE52D9C4C1A5E5106A7C996379A3CAE06C031D5FC62D9FA577E97308084ACBF1  a7ng_ddr_feed_mig_top.sv`  
`870FA6EEC23436FA8AD2A8772A80865016807CA37542C0C994E9E1E88152190D  mig.prj`  
(full: `SHA256.txt`)

## NEXT

1. Parent verify trio / auditor — expect allow_loop_done_eng if H_RIVAL FALSIFIED + MIG rows accepted.  
2. Optional: board silicon ddr_feed stall UART (still not claimed).  
No BOARD_PASS. No full HS-02.
