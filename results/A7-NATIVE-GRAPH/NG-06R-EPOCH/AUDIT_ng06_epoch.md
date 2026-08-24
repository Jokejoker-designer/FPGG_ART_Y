# AUDIT — ng06_epoch (VERIFY_ONLY)

**Auditor:** `a7-evidence-auditor`  
**Mode:** READ_ONLY_AUDIT / VERIFY_ONLY (no RTL edit; no LOOP_STATE flip)  
**Date:** 2026-08-22  
**Evidence_class:** **XSIM** (not BOARD, not silicon)  
**GATE:** `ng06_epoch`  
**LOOP_STATE:** first OPEN = `ng06_epoch` (matches this audit)  
**Implementer DISPATCH:** `a7-ng-scientific` / `PASS` / marker `NG06R_EPOCH_ENGINEERING_PASS` / sha share `4413C74B…`  
**Skills:** scientific-critical-thinking + scientific-method-native-ai  

```text
MUST_READ_UNBLOCK_H5: read. Next = ungated DIFF twin (not S2, not glue).
BLUEPRINT_LOOP: read. Goal=NATIVE_V1_MINI_AI_BOARD_PASS. Next=ng06_epoch
```

---

## Verdict

```text
AUDIT: 2 FINDINGS
result: PASS
allow_loop_done_eng: true
severity_metrics: DROP_STALE>0, alive=256, prior_ok=1 (logged), Evidence_class=XSIM
```

Primary unknown (H-epoch DROP_STALE under mixed-epoch bags) is supported by file-backed XSim.  
H_RIVAL “permanent ctx kill via DROP_STALE” is **falsified for share `ctx_alive`** (alive stays 256 after ≫0 DROP_STALE).  
Two MINOR issues weaken how prune/prior “no permanent semantic kill” was *argued*, not the share DROP_STALE result.  
**Do not declare BOARD_PASS.** Orchestrator may flip LOOP — this auditor does **not**.

---

## Declared scientific frame (graded)

| Slot | Declared (GATE/closeout) | Auditor grade |
|------|--------------------------|---------------|
| OBSERVATION | wide-dispatch DONE_ENG; delayed events can apply stale work | **EVIDENCE** (prior gate + this RTL) |
| UNKNOWN | query/path epoch + DROP_STALE stop stale expand without permanent semantic kill? | **Open→tested** — **EVIDENCE** |
| H_CANDIDATE | H-epoch — mismatch drop sufficient for query-scoped prune | **SUPPORTED** (XSIM) — **EVIDENCE** |
| H_RIVAL | silent kill of live paths / wipe unrelated priors (HS-07) | **Partially falsified** — see findings |
| FALSIFIER | DROP_STALE==0 OR priors wiped OR permanent ctx_alive kill | **Did not fire** on share bags — **EVIDENCE** |
| UNIT | mixed-epoch query/seed bags (not 100k cycles-as-queries) | **EVIDENCE** (bumps every 2048/4096; multi-seed tops) |
| CONTROL | matched-epoch share regress; no N_WAY law change | **EVIDENCE** (`drop_stale=0` + `A7NG06_SHARE_XSIM_PASS`) |
| METRICS | DROP_STALE, alive, prior_ok, node_alive | Mixed strength — see findings |

---

## Dispatch / loop law

| Check | Outcome |
|-------|---------|
| `DISPATCH_LOG` implementer PASS for `ng06_epoch` | **PASS** — line agent=`a7-ng-scientific` result=`PASS` artifact=`GATE_ng06_epoch.md` |
| Agent vs pipeline/`FALLBACK_AGENT` | **PASS** — `ng06_epoch` → `a7-ng-scientific` |
| `LOOP_STATE.next` / first OPEN | **PASS** — `ng06_epoch` |
| Parent claimed BOARD_PASS | **PASS** — none |
| Evidence_class mixed with board/silicon | **PASS** — XSIM only |

Refuse rule “no implementer PASS” → **does not apply**.

---

## Primary metrics (re-derived from raw logs)

Source: `run_epoch_batch.log` + per-top `xsim_tb_a7ng_epoch*.log` + `xsim_share_regress.log`.

