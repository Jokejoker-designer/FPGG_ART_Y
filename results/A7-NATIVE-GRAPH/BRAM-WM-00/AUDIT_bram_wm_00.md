# AUDIT — bram_wm_00 (VERIFY_ONLY)

**Auditor:** `a7-evidence-auditor`  
**Mode:** READ_ONLY_AUDIT / VERIFY_ONLY (no RTL edit; no LOOP_STATE flip)  
**Date:** 2026-08-22  
**Evidence_class:** **XSIM** (+ OOC util/timing **DERIVED** from post-route reports — not BOARD, not silicon)  
**GATE:** `bram_wm_00` / `A7-BRAM-WM-00`  
**LOOP_STATE:** first OPEN / `next` = `bram_wm_00` (matches this audit)  
**Implementer DISPATCH:** `a7-ng-memory-arch` / `PASS` / marker `A7NG_BRAM_WM00_XSIM_PASS` / primary `1F7F3950…`  
**Refuse rule:** DONE_ENG allow **false** if XSim bags fail lossless/DROP/dual/LM-touch falsifiers, frozen SHA drift, Evidence_class mixed with board/silicon, **or** timing / §45 `BRAM_WORKING_MEMORY_ARCH_PASS` / BOARD_PASS claimed.

```text
MUST_READ_UNBLOCK_H5: read. Next = ungated DIFF twin (not S2, not glue).
BLUEPRINT_LOOP: read. Goal=NATIVE_V1_MINI_AI_BOARD_PASS. Next=bram_wm_00
```

---

## Verdict

```text
AUDIT: 2 FINDINGS
result: PASS
allow_loop_done_eng: true
severity_metrics: 8/8 XSim bags PASS; DROP counted; dual_err sticky; lm path refused; frozen LM-06/01R/02M/A0.3 + schema MATCH; OOC WNS=-290.499 FAIL measured (not claimed PASS); no ARCH_PASS; no BOARD_PASS; Evidence_class=XSIM(+OOC DERIVED)
```

H_CANDIDATE **lossless / correct / measurable without LM-06** is **SUPPORTED** under XSIM.  
H_CANDIDATE **bankable** is **NOT SUPPORTED** this gate (OOC timing FAIL) — see finding #1.  
H_RIVAL (silent overwrite / dual-owner accept / LM wipe) **falsified** for these bags.  
BRAM tile count **0/135** (OOC route) — LUTRAM path; does not compete with LM-06 BRAM headroom (**EVIDENCE** util report).

**Do not declare BOARD_PASS.** **Do not declare `BRAM_WORKING_MEMORY_ARCH_PASS` (§45).**  
Orchestrator may flip LOOP — this auditor does **not**.

---

## Declared scientific frame (graded)

