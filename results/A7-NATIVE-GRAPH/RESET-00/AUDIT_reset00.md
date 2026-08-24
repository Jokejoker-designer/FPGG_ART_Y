# AUDIT — reset_00 (VERIFY_ONLY)

**Auditor:** `a7-evidence-auditor`  
**Mode:** READ_ONLY_AUDIT / VERIFY_ONLY (no RTL edit; no LOOP_STATE flip)  
**Date:** 2026-08-22  
**Evidence_class:** **XSIM** (not BOARD, not silicon)  
**GATE:** `reset_00` / milestone slice `A7-NATIVE-RESET-00` **logical** path  
**LOOP_STATE:** first OPEN / `next` = `reset_00` (matches this audit)  
**Implementer DISPATCH:** `a7-ng-memory-arch` / `PASS` / marker `A7NG_RESET00_XSIM_PASS` / primary `CC774F32…`  
**Parallel VERIFY:** `a7-ng-xsim-verify` PASS; `a7-vivado-gate` PASS (XVLOG / frozen MATCH)  
**Refuse rule:** DONE_ENG allow **false** if HARD scrub claimed PASS, frozen LM/01R/02M/A0.3 SHA mismatch, or Evidence_class mixed with board/silicon.

```text
MUST_READ_UNBLOCK_H5: read. Next = ungated DIFF twin (not S2, not glue).
BLUEPRINT_LOOP: read. Goal=NATIVE_V1_MINI_AI_BOARD_PASS. Next=reset_00
```

---

## Verdict

```text
AUDIT: 1 FINDING
result: PASS
allow_loop_done_eng: true
severity_metrics: RST-01/03 + HARD-reject file-backed; frozen LM-06/01R/02M/A0.3 MATCH; share 4413C74B control; no HARD scrub PASS; Evidence_class=XSIM
```

Logical QUERY + TRAIN authority cut is supported under XSIM. H_RIVAL (stale authoritative visibility / LM wipe) **falsified** for these bags. HARD scrub is **rejected** (`reset_error`), not claimed PASS.  
**Do not declare BOARD_PASS.** Full AUTHORITY A→HARD→B board milestone remains **out of scope**. Orchestrator may flip LOOP — this auditor does **not**.

---

## Declared scientific frame (graded)

| Slot | Declared (GATE_reset00) | Auditor grade |
|------|-------------------------|---------------|
| OBSERVATION | query/path epoch DONE_ENG; QUERY_RESET / training_generation fast path unproven | **EVIDENCE** (prior + this gate) |
| UNKNOWN | logical invalidation without physical BRAM wipe / LM-06 touch? | **Closed YES (smoke)** — **EVIDENCE** |
| H_CANDIDATE | QUERY_RESET / TRAIN generation bump suffice for authority cut | **SUPPORTED** — **EVIDENCE** (RST-01/03) |
| H_RIVAL | old gen still accepted after bump; OR reset wipes LM-06 | **FALSIFIED** — **EVIDENCE** (`learn_vis=0`; file SHA MATCH) |
| FALSIFIER | stale auth after bump; OR frozen SHA changed | **Did not fire** — **EVIDENCE** |
| UNIT | reset event / training generation bag | **EVIDENCE** (not cycles-as-queries) |
| CONTROL | LM-06/01R/02M/A0.3 SHAs; share untouched | **EVIDENCE** (recomputed) |
| METRICS | auth=0; learn_vis=0; old_phys>0; cyc≈5; LM MATCH | **EVIDENCE** (logs) |

---

## Dispatch / loop law

| Check | Outcome |
|-------|---------|
| Implementer PASS `reset_00` / `a7-ng-memory-arch` | **PASS** — DISPATCH_LOG |
| Agent vs `run_blueprint_loop.py` FALLBACK | **PASS** — `reset_00` → `a7-ng-memory-arch` |
| `LOOP_STATE.next` / first OPEN | **PASS** — `reset_00` |
| Parent claimed BOARD_PASS | **PASS** — none |
| Evidence_class mixed with board/silicon | **PASS** — XSIM / XVLOG only |
| HARD scrub claimed PASS | **PASS** — reject bag only |
| Auditor VERIFY_ONLY (no LOOP flip) | **PASS** — this file |

---

## Headline numbers (auditor re-derived)

From `xsim_reset00.log` (UTF-16-LE; decoded) and `xsim_reset00_verify.log` (ASCII; bit-exact bag lines):

