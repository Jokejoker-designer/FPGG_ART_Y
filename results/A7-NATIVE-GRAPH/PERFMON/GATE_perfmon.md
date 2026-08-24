# GATE: perfmon (PLAN B2 / feedback §21)

**Agent:** `a7-ng-scientific`  
**Evidence class:** XSIM (not BOARD)  
**Marker:** `A7NG_PERFMON_XSIM_PASS`  
**Date:** 2026-08-22

## Scientific frame

| Field | Value |
|-------|-------|
| OBSERVATION | wide+epoch DONE_ENG; bottlenecks guessed without HW counters |
| UNKNOWN | can PERFMON-lite expose preregistered counters without changing search/learn law? |
| H_CANDIDATE | counters on share/frontier/topk path sufficient for later bags |
| H_RIVAL | counters sit on critical path / change dispatch semantics |
| FALSIFIER | N_WAY util or DROP_STALE regress vs frozen SHAs; or law id change |
| UNIT | counter dump per run/seed — not cycles-as-queries |
| CONTROL | share SHA `4413C74B442CA5A4CD9D0EE6E71BE71EE3067677BB42F327BB90EDAAFB3B9EB6` (untouched) |
| METRICS | lane_busy, jobs/cycle, queue_occ, starve, stale_drop, scheduler idle/conflict (+ frontier/topk) |

## Verdict

**PASS (engineering / XSIM).** H_RIVAL falsified for this gate: share RTL SHA unchanged; share TB regress `A7NG06_SHARE_XSIM_PASS`; PERFMON is observer-only (no grant-path edit, no law_id change).

`FITS != RUNS != TRAINS != CONVERGES != USEFUL` — this gate proves **instrumentation runs and increments**, not usefulness of any optimizer.

## CHANGED

| Path | Role |
|------|------|
| `rtl/native_graph/perfmon/a7ng_perfmon.sv` | NEW observer accumulator |
| `tests/xsim/tb_a7ng_perfmon.sv` | NEW smoke TB (share+frontier+topk taps) |
| `tests/xsim/run_a7ng_perfmon.tcl` | NEW XSim runner |
| `docs/native_graph/TEST_MATRIX.md` | PM-X1/X2/C1/C2 rows |

**NOT changed:** `a7ng_multi_agent_share.sv`, frontier, topk, learn RTL, frozen 01R/02M/LM-06/A0.3.

## TESTS

| ID | Result |
|----|--------|
| PM-X1 `run_a7ng_perfmon.tcl` | PASS `A7NG_PERFMON_XSIM_PASS` |
| PM-C1 share SHA control | MATCH `4413C74B…` |
| Share regress `tb_a7ng_multi_agent_share` | PASS `A7NG06_SHARE_XSIM_PASS` |

## ACTUAL dump (seed bag)

```text
cycles=67 jobs=16 qocc_acc=17 idle=65 conf=0 starve=0 stale=1
fr_push=18 fr_pop=18 fr_full=2 tk_bat=8 cand_in=128 cand_out=64
lane_busy_accum[0..15]=2 each
```

## SHA256 (primary)

`954DF536F22A01F0BF2B25809DF506725A0D34C05D47FE70D52389DDB2E92B07  a7ng_perfmon.sv`  
(full list: `SHA256.txt`)

## NEXT

Pipeline next after this PASS: parent `--dispatch` (likely `mem_schema_v1` / `reset_00` still BLOCKED_BY perfmon until STATUS flip). No BOARD_PASS.