| Bag | DROP_STALE | alive / node | prior_ok | Marker |
|-----|------------|--------------|----------|--------|
| share seed0 `0xE06A701` | **396171** | alive=**256** | **1** | `A7NG06R_EPOCH_XSIM_PASS` |
| share seed1 `0xE06A711` | **396545** | alive=**256** | **1** | bag PASS |
| share seed2 `0xE06A721` | **395506** | alive=**256** | **1** | bag PASS |
| prune seed0 `0xE06B702` | **50026** | node_alive=**1** | — | bombs=25166 |
| prune seed1 `0xE06B712` | **49855** | node_alive=**1** | — | bombs=25178 |
| matched share regress | **0** | — | — | `A7NG06_SHARE_XSIM_PASS` multi=1 |
| prune unit | — | — | — | `A7NG04_PRUNE_PASS` |
| batch close | — | — | — | `NG06R_EPOCH_ENGINEERING_PASS` |

**FACT:** All mixed-epoch bags have DROP_STALE ≫ 0. Share alive=256 and prior_ok=1 match GATE/closeout/marker file.  
**FACT:** No FAIL lines in batch log body (excluding Vivado “Pass Through” noise).

### SHA256 (live re-hash)

| File | Live SHA256 | SHA256.txt |
|------|-------------|------------|
| `a7ng_multi_agent_share.sv` | `4413C74B442CA5A4CD9D0EE6E71BE71EE3067677BB42F327BB90EDAAFB3B9EB6` | match |
| `a7ng_ctx_prune.sv` | `187452537BB094CF94CF598C0F854A1433BAEFB28894252960EF0ED70D36C86D` | match |

Prior wide SHA `4C604278…` superseded by epoch-port share — expected interface change; matched-epoch regress still PASS.

---

## Findings

```
[MINOR] node_alive=1 is tautological on prune DUT
  where     : rtl/native_graph/prune/a7ng_ctx_prune.sv:43
              GATE_ng06_epoch.md:26; closeout.md:23
  claim      : H_RIVAL permanent kill FALSIFIED citing node_alive=1
  evidence   : `assign node_alive_o = 1'b1;` — signal cannot go low
  why it matters: reader may think prune bags empirically proved HS-06 node ban absence;
                  they only re-read a constant
  fix        : cite structural “no ban table / DROP_STALE ignores fire” + bombs>0 on matched
               fires; do not list node_alive=1 as independent empirical falsifier
```

```
[MINOR] prior_ok is TB-local surrogate, not on-chip learned state
  where     : tests/xsim/tb_a7ng_epoch.sv:49-53, 111-114, 190-191
              GATE/closeout prior_ok=1 claims
  claim      : unrelated priors intact (HS-07)
  evidence   : `prior_tag[]` / `prior_snapshot[]` live only in TB; never DUT ports
  why it matters: proves TB did not scrub its own array on epoch bump, not that share
                  preserved hardware priors
  fix        : label prior_ok as CONTROL/TB hygiene; rely on alive=256 + RTL
               “DROP_STALE must NOT clear ctx_alive” for HS-07 share claim
```

No CRITICAL/MAJOR. No golden edits, skipped bags, host answer path, or frozen-bit overwrite detected in this archive.

---

## Claim scope (anti-overreach)

| Claim | Grade |
|-------|-------|
| DROP_STALE>0 under mixed-epoch XSim bags | **EVIDENCE** |
| alive=256 after massive DROP_STALE (share) ⇒ DROP_STALE path does not clear `ctx_alive` | **EVIDENCE** |
| Matched-epoch share still grants (`drop_stale=0`) | **EVIDENCE** |
| “Permanent semantic kill” impossible forever / BOARD / silicon | **FALSE_OR_OVERCLAIM** if asserted — **not** asserted in GATE/closeout |
| H_RIVAL fully falsified via node_alive + prior_ok | **ENGINEERING_INFERENCE** with MINOR overreach (above) |

---

## allow_loop_done_eng

**true** — implementer PASS present; DROP_STALE>0; alive=256; Evidence_class=XSIM; marker + SHA bind; MINOR findings do not break the gate falsifiers for share H-epoch.

Orchestrator may mark `ng06_epoch` DONE_ENG. This auditor does **not** edit `LOOP_STATE.json`.

---

## NOT VERIFIED

- Cursor Task UUID / that RTL was not written in parent chat (DISPATCH agent string only)
- Full Vivado synth/impl / WNS for epoch-port share (not requested this VERIFY)
- Independent `a7-ng-xsim-verify` Task log (batch log used as XSim provenance)
- On-chip / DDR learned-prior persistence under epoch bump (out of scope; `prior_ok` is TB-only)
- HS-02 teacher-off / BOARD ladder
