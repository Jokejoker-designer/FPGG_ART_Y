# AUDIT — `descriptor_contract_00` (VERIFY_ONLY)

**Auditor:** `a7-evidence-auditor`  
**Mode:** READ_ONLY_AUDIT / VERIFY_ONLY (no RTL edit; no LOOP_STATE flip)  
**Date:** 2026-08-22  
**Evidence_class:** **LAW_AUDIT** (not XSim, not silicon, not SOA RTL)  
**GATE:** `descriptor_contract_00`  
**LOOP_STATE:** `next` = `ddr_cue_soa_00` (gate under audit = `DONE_ENG`; verify completes here)  
**Implementer DISPATCH:** `a7-hlb-auditor` / `PASS` / marker `A7NG_DESCRIPTOR_CONTRACT_104B_FROZEN` / mode `LAW_AUDIT`

```text
MUST_READ_UNBLOCK_H5: read. Next = ungated DIFF twin (not S2, not glue).
BLUEPRINT_LOOP: read. Goal=NATIVE_V1_MINI_AI_BOARD_PASS. Next=ddr_cue_soa_00
```

---

## Verdict

```text
AUDIT: CLEAN
result: PASS_NARROW
allow_loop_done_eng: true
result_class: PASS_NARROW
evidence_class: LAW_AUDIT
marker: A7NG_DESCRIPTOR_CONTRACT_104B_FROZEN
```

H_CANDIDATE (stage-1 consumes `node_id` + `node_cue` + `learned_prior` = **104 b**) — **SUPPORTED** — **EVIDENCE** (RTL trace + `CONTRACT_FREEZE.md` score law + golden oracle).  
H_RIVAL (96 b suffices; prior broadcast or `confidence` alias) — **FALSIFIED** — **EVIDENCE** (scorer adds per-candidate `learned_prior`; golden has 29 distinct priors / 32 vectors; `confidence` u16 has no TermGen path).  
**No SOA RTL** in this gate — **EVIDENCE** (directory is law docs only; freeze explicitly scopes SOA to `ddr_cue_soa_00`).  
**Do not declare BOARD_PASS.** **Do not claim DDR byte reduction or SOA layout proven.**

---

## Dispatch law

| Check | Outcome |
|-------|---------|
| Last `DISPATCH_LOG.jsonl` line `gate=descriptor_contract_00` | **PASS** |
| Last line `agent=a7-hlb-auditor` | **PASS** — matches `run_blueprint_loop.py` mapping |
| `LOOP_STATE` `descriptor_contract_00` status | **DONE_ENG**; `verify.auditor` was **PENDING** (this file) |
| `LOOP_STATE.next` | `ddr_cue_soa_00` — prerequisite lift is consistent with closed unknown |
| Parent wrote RTL (void) | **PASS** — no new `.sv` under `DESCRIPTOR-CONTRACT-00/` |
| AI declares `BOARD_PASS` | **PASS** — none in gate artifacts |

---

## Required checks

### 1. 104-bit freeze lawful — **PASS**

| Claim | Re-derived | Class |
|-------|------------|-------|
| `STAGE1_DESCRIPTOR_BITS = 104` | `32 + 64 + 8 = 104` | **EVIDENCE** |
| Fields frozen | `node_id`, `node_cue`, `learned_prior` | **EVIDENCE** |
| `node_id` consumed | `cand_id_i` → Top-K id/tie-break (`a7ng_termgen_lane.sv:11,43`) | **EVIDENCE** |
| `node_cue` consumed | XOR/ROTL on `cues_i.node_cue` (`a7ng_termgen_lane.sv:46-51`) | **EVIDENCE** |
| `learned_prior` consumed | `prior_d1 <= cues_i.learned_prior` → scorer `+learned_prior` (`termgen_lane:44,88`; `scorer_lane:55`) | **EVIDENCE** |
| Score law requires prior | `CONTRACT_FREEZE.md` includes `LearnedPrior` in compose | **EVIDENCE** |
| FPGA-owned prior region | `NG_DDR_PRIOR_BASE` @ `a7ng_pkg.sv:18` | **EVIDENCE** |
| Query cue bags not per-cand DDR | Five 64-bit broadcast inputs in `termgen_cues_t` | **EVIDENCE** |

NodeRecordV1 tail fields (`node_type`, `topic_id`, `confidence`, `degree_sat`, `version`) are explicitly rejected for stage-1 semantic consumption — **EVIDENCE** (`MEM_SCHEMA_V1.md` offsets; no RTL consumer).

### 2. 96-bit rival falsified — **PASS**

