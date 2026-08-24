# AUDIT — ddr_feed (VERIFY_ONLY)

**Auditor:** `a7-evidence-auditor`  
**Mode:** READ_ONLY_AUDIT / VERIFY_ONLY (no RTL edit; no LOOP_STATE flip)  
**Date:** 2026-08-22  
**Evidence_class:** **XSIM** (synthetic fixed-latency DDR model — **not MIG**, **not BOARD**, **not silicon**)  
**GATE:** `ddr_feed` / A7-BRAM-WM-01  
**LOOP_STATE:** first OPEN / `next` = `ddr_feed` (matches this audit)  
**Implementer DISPATCH:** `a7-ng-memory-arch` / `PASS` / marker `A7NG_DDR_FEED_XSIM_PASS` / primary `EE57D1BC…`  
**Refuse rule:** DONE_ENG allow **false** if stall headline claimed as MIG/board bandwidth, H_RIVAL closed without MIG evidence, DROP>0, frozen SHA drift, Evidence_class mixed with board/silicon, 100 MHz / BOARD_PASS claimed, or XSim marker absent.

```text
MUST_READ_UNBLOCK_H5: read. Next = ungated DIFF twin (not S2, not glue).
BLUEPRINT_LOOP: read. Goal=NATIVE_V1_MINI_AI_BOARD_PASS. Next=ddr_feed
```

---

## Verdict

```text
AUDIT: 2 FINDINGS
result: PASS
allow_loop_done_eng: true
severity_metrics: baseline_stall=0.961544→best=0.475410 EVIDENCE under synthetic LATENCY=24 only; H_RIVAL OPEN (not MIG); DROP=0/32; frozen LM-06/01R/02M/A0.3 + WM-00 + schema MATCH; no 100MHz; no BOARD_PASS; Evidence_class=XSIM
```

H_CANDIDATE (ping-pong + burst + multi-outstanding lowers PE stall vs single-issue) **SUPPORTED** under **synthetic LATENCY=24** — **EVIDENCE** (XSim log + CSV).  
H_RIVAL (synthetic hides real MIG) remains **OPEN** — correctly **not** falsified.  
**Do not declare BOARD_PASS.** **Do not promote stall 0.96→0.47 as MIG / board GB/s.**  
Orchestrator may flip LOOP — this auditor does **not**.

---

## Declared scientific frame (graded)

