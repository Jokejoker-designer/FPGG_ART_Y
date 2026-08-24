# AUDIT — mig_h_rival (VERIFY_ONLY, post-repair)

**Auditor:** `a7-evidence-auditor`  
**Mode:** VERIFY_ONLY (no RTL edit; **no LOOP_STATE flip**)  
**Date:** 2026-08-22  
**Evidence_class:** **MIG_XSIM** (Digilent AXI MIG + ddr3_model stall sweep) — **not BOARD**, **not silicon PE stall**, **not HS-02**  
**GATE:** `mig_h_rival`  
**LOOP_STATE:** `next` / first OPEN = `mig_h_rival`  
**Implementer DISPATCH:** `a7-ng-memory-arch` / `PASS_NARROW` / repair (`GATE_mig_h_rival.md`, ts 2026-08-22T01:53:54Z)  
**Parallel VERIFY:** `a7-ng-xsim-verify` PASS (`VERIFY_mig_h_rival.md`); `a7-vivado-gate` PASS_NARROW (`GATE_mig_h_rival_vivado_verify.md`)  
**Refuse rule:** FAIL if H_RIVAL closed without MIG stall numbers; synthetic 0.475410 sold as MIG/board; BOARD_PASS; frozen SHA drift; mig.prj hand-edit / native `app_*`; invented `MIG_SWEEP_ROW`.

```text
MUST_READ_UNBLOCK_H5: read. Next = ungated DIFF twin (not S2, not glue).
BLUEPRINT_LOOP: read. Goal=NATIVE_V1_MINI_AI_BOARD_PASS. Next=mig_h_rival
```

---

## Verdict

```text
AUDIT: 2 FINDINGS
result: PASS_NARROW
allow_loop_done_eng: true
severity_max: MINOR
severity_metrics: xelab -mt off -O0 PASS; MIG_SWEEP_ROW (1,1)=0.958710 (4,8)=0.549296 DROP=0 EVIDENCE; H_RIVAL FALSIFIED; synthetic CONTROL retained (not equality); frozen+mig.prj MATCH; no BOARD_PASS; Evidence_class=MIG_XSIM
```

**allow_loop_done_eng = true:** Digilent AXI MIG-backed stall rows are archived; prior xelab ACCESS_VIOLATION repaired with `-O0`; H_RIVAL ("synthetic LAT=24 only") is **FALSIFIED**. Narrow engineering unknown closed. **Not** BOARD_PASS / §14 / HS-02.

H_CANDIDATE (MIG_SWEEP_ROW on Digilent AXI path) **SUPPORTED** — **EVIDENCE**.  
H_RIVAL (synthetic-only stall evidence) **FALSIFIED** — **EVIDENCE**.  
Falsifiers (mig.prj hand-edit, frozen overwrite, BOARD_PASS, invented stall, promote synthetic as MIG) **did not fire** — **EVIDENCE**.

**Do not declare BOARD_PASS.** **Do not flip LOOP_STATE** (orchestrator only).

---

## Findings

```
[MINOR] TOTAL=64 vs synthetic TOTAL=256 (unequal N)
  where     : tests/xsim/tb_a7ng_ddr_feed_mig.sv TOTAL=64; MIG_SWEEP_ROW.md; LIMIT.md
  claim      : MIG vs synthetic stall comparison table
  evidence   : MIG cells run TOTAL=64; DDR-FEED CONTROL used TOTAL=256
  why it matters: absolute stall equality across classes is not matched-N; direction still informative
  fix        : keep LIMIT disclosure; do not treat deltas as N-matched board prediction
```

```
[MINOR] WAITING_BOARD recipe drift vs repair TCL
  where     : MIG-RIVAL/WAITING_BOARD.md vs tests/xsim/run_a7ng_ddr_feed_mig.tcl
  claim      : re-run commands / marker names for optional silicon path
  evidence   : repair TCL uses xelab `-mt off -O0`; marker `A7NG_MIG_RIVAL_XSIM_PASS` in UTF-16 log
  why it matters: operator copy-paste could diverge from archived PASS path
  fix        : align WAITING_BOARD commands to TCL + exact marker (doc only)
```

---

## Dispatch / loop law

| Check | Outcome |
|-------|---------|
| `LOOP_STATE.next` / first OPEN = `mig_h_rival` | **PASS** |
| Implementer agent = `a7-ng-memory-arch` (FALLBACK / pipeline) | **PASS** — DISPATCH repair line |
| Parallel `a7-ng-xsim-verify` + `a7-vivado-gate` | **PASS** — post-repair VERIFY present |
| Auditor agent this VERIFY = `a7-evidence-auditor` | **PASS** |
| Evidence_class mixed as board/silicon | **PASS** — GATE/LIMIT/WAITING refuse |
| H_RIVAL labeled FALSIFIED with MIG rows | **PASS** |
| BOARD_PASS / HS-02 language | **PASS** — explicit non-claims |
| Auditor VERIFY_ONLY (no LOOP flip) | **PASS** — this file |

---

## Declared scientific frame (graded)