| Bag | Claim | Log |
|-----|-------|-----|
| RST-01 QUERY | `auth=0 phys=8 work=0 ep=2 learn_vis=1 cyc=5` | **MATCH** both logs |
| RST-03 TRAIN | `gen=2 learn_vis=0 learn_phys=14 old_phys=13 new_vis=1 cyc=5` | **MATCH** both logs |
| HARD | reject / `reset_error` | **MATCH** — `HARD reject PASS (error as designed)` |
| Marker | `A7NG_RESET00_XSIM_PASS` | **MATCH** (+ verify `A7NG_RESET00_XSIM_OK`) |

Physical remnant (`phys`/`old_phys` > 0) with authority cut (`auth`/`learn_vis` = 0) supports “no scrub required” — **EVIDENCE**.

RTL check: `a7ng_reset_ctrl` HARD → `RST_ERROR` without `ptr_invalidate` / bumps; `a7ng_wm_authority` invalidate clears pointers only; `a7ng_learned_gen_view` never wipes slots on generation bump.

---

## Frozen artifact / share law

Auditor recomputed SHA256 (2026-08-22):

| Artifact | Live SHA256 | Match |
|----------|-------------|-------|
| `a7ng_reset_ctrl.sv` | `CC774F32D8632F9099FB55E92FE81FD334FA514A49802CAE16915E031A17E532` | vs `SHA256.txt` **YES** |
| All 8 archive RTL/TB/tcl rows | — | **YES** (live == `SHA256.txt`) |
| `arty_a7_lm06.bit` | `67C37DD51AED30F82B5B72EC9EF0736DDABA534ED1D724D0ADCAFD2B4282E3BA` | **YES** |
| `arty_a7_eam01r.bit` | `57D1DF1BF86338A896876F6FBE204B1705128FFEC0A96F0582CF7EF90E9EF6CF` | **YES** |
| `arty_a7_eam02m.bit` | `DB3BC58A6CC697FD0C290F97B5D6AD171AE7721A6C8A1E2DB2E87C5A84CFE696` | **YES** |
| `arty_a7_eam03e_a03.bit` | `05E478FF53D8CEBE5CFDF79E1046E986F077F6E0117C714CDA794B38142BEC09` | **YES** |
| `a7ng_multi_agent_share.sv` | `4413C74B442CA5A4CD9D0EE6E71BE71EE3067677BB42F327BB90EDAAFB3B9EB6` | **YES** (untouched) |

`frozen_sha_control.txt` / `frozen_sha_verify.txt` / `vivado_verify_sha_frozen.txt` agree MATCH.

---

## Finding

```
[MINOR] XSim CONTROL pin lm_frozen_intact is TB-tied constant
  where     : tests/xsim/tb_a7ng_reset00.sv (lm_ok=1); xsim_reset00*.log CONTROL line
  claim      : log prints CONTROL lm_frozen_intact=1 as if observed by DUT
  evidence   : TB drives lm_frozen_intact_i=1'b1 for entire run; true LM/backbone control is file SHA of frozen bits (MATCH)
  why it matters: a reader could treat the XSim CONTROL line as hardware proof of LM integrity
  fix        : keep file-SHA as sole LM control in GATE/closeout (already present); label TB pin as harness stub in future logs
```

Does **not** refuse `allow_loop_done_eng` — frozen SHA MATCH is independent and verified.

---

## Forbidden-route scan

| Route | Result |
|-------|--------|
| Golden edited to match | **Not found** |
| HARD scrub claimed PASS | **Not found** (reject only) |
| LM-06 / 01R / 02M / A0.3 overwrite | **Not found** (SHA MATCH) |
| Share law changed | **Not found** (`4413C74B…`) |
| Host gradient/winner/answer | **Not found** |
| BOARD_PASS self-declare | **Not found** |
| Evidence_class = board/silicon | **Not found** |

---

## allow_loop_done_eng

**true** — marker + owned-path SHA + XSim bags + frozen MATCH + no HARD scrub false claim + Evidence_class=XSIM.

Scope remains engineering XSIM logical reset — **not** AUTHORITY board A→HARD→B, **not** BOARD_PASS.

---

## NOT VERIFIED

- Parent-chat vs Task authorship of RTL (DISPATCH names `a7-ng-memory-arch`; no git-blame audit this turn)
- SESSION level bag (FSM present; GATE scope QUERY+TRAIN only — honest omission)
- Silicon / board A→reset→B retrieve proof (explicitly out of scope)
- Encoder H5 / ungated DIFF lane (parked; not this gate)