| Slot | Declared (GATE_ddr_feed) | Auditor grade |
|------|--------------------------|---------------|
| OBSERVATION | WM-00 lossless XSim with synth DDR; PE may stall without burst/pp/outstanding | **EVIDENCE** (prior BRAM-WM-00 + this gate) |
| UNKNOWN | does burst×outstanding + ping-pong reduce PE stall vs baseline? | **Closed YES (synthetic)** — **EVIDENCE** |
| H_CANDIDATE | double-buffer + burst + multi-outstanding lowers stall | **SUPPORTED (synthetic)** — **EVIDENCE** |
| H_RIVAL | synthetic model hides real MIG; numbers artifactual | **OPEN** — **EVIDENCE** that claim is open; **not** MIG-tested |
| FALSIFIER | stall not reduced; DROP>0; frozen SHA changed | **Did not fire** — **EVIDENCE** |
| UNIT | sweep cell (burst × outstanding × seed) | **PARTIAL** — burst/out vary; seed axis vacuous (finding #2) |
| CONTROL | WM-00 / schema / LM-06/01R/02M/A0.3 SHA | **EVIDENCE** (recomputed MATCH) |
| METRICS | PE stall_frac; recs/cycle; empty/full; DDR bytes/bursts | **EVIDENCE** (re-derived); must stay labeled **synthetic only** |

---

## Dispatch / loop law

| Check | Outcome |
|-------|---------|
| Implementer PASS `ddr_feed` / `a7-ng-memory-arch` | **PASS** — DISPATCH_LOG line before this audit |
| Agent vs `run_blueprint_loop.py` FALLBACK | **PASS** — `ddr_feed` → `a7-ng-memory-arch` |
| `LOOP_STATE.next` / first OPEN | **PASS** — `ddr_feed` |
| Parent claimed BOARD_PASS / MIG bandwidth / 100 MHz WM | **PASS** — GATE/closeout/log explicitly refuse |
| Evidence_class mixed with board/silicon | **PASS** — XSIM synthetic only |
| H_RIVAL labeled OPEN (≠ MIG) | **PASS** — GATE, closeout, RTL header, TB, log NOTE, RESOURCE_BUDGET |
| Stall 0.96→0.47 labeled synthetic-only in primary archive | **PASS** — GATE/closeout/RESOURCE_BUDGET; TEST_MATRIX gap = finding #1 |
| Auditor VERIFY_ONLY (no LOOP flip) | **PASS** — this file |

---

## Headline numbers (auditor re-derived)

### XSim (`xsim_ddr_feed.log` / `sweep_table.txt` / `sweep_seed0.csv`)

| Claim | Artifact re-derive | Grade |
|-------|--------------------|-------|
| baseline stall (1,1) = 0.961544 | `pe_stall/(pe_stall+pe_busy)=6401/6657=0.961544` | **EVIDENCE** (synthetic) |
| best stall (4,8) = 0.475410 | `232/488=0.475410` | **EVIDENCE** (synthetic) |
| relative stall cut ≈50.6% | `1−0.475410/0.961544=0.505576` | **EVIDENCE** (synthetic) |
| recs/cyc 0.038456 → 0.524590 | `256/6657`, `256/488` | **EVIDENCE** (synthetic) |
| DROP=0 all 32 cells | 16×seed0 + 16×seed1 rows | **EVIDENCE** |
| ddr_rd_bytes=4096 / cell | all rows | **EVIDENCE** |
| LATENCY=24 synthetic / not MIG | log NOTE + RTL `a7ng_ddr_feed_lat_ddr.sv` | **EVIDENCE** |
| Marker `A7NG_DDR_FEED_XSIM_PASS` | log + marker file | **EVIDENCE** |

**Classification (required):** stall **0.961544 → 0.475410** is **EVIDENCE** under **synthetic LATENCY=24 XSim only**. It is **FALSE_OR_OVERCLAIM** if read as Digilent MIG / board bandwidth / silicon PE stall.

### Frozen SHA (recomputed this audit)

| Artifact | Expect | Result |
|----------|--------|--------|
| `a7ng_ddr_feed_top.sv` | `EE57D1BC…` | **MATCH** |
| `a7ng_ddr_feed_pp.sv` | `163FCA2D…` | **MATCH** |
| `a7ng_ddr_feed_lat_ddr.sv` | `05FAD7F4…` | **MATCH** |
| `a7ng_wm00_top.sv` | `1F7F3950…` | **MATCH** |
| `a7ng_mem_schema_v1.sv` | `F0FE426E…` | **MATCH** |
| `arty_a7_lm06.bit` | `67C37DD5…` | **MATCH** |
| `arty_a7_eam01r.bit` | `57D1DF1B…` | **MATCH** |
| `arty_a7_eam02m.bit` | `DB3BC58A…` | **MATCH** |
| `arty_a7_eam03e_a03.bit` | `05E478FF…` | **MATCH** |

---

## Findings

```
[MINOR] TEST_MATRIX DF-X2/DF-X3 omit synthetic-only / not-MIG qualifier
  where     : docs/native_graph/TEST_MATRIX.md:85-86
  claim      : PASS column shows bare `0.961544→0.475410` and `0.038→0.525`
  evidence   : GATE/RESOURCE_BUDGET/log correctly say synthetic LATENCY=24; matrix row does not
  why it matters: a skim reader can treat the stall cut as MIG/board bandwidth evidence
  fix        : annotate PASS cells `XSIM synthetic LATENCY=24; H_RIVAL OPEN; not MIG`
```

```
[MINOR] seed{0,1} axis is vacuous under fixed-latency synth DDR
  where     : tests/xsim/tb_a7ng_ddr_feed.sv:91; sweep_table.txt seed0 vs seed1 rows
  claim      : UNIT includes seed; 32 cells = 4×4×2 replication
  evidence   : seed only shifts `base_node=seed*17`; stall_frac identical seed0↔seed1 for every (burst,out)
  why it matters: overstates independent replication; does not stress H_RIVAL (MIG variance)
  fix        : label seed as address-offset smoke only, or add non-deterministic / MIG-like latency later
```

---

## Forbidden-route scan

| Route | Result |
|-------|--------|
| Golden edited to match DUT | **Not found** — metrics from live counters |
| Failing cell skipped / DROP tolerance widened | **Not found** — DROP=0 required; all 32 printed |
| Seeds dropped after seeing results | **Not found** — both seeds present (identical) |
| Host computes winner/answer/gradient | **N/A** — feed/stall smoke only |
| Timing FAIL rounded away / 100 MHz claimed | **Not found** — timing explicitly not claimed; WM-00 WNS OPEN cited |
| Frozen bits overwritten | **Not found** — SHA MATCH |
| BOARD_PASS / ARCH_PASS self-declared | **Not found** |
| Stall cut claimed as MIG/silicon | **Not found** in GATE/closeout/RESOURCE_BUDGET; matrix gap = finding #1 |

---

## allow_loop_done_eng

**true** — engineering XSIM unknown closed with file-backed marker, SHA, DROP=0, and honest H_RIVAL OPEN. Stall headline graded **EVIDENCE (synthetic only)**. MINOR labeling/UNIT issues do not block DONE_ENG.

**false would require:** MIG/board overclaim, H_RIVAL falsely closed, missing marker/SHA, DROP>0, or BOARD_PASS language.

---

## NOT VERIFIED

- Digilent MIG / board DDR bandwidth or PE stall on Arty A7-100T (H_RIVAL OPEN by design)
- OOC / post-route timing for ddr_feed RTL (not claimed this gate)
- Independent XSim re-run this audit session (graded from archived `xsim_ddr_feed.log` + CSV; SHA of RTL re-hashed)
- Whether parent will flip LOOP / unblock `frontier_shootout` (orchestrator only)

---

```text
allow_loop_done_eng: true
H_RIVAL: OPEN (synthetic ≠ MIG)
stall_0.961544_to_0.475410: EVIDENCE_SYNTHETIC_XSIM_ONLY
BOARD_PASS: not declared
LOOP_STATE: not modified
```