| Rival claim | Falsifier | Class |
|-------------|-----------|-------|
| Omit / broadcast `learned_prior` | Scorer adds `terms_d1.learned_prior` to rankable score; broadcast `learned_prior_i` in `a7ng_ddr_wavefront_top.sv:255` documented **invalid** when priors differ | **EVIDENCE** |
| `confidence` u16 aliases prior | Schema: `confidence` @ byte 12, u16; lawful prior is i8 `term_t`; no RTL map | **EVIDENCE** |
| Golden tolerates constant prior | `golden_termgen.json`: **29** distinct `learned_prior` values across **32** vectors (re-counted) | **EVIDENCE** |

Per-record prior path exists on compact wavefront: `a7ng_wavefront_mig_top.sv:196` reads `wave_rec[k][103:96]`.

### 3. No SOA RTL claimed — **PASS**

| Check | Outcome |
|-------|---------|
| Files under `DESCRIPTOR-CONTRACT-00/` | `.md` + `SHA256.txt` only — no RTL/TB added |
| `DESCRIPTOR_CONTRACT_FREEZE.md` scope | States **not SOA RTL**; SOA byte floor deferred to `ddr_cue_soa_00` |
| `RESULTS.md` LIMITS | Explicit: no SOA RTL, no DDR measurement, no silicon |
| DISPATCH `soa_rtl: false` | **MATCH** |

### 4. Evidence class separation — **PASS**

No artifact labels simulation as board/silicon. LAW_AUDIT is consistently scoped to RTL trace + oracle + contract text.

### 5. Host learning boundary — **PASS** (inherits HLB)

HLB audit (`AUDIT_descriptor_contract_00_hlb.md`): **CLEAN**, 0 violations. Host files are golden generator / MEMORY-PRELOAD / TRAIN harness without winner-on-payload surface — **EVIDENCE** (HLB file; spot-check `train_v2_harness.py` forbids `winner`).

### 6. SHA256 anchor (re-derived)

| Artifact | Claimed | Live rehash | Match |
|----------|---------|-------------|-------|
| `a7ng_termgen_lane.sv` | `DD637EDA…5218` | `DD637EDAC060D407F44E81C6DD83FE3995150B4CDD275EEF2820757F22DF5218` | **MATCH** |

Other anchors in `SHA256.txt` not re-hashed this pass; gate directory hashes are internally consistent.

---

## Findings

None at CRITICAL or MAJOR severity.

Inherited MINOR (from HLB; not gate-blocking):

### [MINOR] NodeRecordV1 delivery vs 104-bit semantic subset

- **where:** `MEM_SCHEMA_V1.md` (16 B beat) vs `DESCRIPTOR_CONTRACT_FREEZE.md`  
- **claim:** Stage-1 semantic width is 104 b inside a 16 B delivery container  
- **evidence:** Documented; not conflated in gate verdict  
- **why it matters:** `ddr_cue_soa_00` could confuse beat width with consumed fields  
- **fix:** Preregister freeze cite in `ddr_cue_soa_00` (already noted in HLB)

### [MINOR] Two cue-widen delivery rules in flight

- **where:** `cue-replicate-v0` (`a7ng_ddr_wavefront_top.sv`) vs `cue-complement-v0` (`a7ng_wavefront_mig_top.sv`)  
- **claim:** TermGen law unchanged; delivery widen differs  
- **evidence:** Both files present; freeze lists both  
- **why it matters:** Integration bitstream must pick one `law_id` before SOA claims  
- **fix:** Declare single widen in `ddr_cue_soa_00`

### [MINOR] Truncated golden SHA in freeze doc

- **where:** `DESCRIPTOR_CONTRACT_FREEZE.md` SHA table (`7BBE92AE…CF8BE0`)  
- **claim:** Full golden anchor  
- **evidence:** Ellipsis only; `SHA256.txt` in gate dir omits golden file  
- **why it matters:** Audit replay cannot verify golden hash from freeze alone  
- **fix:** Add full `golden_termgen.json` SHA to `SHA256.txt` when convenient

---

## Gate closeout

| Item | Value |
|------|-------|
| ONE UNKNOWN | Which per-candidate fields does lawful stage-1 scoring consume? → **CLOSED** |
| Frozen width | **104 bits** |
| Frozen fields | `node_id(32) + node_cue(64) + learned_prior(8)` |
| H_RIVAL | **FALSIFIED** (`96b_broadcast_prior`, `confidence_alias`) |
| SOA RTL | **none** (planning unblocked for next gate only) |
| BOARD_PASS | **none** (human only) |
| NEXT | Parent may dispatch `ddr_cue_soa_00` |

---

## NOT VERIFIED

- Full re-hash of every SHA row in `DESCRIPTOR_CONTRACT_FREEZE.md` (only `a7ng_termgen_lane.sv` re-derived).  
- XSim / post-route / board (out of scope for LAW_AUDIT gate).  
- DDR bytes/query reduction (explicitly deferred to `ddr_cue_soa_00`).  
- Unified cue-widen `law_id` selection (deferred to SOA gate).  
- Production wavefront path correctness when per-node priors differ on `a7ng_ddr_wavefront_top` broadcast wiring (documented as artifact, not production claim).
