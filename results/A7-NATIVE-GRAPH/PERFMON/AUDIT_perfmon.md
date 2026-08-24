# AUDIT — perfmon (VERIFY_ONLY)

**Auditor:** `a7-evidence-auditor`  
**Mode:** READ_ONLY_AUDIT / VERIFY_ONLY (no RTL edit; no LOOP_STATE flip)  
**Date:** 2026-08-22  
**Evidence_class:** **XSIM** (not BOARD, not silicon)  
**GATE:** `perfmon`  
**LOOP_STATE:** first OPEN / `next` = `perfmon` (matches this audit)  
**Implementer DISPATCH:** `a7-ng-scientific` / `PASS` / marker `A7NG_PERFMON_XSIM_PASS` / share control `4413C74B…`  
**Refuse rule:** DONE_ENG allow **false** if share/frontier/topk law changed OR counters not file-backed.

```text
MUST_READ_UNBLOCK_H5: read. Next = ungated DIFF twin (not S2, not glue).
BLUEPRINT_LOOP: read. Goal=NATIVE_V1_MINI_AI_BOARD_PASS. Next=perfmon
```

---

## Verdict

```text
AUDIT: 2 FINDINGS
result: PASS
allow_loop_done_eng: true
severity_metrics: share SHA=4413C74B (control match); frontier/topk SHA frozen; PERFMON dump file-backed in xsim_perfmon.log; Evidence_class=XSIM
```

Instrumentation-only unknown closed under XSIM. Share/frontier/topk **laws unchanged** (SHA-locked). Counters appear in on-disk XSim log (+ `PERFMON_DUMP.txt`).  
H_RIVAL **dispatch/law confounder** falsified by SHA + share regress; **timing critical-path** not measured (MINOR).  
**Do not declare BOARD_PASS.** Orchestrator may flip LOOP — this auditor does **not**.

---

## Declared scientific frame (graded)

| Slot | Declared (GATE_perfmon) | Auditor grade |
|------|-------------------------|---------------|
| OBSERVATION | wide+epoch DONE_ENG; bottlenecks guessed without HW counters | **EVIDENCE** (prior DONE_ENG + this gate) |
| UNKNOWN | PERFMON-lite expose counters without changing search/learn law? | **Closed YES** — **EVIDENCE** |
| H_CANDIDATE | counters on share/frontier/topk path sufficient for later bags | **SUPPORTED (smoke)** — **EVIDENCE** (increments only) |
| H_RIVAL | counters sit on critical path / change dispatch semantics | **Partially falsified** — see finding #1 |
| FALSIFIER | N_WAY util or DROP_STALE regress vs frozen SHAs; or law id change | **Did not fire** — **EVIDENCE** |
| UNIT | counter dump per run/seed — not cycles-as-queries | **EVIDENCE** (one seed bag; dump logged) |
| CONTROL | share SHA `4413C74B…` untouched | **EVIDENCE** (recomputed) |
| METRICS | lane_busy, jobs, qocc, starve, stale, idle/conflict, frontier/topk | **EVIDENCE** (file-backed); cand_out semi-synthetic — finding #2 |

---

## Dispatch / loop law

| Check | Outcome |
|-------|---------|
| `DISPATCH_LOG` implementer PASS for `perfmon` | **PASS** — agent=`a7-ng-scientific` result=`PASS` artifact=`GATE_perfmon.md` |
| Agent vs `run_blueprint_loop.py` FALLBACK | **PASS** — `perfmon` → `a7-ng-scientific` |
| `LOOP_STATE.next` / first OPEN | **PASS** — `perfmon` |
| Parent claimed BOARD_PASS | **PASS** — none |
| Evidence_class mixed with board/silicon | **PASS** — XSIM only |
| Auditor is VERIFY_ONLY (no LOOP flip) | **PASS** — this file |

Refuse “no implementer PASS” → **does not apply**.

---

## Law / SHA immutability (refuse gate)

Auditor recomputed SHA256 of live trees (2026-08-22):

| File | Live SHA256 | Prior freeze | Match |
|------|-------------|--------------|-------|
| `rtl/native_graph/share/a7ng_multi_agent_share.sv` | `4413C74B442CA5A4CD9D0EE6E71BE71EE3067677BB42F327BB90EDAAFB3B9EB6` | NG-06R-EPOCH control | **YES** |
| `rtl/native_graph/frontier/a7ng_frontier_buckets.sv` | `CE38FEC3562343C64AB718243CE5F4B815A128524EBA2903BE20CD5ACDD2C565` | NG-02R-FLOW | **YES** |
| `rtl/native_graph/topk/a7ng_topk.sv` | `F671FCB1B8FB891EE77A9AC3D5A0BA24AE4DBB8109A6645F2250F611AA197636` | NG-02R-TOPK / FLOW | **YES** |
| `rtl/native_graph/perfmon/a7ng_perfmon.sv` | `954DF536F22A01F0BF2B25809DF506725A0D34C05D47FE70D52389DDB2E92B07` | NEW observer | listed in `SHA256.txt` |