| Slot | Declared (GATE_bram_wm_00) | Auditor grade |
|------|----------------------------|---------------|
| OBSERVATION | schema frozen; WM not proven independent of LM-06 | **EVIDENCE** (prior mem_schema + this gate) |
| UNKNOWN | 256/64/Top-8/32/16PE/synth DDR lossless+util without LM-06? | **Closed YES (XSim smoke)** — **EVIDENCE**; bankable **OPEN** |
| H_CANDIDATE | correct/lossless/bankable without LM | **PARTIAL** — lossless **SUPPORTED**; bankable **FALSE_OR_OVERCLAIM** if Supported (finding #1) |
| H_RIVAL | silent overwrite / dual owner / BRAM>headroom / LM touch | **FALSIFIED** (bags + SHA + BRAM=0) — **EVIDENCE** |
| FALSIFIER | DROP>0 on capacity; dual accepted; LM SHA touched | **Did not fire** — **EVIDENCE** |
| UNIT | query/seed WM bag | **EVIDENCE** (8 bags; not cycles-as-queries) |
| CONTROL | frozen LM/01R/02M/A0.3 + schema F0FE426E… | **EVIDENCE** (recomputed MATCH) |
| METRICS | PE grants, DROP, DDR bytes, lm_grant=0, OOC LUT/FF/BRAM/DSP/WNS | **EVIDENCE** (logs + rpts); lane util numeric incomplete — finding #2; timing **FAIL** graded |

---

## Dispatch / loop law

| Check | Outcome |
|-------|---------|
| Implementer PASS `bram_wm_00` / `a7-ng-memory-arch` | **PASS** — DISPATCH_LOG last implementer line |
| Agent vs `run_blueprint_loop.py` FALLBACK | **PASS** — `bram_wm_00` → `a7-ng-memory-arch` |
| `LOOP_STATE.next` / first OPEN | **PASS** — `bram_wm_00` |
| Parent claimed BOARD_PASS / §45 ARCH_PASS | **PASS** — none; GATE/closeout explicitly refuse |
| Timing claimed PASS @100 MHz | **PASS** — labeled **FAIL** (−290.499 ns) |
| Evidence_class mixed with board/silicon | **PASS** — XSIM + OOC DERIVED only |
| Auditor VERIFY_ONLY (no LOOP flip) | **PASS** — this file |

---

## Headline numbers (auditor re-derived)

### XSim (`xsim_wm00.log`)

| Bag | Claim | Log |
|-----|-------|-----|
| FILL256 | count=256 DROP=0 ddr_rd_bytes=4096 | **MATCH** `count=256 drop=0 ddr_bytes=4096` |
| OVERFLOW | DROP=1 not silent | **MATCH** `drop=1 (not silent)` |
| FRONTIER | count=64 DROP on 65th | **MATCH** `count=64 drop=1` |
| TOP8 | nodes/scores 31..24 | **MATCH** `nodes=31..24` |
| LEARN | 32 + coalesce=1 + wr bytes=512 | **MATCH** `count=32 coal=1 wr=16 bytes=512` |
| 16PE | grants=16 lm_grant=0 | **MATCH** `grants=16`; final `lm_grant=0` |
| DUAL_OWNER | dual_err sticky | **MATCH** `dual_cnt=2` |
| SCHEMA | NodeRecordV1 version=1 | **MATCH** |
| Marker | `A7NG_BRAM_WM00_XSIM_PASS` | **MATCH** |

Aggregate METRICS: `cand_drop=1 fr_drop=1 learn_drop=0 dual=2 ddr_rd_bytes=4416 ddr_wr_bytes=512 pe_grants=16` — **EVIDENCE**.

### OOC util / timing (re-read reports)

| Metric | Claim | Artifact |
|--------|-------|----------|
| LUT | 10238 / 16.15% | **MATCH** `util_route.rpt` Slice LUTs |
| FF | 7359 / 5.80% | **MATCH** |
| BRAM | 0 / 135 | **MATCH** Block RAM Tile |
| DSP | 0 | **MATCH** |
| WNS @100 MHz | −290.499 ns FAIL | **MATCH** Design Timing Summary |
| TNS | −108584.445 FAIL | **MATCH** Design Timing Summary |
| Worst path | comb Top-8 insert (`u_ev/slot_reg…`) | **MATCH** Slack (VIOLATED) −290.499 ns; Data Path Delay 300.446 ns |

Constraint period 10.000 ns (100 MHz). Report: **Timing constraints are not met.**

### Frozen SHA (recomputed)

| Artifact | Expected | Recomputed |
|----------|----------|------------|
| `arty_a7_lm06.bit` | `67C37DD5…` | **MATCH** |
| `arty_a7_eam01r.bit` | `57D1DF1B…` | **MATCH** |
| `arty_a7_eam02m.bit` | `DB3BC58A…` | **MATCH** |
| `arty_a7_eam03e_a03.bit` | `05E478FF…` | **MATCH** |
| `a7ng_mem_schema_v1.sv` | `F0FE426E…` | **MATCH** |
| `a7ng_wm00_top.sv` (primary) | `1F7F3950…` | **MATCH** |

---

## Findings

```
[MAJOR] H_CANDIDATE "bankable" claimed Supported while OOC timing FAIL
  where     : results/A7-NATIVE-GRAPH/BRAM-WM-00/closeout.md:12 ; GATE_bram_wm_00.md:15,23
  claim      : "H_CANDIDATE (WM lossless/bankable without LM) | Supported (XSim bags)"
  evidence   : timing_route.rpt Design Timing Summary WNS=-290.499 TNS=-108584.445; "Timing constraints are not met."; §45 item 8 requires post-route timing PASS for ARCH_PASS; GATE correctly refuses ARCH_PASS but still grades bankable as part of Supported H_CANDIDATE
  why it matters: a reader can conclude WM-00 is productization-bankable at 100 MHz when the measured critical path is ~300 ns (~3.3 MHz class), conflating XSim functional lossless with timing bankability
  fix        : split H_CANDIDATE in GATE/closeout — lossless/correct = SUPPORTED (XSIM); bankable = OPEN/FAIL (OOC WNS measured). Keep §45 / BOARD_PASS refused.
```

```
[MINOR] lm_grant_o hardwired 0; 16PE util max not printed
  where     : rtl/native_graph/memory/a7ng_wm00_owner.sv:29 ; tests/xsim/tb_a7ng_wm00.sv:433-434 ; xsim_wm00.log:25
  claim      : METRICS lm_grant=0 and "lane util (16 PE grants)" as full util evidence
  evidence   : `assign lm_grant_o = 1'b0` always; ownership still refuses `lm_wr_req_i` (dual_err++) — real. 16PE PASS line ends `active_max_tracked` with no numeric busy_acc dump despite pe_iface accumulating lane_busy_acc_o
  why it matters: lm_grant pin is tautological; lane util ratio is not file-backed beyond grant count / busy_nz smoke
  fix        : optional follow-up — drive lm_grant from refused-owner path; print max(busy_acc) / pe_cycles; do not re-open DONE_ENG for this alone
```

---

## Forbidden-route scan

| Route | Result |
|-------|--------|
| Golden edited to match DUT | **Not seen** — TOP8 expects 31..24 from insert order |
| Test deleted / tolerance widened | **Not seen** — 8 bags present; DROP must increment |
| Host computes winner/answer | **Not seen** — synth DDR + TB stimuli only |
| Frozen LM/01R/02M/A0.3 overwrite | **MATCH** controls |
| BOARD_PASS / ARCH_PASS self-declare | **Absent** — explicitly refused |
| Timing PASS overclaim | **Absent** — FAIL measured |
| Glue encoder / LM-06 into WM | **Absent** — no LM-06 instance; SHA untouched |
| BRAM metric collapse (tiles→0) as fake win | **OK for this gate** — spec §33 allows LUTRAM; H_RIVAL was BRAM>headroom / dual / wipe, not “must use BRAM tiles” |

---

## allow_loop_done_eng

```text
allow_loop_done_eng: true
```

**Rationale:** XSim lossless bags **hold** (file-backed). Timing is graded **FAIL / measured**, not PASS. No BOARD_PASS / §45 ARCH_PASS. Finding #1 is claim-wording (bankable), not a silent timing green. Finding #2 does not falsify DROP/dual/LM-SHA controls.

**Not** `PASS_NARROW` — implementer did **not** overclaim timing PASS.

---

## NOT VERIFIED

- Full-chip / integrate_fit post-route WNS with LM-06 + graph (out of scope; OOC WM-only).  
- Parallel `a7-ng-xsim-verify` / `a7-vivado-gate` trio lines for this gate (implementer logs present; auditor re-read artifacts only).  
- Burst-feedable / WM-01 DDR ping-pong (next gate).  
- Whether parent chat wrote any of `rtl/native_graph/memory/a7ng_wm00_*.sv` outside Task (DISPATCH agent matches FALLBACK; no contradictory parent patch evidence in STATUS).  
- Encoder H5 ungated DIFF twin (parked; not this lane).