| Slot | Declared (GATE repair) | Auditor grade |
|------|------------------------|---------------|
| OBSERVATION | Prior xelab crash; synthetic stall only | **EVIDENCE** (prior AUDIT + archives) |
| UNKNOWN | ≥1 preregistered MIG-backed stall row? | **CLOSED** — **EVIDENCE** (`MIG_SWEEP_ROW`) |
| H_CANDIDATE | MIG_SWEEP_ROW on Digilent AXI path | **SUPPORTED** — **EVIDENCE** |
| H_RIVAL | still only synthetic LAT=24 | **FALSIFIED** — **EVIDENCE** |
| FALSIFIER | invent GB/s; hand-edit mig.prj; BOARD_PASS | **Did not fire** — **EVIDENCE** |
| UNIT | sweep cell (burst × outstanding); TOTAL=64 | **EVIDENCE** (preregistered; N disclosed) |
| CONTROL | DDR-FEED synthetic; mig.prj AXI SHA; frozen MATCH | **EVIDENCE** |
| METRICS | PE stall_frac; recs/cycle; DROP; ddr_rd_bytes | **EVIDENCE** MIG_XSIM |

---

## Headline numbers (auditor re-derived)

UTF-16-LE log `xsim_mig_rival.log` parsed; stall_frac re-derived as `pe_stall/(pe_stall+pe_busy)`:

| Claim | Artifact re-derive | Grade |
|-------|--------------------|-------|
| xelab `-mt off -O0` | `xelab_repair_O0.log`: cmd line + `Built simulation snapshot` | **EVIDENCE** |
| MIG (1,1) stall_frac | log `0.958710`; 1486/(1486+64)=0.958709677 → **0.958710** | **EVIDENCE** |
| MIG (4,8) stall_frac | log `0.549296`; 78/(78+64)=0.549295775 → **0.549296** | **EVIDENCE** |
| DROP | 0 both cells | **EVIDENCE** |
| Marker | `A7NG_MIG_RIVAL_XSIM_PASS` PRESENT | **EVIDENCE** |
| `a7ng_ddr_feed_mig_top.sv` SHA | `EE52D9C4C1A5E5106A7C996379A3CAE06C031D5FC62D9FA577E97308084ACBF1` MATCH | **EVIDENCE** |
| `mig.prj` SHA | `870FA6EEC23436FA8AD2A8772A80865016807CA37542C0C994E9E1E88152190D` MATCH | **EVIDENCE** |
| `mig.prj` PortInterface | AXI; `app_*` count=0 | **EVIDENCE** |
| Synthetic CONTROL 0.961544→0.475410 | DDR-FEED AUDIT / CONTROL file — **not MIG** | **EVIDENCE** CONTROL only |
| Frozen LM-06 / 01R / 02M / A0.3 | live rehash MATCH control | **EVIDENCE** |
| BOARD / HS-02 / BOARD_PASS | not claimed | **EVIDENCE** |

**Classification (required):** Digilent AXI MIG + ddr3_model stall rows are **EVIDENCE** class **MIG_XSIM**. Synthetic **0.961544→0.475410** remains **FALSE_OR_OVERCLAIM** if read as Digilent MIG / board. Board PE stall remains **ABSENT**.

---

## Forbidden-route search

| Route | Result |
|-------|--------|
| Golden / expected stall edited to match | **CLEAR** — log counters re-derive display |
| Failing test deleted / tolerance widened | **CLEAR** — prior ACCESS_VIOLATION archived; fix is `-O0` |
| Seeds selected after results | **CLEAR** — preregistered (1,1)/(4,8) only |
| Host computes MIG stall as board | **CLEAR** |
| Hardcoded MIG stall / promote synthetic as MIG | **CLEAR** — LIMIT/GATE refuse equality |
| Frozen bit overwrite | **CLEAR** — MATCH |
| Hand-edited `mig.prj` / native `app_*` | **CLEAR** — AXI SHA MATCH; `app_*=0` |
| Self-declared BOARD_PASS | **CLEAR** |

---

## allow_loop_done_eng decision

| Question | Answer |
|----------|--------|
| xelab repair + xsim marker archived? | **YES** |
| MIG_SWEEP_ROW Digilent AXI numbers present? | **YES** — 0.958710 / 0.549296, DROP=0 |
| H_RIVAL ("synthetic only") closed? | **YES — FALSIFIED** |
| BOARD / §14 / HS-02 closed? | **NO** — correctly out of scope |
| `allow_loop_done_eng` | **true** (narrow DONE_ENG only) |

Orchestrator may mark `mig_h_rival` **DONE_ENG** with `PASS_NARROW` / Evidence_class=MIG_XSIM. Do **not** declare BOARD_PASS.

---

## NOT VERIFIED

- Board ddr_feed stall UART / silicon PE stall (WAITING_BOARD; optional).  
- Whether `-O0` is the only durable xelab workaround across Vivado patch levels (tool root-cause).  
- Matched-N (TOTAL=256) MIG sweep (not claimed).  
- Encoder H5 / ungated DIFF (parked; out of scope).

---

## Auditor actions

- Wrote this file under `results/A7-NATIVE-GRAPH/MIG-RIVAL/` (post-repair supersedes path+xvlog-only audit).  
- Appends `STATUS/DISPATCH_LOG.jsonl` only.  
- **No** `LOOP_STATE.json` edit.  
- **No** BOARD_PASS.