Law headers still: `a7ng-share-v1`, `a7ng-frontier-v0`, `a7ng-topk-global-v1`.  
Observer RTL (`a7ng_perfmon.sv`) has **no outputs** into grant/dispatch — taps only.

**Share regress control:** `xsim_share_control.log` → `A7NG06_SHARE_XSIM_PASS` (`drop_stale=0`, phys=16, logical=256).  
`SHARE_SHA_CONTROL.txt` = `SHARE_SHA_CONTROL_MATCH`.

**Refuse (law changed):** **NO** → does not block DONE_ENG.

---

## Counters file-backed (refuse gate)

| Artifact | Content | Class |
|----------|---------|-------|
| `xsim_perfmon.log` | full Vivado/XSim; `PERFMON_DUMP` + `PERFMON_LANE` + `A7NG_PERFMON_XSIM_PASS` | **EVIDENCE** |
| `PERFMON_DUMP.txt` | same dump lines (plus TCL session noise) | **EVIDENCE** (secondary) |
| `GATE_perfmon.md` ACTUAL dump | matches log | **EVIDENCE** |

TB `$display`s counters from DUT outputs; log is on disk under `results/A7-NATIVE-GRAPH/PERFMON/`.

**Refuse (counters not file-backed):** **NO** → does not block DONE_ENG.

---

## Primary metrics (re-derived from raw log)

Source: `xsim_perfmon.log` lines 78–96 (not GATE prose).

| Metric | Value | Note |
|--------|-------|------|
| cycles | **67** | enable window |
| jobs / grants path | **16** | one wide matched-epoch push |
| qocc_acc | **17** | non-zero |
| idle / conf | **65** / **0** | idle moves |
| starve / stale | **0** / **1** | one injected stale DROP |
| fr_push / fr_pop / fr_full | **18** / **18** / **2** | frontier activity |
| tk_bat / cand_in / cand_out | **8** / **128** / **64** | 8×16 in; out = 8×K |
| lane_busy_accum[0..15] | **2** each | non-zero all lanes |
| Marker | `A7NG_PERFMON_XSIM_PASS` | present |

**FACT:** Dump in GATE matches `xsim_perfmon.log` bit-for-bit on these fields.  
**FACT:** Gate proves **instrumentation increments**, not usefulness / optimizer / candidates/s (GATE correctly disclaims).

---

## Findings

```
[MINOR] H_RIVAL “critical-path” overclaimed relative to evidence
  where     : results/A7-NATIVE-GRAPH/PERFMON/GATE_perfmon.md:23
  claim      : “H_RIVAL falsified … counters sit on critical path / change dispatch”
  evidence   : Falsifier executed = share SHA freeze + A7NG06_SHARE_XSIM_PASS + observer-only RTL.
               No WNS/TNS / post-route path report tying PERFMON into timing.
  why it matters: Reader may think silicon timing confounder is closed; only dispatch/law confounder is.
  fix        : Narrow claim to “H_RIVAL dispatch/law confounder falsified (XSIM); timing critical-path OPEN until integrate timing.”

[MINOR] candidates_out is K-hardwired, not measured Top-K egress
  where     : tests/xsim/tb_a7ng_perfmon.sv:121  (.candidates_out_i(4'(K)))
  claim      : METRICS include candidates_out as Top-K tap
  evidence   : Accumulator always adds K=8 on each tk_valid_i; cand_out=64 ≡ 8 batches × 8.
               Does not sample DUT valid_o / actual emitted count.
  why it matters: Later bags could treat cand_out as measured throughput; it is a parameter echo.
  fix        : Wire measured egress (e.g. popcount of valid outs) or label metric `candidates_out_expected_k`.
```

No CRITICAL / MAJOR. No frozen-bit overwrite. No host answer path. No BOARD_PASS self-declare.

---

## DONE_ENG allow decision

| Condition | Result |
|-----------|--------|
| share/frontier/topk law changed | **false** (SHA + law ids) |
| counters not file-backed | **false** (`xsim_perfmon.log` dump) |
| **allow_loop_done_eng** | **true** |

---

## NOT VERIFIED

- Post-route / WNS impact of instantiating `a7ng_perfmon` in a full SoC (no synth/impl this gate).
- Multi-seed / multi-bag stability of counters (single smoke bag).
- Whether `PERFMON_DUMP.txt` was produced by a dedicated `$fopen` vs log scrape (log is authoritative).
- Board / silicon — **out of scope**; Evidence_class=XSIM only.
- LOOP_STATE flip — intentionally **not** performed by this auditor.
