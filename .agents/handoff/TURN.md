# Handoff turn

`owner` must match `BRIDGE.json` → `lock.owner`. Only the owner edits product files.

## Status

- state: `assigned`
- owner: `cursor`
- from: `codex`
- to: `cursor`
- active_gate: `ddr_cue_soa_bench_01` (implementer Task in flight; lock retained)
- parallel_note: LM06 BRAM research pack synced below (informational; does **not** steal lock)

## Note (cursor → codex) — LM06 BRAM research sync

**Type:** informational sync (not a blocker; not a DECIDE request)  
**Date:** 2026-08-24T10:16:20+07:00  
**Lock:** remains `cursor` for `ddr_cue_soa_bench_01` — Codex may **read** this note anytime; do not take lock for BRAM unless human opens a BRAM gate.

### What was missing before

BRAM investigation lived only as untracked files under Cursor tree; **no** mailbox entry, **no** git commit. Now synced.

### Pack paths (same repo Codex already uses)

| Gate | Path | Verdict |
|------|------|---------|
| `LM06-BRAM-PHYS-AUDIT-00` | `results/A7-NATIVE-GRAPH/LM06-BRAM-PHYS-AUDIT-00/` | `AUDIT_COMPLETE_NO_PARITY_TILE_GAIN` |
| `LM06-BANK-CONCURRENCY-00` | `results/A7-NATIVE-GRAPH/LM06-BANK-CONCURRENCY-00/` | **AMENDED** `PASS_NARROW` |

Authority for concurrency interpretation: **`AMENDMENT.md`** + amended `CLOSEOUT.md` / `RESULTS.md` (not pre-amend headlines).

### Independent human audit → adopted

```text
INDEPENDENT VERDICT: PASS_NARROW / CLOSEOUT_AMEND_REQUIRED (applied)
Closeout class: TRACE_COMPLETE_PORT_TOPOLOGY_CLOSED_LIFETIME_OPEN
(prior TRACE_COMPLETE_LIFETIME_ONLY_HEADROOM WITHDRAWN)
```

**PROVEN (narrow):** CORE≈98 + BOARD tensor≈34 split; act needs TDP in some states; CORE act/weight near native aspect; no free bank-fold lever.

**CORRECTION:** `CORE_snap` capacity lower bound = 2; `topology_headroom=0` (not 1). D1 = CROSS-RESOURCE BRAM→LUTRAM (−2), not wasted topology tile.

**NOT PROVEN:** lifetimes; silicon-TILE weight dynamics; pingpong exclusivity; necessity of 34 BRAM BOARD tensor on LM06 BOARD_PASS cone.

**Evidence class for TSV pack:** `CURATED_DERIVATION` (not auto-derived from DCP row pipeline).

### Next research (human gate only — do not auto-start)

```text
LM06-BOARD-TENSOR-REACHABILITY-01
ONE UNKNOWN: are tile_weight_pingpong + tile_activation on the
frozen LM06 causal output cone? (A required / B removable ~34 / C mixed)
F1 pingpong lifetime ONLY after A.
```

### Bench status (orthogonal)

`ddr_cue_soa_bench_01` still owned by Cursor per Codex assignment; BRAM sync does not change that unknown.

## Result (Cursor → Codex) — attempt 9 metadata correction

**Gate:** `ddr_cue_soa_00r_axi_liveness`  
**Attempt:** 9  
**Mode:** `METADATA_CORRECTION_ONLY` (REJECT_METADATA follow-up)  
**Engineering result:** **FAIL** (`NO_QUERY_AR`) — **unchanged**  
**Attempt 10:** not started  
**Board:** no

### ONE UNKNOWN (answered for metadata scope)

Can live authority metadata match sealed v13 evidence without rerun or changing the engineering result? **Yes** — LOOP_STATE snapshot aligned; CLOSEOUT FACT §2 disambiguated.

### Corrections applied

| File | Change |
|------|--------|
| `LOOP_STATE.json` | `xsim_snapshot` `v12` → `v13` (this gate only; no other queue field) |
| `00R/CLOSEOUT.md` | FACT §2: 39 AR chronologically after `SOA_QUERY_START`; `ar_after_start=0` = TB `start_seen` counter miss, not zero traffic |
| `DISPATCH_LOG.jsonl` | One `CORRECTION` line appended (`METADATA_CORRECTION_ONLY`) |

### Unchanged

- Sealed log SHA `A871F5C5…B7F831`; FAIL markers; H_RIVAL SUPPORTED; engineering 832 B OPEN; SOA not falsified; no rerun; no promotion.

`lock.owner=none`. Await Codex fresh evidence audit (r2). No attempt10.

## Result (Cursor → Codex) — attempt 9

**Gate:** `ddr_cue_soa_00r_axi_liveness`  
**Attempt:** 9  
**Agent:** [a7-ng-memory-arch](cf0914b9-399b-4790-83e0-f529361a0eb4)  
**Result:** **FAIL** (`NO_QUERY_AR`)  
**Marker:** `A7NG_DDR_CUE_SOA_XSIM_PASS` — not observed  
**Evidence_class:** `MIG_XSIM` only — no board  
**Attempt 10:** not started

### ONE UNKNOWN

Does every hang-bearing DDR command sequence have a corresponding actual AXI AR fire on the monitored query channel, and what is the first query AR address?

### Verdicts

| Hypothesis | Result |
|------------|--------|
| H_CANDIDATE (unconditional ledger) | **PARTIAL** — 39 AR fires logged; first addr `0x01000000` (ID-plane); QUERY tag never latched |
| H_RIVAL (bank1 col018 has no query-channel AR) | **SUPPORTED** |
| Engineering 832 B | still **OPEN**; SOA **not falsified** |

### Key FACTS

- First ledger AR: `0x01000000` @ 126290625 ps, `tag=PRELOAD`, `running=1`, `query_active=0`
- `SOA_AR_COUNTS before_start=39 after_start=0 query_ar_seen=0 wait_cyc=1024`
- `SOA_NO_QUERY_AR` then sealed `$finish` @ 138494625 ps
- DDR bank1 col018 @ 126072466 / 126084466 — **before** first query-channel AR; no matching `SOA_AR_LEDGER`
- Zero PRIOR-plane AXI AR (`0x0300xxxx`)
- `B_RREADY` / PRIOR-first hang remain **NEEDS_EXPERIMENT** (cut off mid-CUE)

### Evidence

| Artifact | Path |
|----------|------|
| Closeout | `results/A7-NATIVE-GRAPH/DDR-CUE-SOA-00/00R/CLOSEOUT.md` |
| MIG log | `results/A7-NATIVE-GRAPH/DDR-CUE-SOA-00/xsim_ddr_cue_soa.log` (SHA `A871F5C5…F831`) |
| Log copy | `00R/xsim_ddr_cue_soa_attempt9.log` |
| DISPATCH | attempt=9 FAIL `NO_QUERY_AR` |
| LOOP_STATE | attempt 9, OPEN, FAIL |

No live xsim/xsimk. No parent `--dispatch`. `lock.owner=none`. Codex launches independent audits.

## Audit Request (Codex -> Cursor) - attempt 9 Layer C

Launch fresh independent READ_ONLY Tasks; no edits or reruns:

1. `a7-evidence-auditor` -> `00R/AUDIT_attempt9_evidence.md`: verify sealed hashes/markers/counts/times; bank1 col018 before QUERY_START; first ledger AR `0x01000000`; zero 0x0300 AR; distinguish FACT from start-latch-race inference; DISPATCH/LOOP consistency; challenge the `NO_QUERY_AR` name.
2. `a7-hlb-auditor` -> `00R/AUDIT_attempt9_hlb.md`: verify one unknown, TB-only host boundary, no host answer/gradient/winner/address, no board/COM12, no law/claim expansion.
3. `a7-ng-xsim-verify` -> `00R/AUDIT_attempt9_xsim_verify.md`: existing logs only; verify v13 compile, clean `$finish`, marker set, hash equality primary/copy, no live simulation process, exact changed paths, unit not rerun.

Evidence integrity only, not gate success. Return lock `none` after three reports exist. No attempt10.

## Acceptance (Codex) - attempt 9 pre-correction

GATE: `ddr_cue_soa_00r_axi_liveness`  
CLAIM CURSOR: bounded MIG_XSIM FAIL `NO_QUERY_AR`; ledger proves bank1 col018 precedes query start and first chronological query AR is ID-plane `0x01000000`; tag miss from TB start race.  
EVIDENCE FILES EXIST: yes - closeout, sealed primary/copy, console, DISPATCH/LOOP, three audits.  
DISPATCH last line == LOOP_STATE first OPEN: yes on gate/attempt/result, **no** on snapshot (`LOOP_STATE v12`, evidence v13).  
IMPLEMENTER == pipeline character_id: yes - `a7-ng-memory-arch`; no parent dispatch.  
ONE UNKNOWN: yes.  
XSim!=board labelled: yes.  
AUDITOR evidence-auditor: PASS with MAJOR snapshot drift - `AUDIT_attempt9_evidence.md`.  
AUDITOR hlb: PASS/CLEAN - `AUDIT_attempt9_hlb.md`.  
AUDITOR xsim: PASS - `AUDIT_attempt9_xsim_verify.md`.  
SELF-AUDIT A still holds: no until live LOOP metadata matches v13.  
VERDICT: **REJECT_METADATA**; engineering diagnostic remains valid FAIL/OPEN.  
NEXT: metadata-only correction below. No attempt10.  
BOARD_PASS declared by AI: NEVER.

## Request (Codex -> Cursor) - attempt 9 metadata correction

ONE UNKNOWN: Can live authority metadata and closeout wording be made exactly consistent with sealed attempt-9 v13 evidence without rerun or changing the engineering result?

ALLOWED PATHS ONLY:
- `results/A7-NATIVE-GRAPH/STATUS/LOOP_STATE.json`: set this gate's `xsim_snapshot` from `v12` to `v13`; no other queue field.
- `results/A7-NATIVE-GRAPH/DDR-CUE-SOA-00/00R/CLOSEOUT.md`: clarify 39 AR are chronologically after `SOA_QUERY_START`, while `after_start=0` is the TB `start_seen` counter; no claim change.
- `results/A7-NATIVE-GRAPH/STATUS/DISPATCH_LOG.jsonl`: append one CORRECTION line only.
- `.agents/handoff/**`.

FORBIDDEN: all source/tests/raw logs, simulation, attempt10, board/COM12, failure-result promotion. DONE: corrected files, structured Result, lock none; then one fresh evidence audit.

## Audit Request final (Codex -> Cursor) - attempt 9 metadata

Launch one fresh `a7-evidence-auditor` READ_ONLY -> `00R/AUDIT_attempt9_evidence_r2.md`. Verify only: LOOP_STATE snapshot is v13 and no other queue field changed by correction; CLOSEOUT chronology/counter sentence is unambiguous and claims unchanged; DISPATCH CORRECTION append exists; source/tests/raw logs/hashes untouched; engineering FAIL/OPEN and no attempt10/board. Return lock `none` and append `audit_metadata_complete`.

## Acceptance (Codex) - attempt 9 final

GATE: `ddr_cue_soa_00r_axi_liveness`  
CLAIM CURSOR: bounded v13 MIG_XSIM diagnostic FAIL `NO_QUERY_AR`; AXI provenance ledger shows first chronological query AR is ID-plane and prior bank1 DDR reads predate query start.  
EVIDENCE FILES EXIST: yes - corrected closeout, sealed log/copy, console, DISPATCH/LOOP, evidence r2, HLB, XSim audits.  
DISPATCH last line == LOOP_STATE first OPEN: yes - same gate, attempt 9, FAIL, v13.  
IMPLEMENTER == pipeline character_id: yes - `a7-ng-memory-arch`; no parent dispatch.  
ONE UNKNOWN: yes.  
XSim!=board labelled: yes.  
AUDITOR evidence-auditor: PASS/CLEAN - `AUDIT_attempt9_evidence_r2.md`.  
AUDITOR hlb: PASS/CLEAN - `AUDIT_attempt9_hlb.md`.  
AUDITOR xsim: PASS - `AUDIT_attempt9_xsim_verify.md`.  
SELF-AUDIT A still holds: yes for attempt 9 after metadata correction; only allowed paths changed, no board, no frozen bit, no parent dispatch.  
VERDICT: **ACCEPT** this diagnostic FAIL as valid evidence. Gate remains **OPEN**; SOA not falsified.  
NEXT: do not open attempt 10 in this turn. Next one-unknown candidate is a race-free TB start/query tag, then continue the 52-beat ledger.  
BOARD_PASS declared by AI: NEVER.

## Self-audit (Codex) - attempt 10

- FACT: attempt 9 logged 39 AXI AR fires chronologically after query start; first was ID `0x01000000`; `NO_QUERY_AR` was a TB `start_seen` race.
- ONE UNKNOWN: Does a race-free start/query tag allow the unchanged DUT to complete the lawful 16 ID + 32 CUE + 4 PRIOR = 52-beat / 832-byte query?
- Target: Arty A7-100T `xc7a100tcsg324-1`; Vivado 2026.1; MIG_XSIM only.
- No RTL/law/MIG IP/board/COM12/frozen-bit changes. TB + snapshot name only.
- XSim is not board. Host does not compute winner/answer/gradient/address.

## Request (User -> Codex) - attempt 10 direct implementation

User explicitly authorized Codex to implement attempt 10 directly. Scope: remove the TB start race deterministically, retain bounded fail-fast behavior, run v14 MIG_XSIM, archive exact evidence, and return lock. No board action.

## Result (Codex -> Cursor) - attempt 10

**Gate:** `ddr_cue_soa_00r_axi_liveness`
**Attempt:** 10
**Result:** **FAIL** (`CUE_COMPLETION_TIMEOUT`)
**Evidence:** `MIG_XSIM` v14 only; no board/COM12
**PASS marker:** absent

### Answer to the one unknown

Race-free start/query tagging works, but the unchanged DUT does not complete 52 beats / 832 bytes.

- `SOA_AR_FIRST_QUERY addr=0x01000000`; query tag seen after 8 UI cycles.
- Exact query AR ledger: 16 ID + 32 CUE + 0 PRIOR = 48.
- Bounded stop: `id_beats=16 cue_beats=0 prior_beats=0` after 8192 cycles.
- Clean `$finish` at 224606625 ps; no live Vivado/XSim process afterward.
- RTL hashes unchanged; only the TB start timing/counters and v14 snapshot name changed.

### Root-cause boundary

The attempt-9 TB race is closed. The next real bottleneck is within the CUE R-return/completion boundary: the DUT emits all CUE ARs but never commits CUE completion, so no PRIOR AR can be issued. Exact first bad signal remains `NEEDS_EXPERIMENT`.

### Evidence

- Closeout: `results/A7-NATIVE-GRAPH/DDR-CUE-SOA-00/00R/CLOSEOUT.md`
- Sealed log: `00R/xsim_ddr_cue_soa_attempt10.log`, SHA256 `BA3D7211...A82626F1`
- Console: `00R/attempt10_vivado_console.log`, SHA256 `988CA272...B2F8AF8FC`
- TB SHA256 `7874A9D1...23E2A3B2`; Tcl SHA256 `42DA9172...503EFD3`

## Acceptance (Codex) - attempt 10

GATE: `ddr_cue_soa_00r_axi_liveness`
ONE UNKNOWN answered: yes — race fixed, unchanged-DUT completion falsified.
EVIDENCE FILES EXIST: yes — sealed log/copy, console, closeout, DISPATCH, LOOP_STATE.
DISPATCH last line == LOOP_STATE first OPEN: yes — attempt 10, FAIL, v14, `CUE_COMPLETION_TIMEOUT`.
BOUNDED TERMINATION: yes — `$finish`; no lingering simulator.
RTL edited: no.
XSim != board labelled: yes.
VERDICT: **ACCEPT_DIAGNOSTIC_FAIL**. Gate remains **OPEN**.
NEXT UNKNOWN: first failing CUE R/completion invariant.
BOARD_PASS declared by AI: NEVER.

## Notes

- Cursor chat: `f66cc793-5eb0-41d2-ae4f-46f101e32b87`
- Codex: `codex://threads/01a02edc-411a-72e2-9e9b-15c77f4198f5`

## Self-audit (Codex) - ddr_cue_soa_bench_01 assignment

- FACT: 00R is DONE_ENG at MIG_XSIM+XSIM_UNIT; final candidate is v22, 832 B/query, exact AOS Global Top8, protocol clean.
- FACT: `LOOP_STATE.next=ddr_cue_soa_bench_01`, status OPEN; authority is Blueprint V2 Phase B and `GATE_IRON_LAW_TEMPLATE.md`.
- PROCESS FACT: preflight `--dispatch` incorrectly selected `a7-ng-orchestrator` because the new bench gate was absent from pipeline/fallback metadata.
- ONE UNKNOWN: at frozen law and identical candidate/query/control content, does SOA improve `B_query` and/or measured `memory_wait` versus AOS?
- H_CANDIDATE: SOA reduces B_query 1024->832 and lowers or does not materially worsen memory-wait/query time under identical MIG traffic.
- H_RIVAL: three-plane/control overhead erases the byte reduction, so memory-wait/query time is equal or worse despite 18.75% fewer useful bytes.
- FALSIFIER: no matched-law AOS control, bytes not 1024/832, Top8 mismatch, protocol/conservation error, or SOA query cycles/memory_wait regress beyond preregistered tolerance.
- UNIT: one independent 64-candidate query per registered traffic cell; clock cycles within one query are not replications.
- CONTROL: frozen AOS and v22 SOA logical content/query/TermGen/scorer/Global Top-K; same MIG model, UI clock, candidate set, warmup and traffic cell.
- METRICS: B_query, R beats, AR bursts, query cycles, memory_wait cycles/fraction, candidates/cycle sustained, protocol counters, Global Top8, optional resource delta reported separately.
- XSim is not board. ALLOW_BOARD=no; no COM12/programming/bitstream/timing claim.
- No host gradient/winner/address/answer; no frozen bit/MIG project/law/schema/LM/encoder/GlassBox change.
- Patch must be benchmark/harness/telemetry only; no optimization redesign inside the bench gate.

## Request (Codex -> Cursor) - ddr_cue_soa_bench_01

[CODEX -> CURSOR] assignment
chat: `f66cc793-5eb0-41d2-ae4f-46f101e32b87`
tree: `d:\Jetking_sem4\SEM_4\arty-a7-online-lm`
lock.owner must remain `cursor` until Result is complete.

GOAL program: `NATIVE_V1_MINI_AI_BOARD_PASS`
GATE: `ddr_cue_soa_bench_01`
ROLE: implementer `a7-ng-memory-arch`; benchmark only, no optimization redesign.
ALLOW_BOARD: **no**. Do not program COM12, create bitstreams, or invoke hardware.

UNKNOWN (one): At frozen law and identical logical content/traffic, does SOA reduce `B_query` and/or common external `memory_wait` versus AOS?

H_CANDIDATE: SOA changes 1024 -> 832 useful bytes and is a Pareto win: common query cycles and common wait cycles are no worse in both registered cells.
H_RIVAL: three-plane fetch/control overhead erases the byte benefit; SOA is byte-only tradeoff or slower.
FALSIFIER: unmatched law/content, wrong 1024/832 bytes, oracle/protocol/conservation mismatch, incomparable wait definitions, or any unreported latency regression.

UNIT: one complete independent 64-candidate query. Clock cycles inside one query are not replications.

CONTROL / candidate:
- AOS and SOA must use identical IDs 0..63, `{cue32,cue32}`, prior=3, query cue buses, TermGen/scorer/Global Top-K laws and oracle IDs `9,11,25,27,41,43,57,59` @ score165.
- Same Digilent MIG model, UI clock, reset/calibration/warmup and consumer-ready behavior.
- Cells: `(burst=16,outstanding=1,consumer_ready=1)` and `(burst=16,outstanding=8,consumer_ready=1)`.
- Freeze/read-only Attempt10 v22 RTL and evidence.

COMMON METRICS (same TB-level semantics for both paths):
- `B_query`, R beats, AR bursts.
- `L_first_wave`: first query AR fire -> first accepted 16-candidate wave.
- `L_last_wave`: first query AR fire -> fourth accepted wave.
- `L_query`: first query AR fire -> final Global Top-K valid/done.
- `M_wait_common`: within first-AR -> fourth-wave window, consumer-ready cycles without a wave fire. Do not substitute incomparable internal counters as the headline.
- `DDR_service_span`: first AR fire -> last R fire.
- sustained candidates/cycle = `64 / L_query`; effective useful B/cycle = `B_query / DDR_service_span`.
- protocol/conservation counters and full Global Top-8.

PREREGISTER before measurements in `results/A7-NATIVE-GRAPH/DDR-CUE-SOA-BENCH-01/PREREGISTER.md` using `STATUS/GATE_IRON_LAW_TEMPLATE.md`.

VERDICT classes, fixed before run:
- `PARETO_WIN`: exact byte reduction, correctness/protocol clean, and SOA `L_query <= AOS` plus `M_wait_common <= AOS` in both cells.
- `BYTE_ONLY_TRADEOFF`: exact byte reduction/correctness but either common latency/wait metric is worse; explicitly forbid any faster claim.
- `FAIL`: correctness/protocol/control mismatch or byte reduction not established.

ALLOWED PATHS:
- new benchmark-only `tests/xsim/*ddr_cue_soa_bench*`
- `results/A7-NATIVE-GRAPH/DDR-CUE-SOA-BENCH-01/**`
- one final implementer line in `STATUS/DISPATCH_LOG.jsonl`
- `.agents/handoff/**`

FORBIDDEN:
- edits to `rtl/**`, existing Attempt10 v22 TB/Tcl/log/closeout, MIG IP/project, frozen bits, laws/schema, LM/encoder/GlassBox, LOOP_STATE
- wall-clock speedup claims; use UI cycles only
- board/COM12/hardware

DISPATCH first:
`python .agents/workflows/native-graph/run_blueprint_loop.py --dispatch`
Confirm it says `subagent_type=a7-ng-memory-arch`, then use that Task. Parent must not implement the benchmark itself.

DONE only when Result contains OBSERVATION/UNKNOWN/H_CANDIDATE/H_RIVAL/FALSIFIER/UNIT/CONTROL/METRICS/COMMANDS/ARTIFACTS/PASS|FAIL, exact hashes, sealed logs, and `lock.owner=none`.
Then stop. Codex will run independent auditors.

## Result (Codex -> Cursor) - Attempt 10 final

- GATE: `ddr_cue_soa_00r_axi_liveness`
- VERDICT: **PASS / DONE_ENG**
- EVIDENCE CLASS: `MIG_XSIM + XSIM_UNIT`; not board
- FINAL MIG: v22, exact 4 AR, 52 beats, 832 bytes, planes16/32/4, 64/64, 4 waves, protocol0, conservation52/52/52, owner idle.
- AOS equivalence: Global Top8 IDs `9,11,25,27,41,43,57,59`, all score165, both patterns.
- STALL UNIT: AR coverage4, R coverage6, backpressure6, stability errors0, 8/8 ordered beats.
- AUDITS R3: evidence PASS, HLB PASS, XSim PASS.
- CLOSEOUT: `results/A7-NATIVE-GRAPH/DDR-CUE-SOA-00/00R/CLOSEOUT.md` SHA `E0417DF7...D1F49E5A3`.
- LOOP: repair and parent SOA gate `DONE_ENG`; `ddr_cue_soa_bench_01` is next OPEN.
- BOARD/COM12: untouched. AI does not declare BOARD_PASS.

## Acceptance (Codex) - Attempt 10 final

GATE: `ddr_cue_soa_00r_axi_liveness`
CLAIM: frozen 104-bit descriptor delivered in exact 832 B / 64-candidate query with protocol-clean 4-AR plan and AOS-equivalent Global Top8.
EVIDENCE FILES EXIST: yes — v22 MIG log, protocol stall unit, closeout, preserved falsifiers, three r3 audits.
DISPATCH last line == LOOP_STATE completed gate: yes — attempt10 PASS, v22, MIG_XSIM+XSIM_UNIT.
ONE UNKNOWN: yes per sequential falsification round; each failed round preserved before the next.
XSim != board labelled: yes.
AUDITOR evidence r3: PASS — `AUDIT_attempt10_final_evidence_r3.md`.
AUDITOR HLB r3: PASS — `AUDIT_attempt10_final_hlb_r3.md`.
AUDITOR XSim r3: PASS — `AUDIT_attempt10_final_xsim_r3.md`.
SELF-AUDIT A still holds: yes; no frozen/MIG project/host-answer/board change.
VERDICT: **ACCEPT / DONE_ENG**.
NEXT: `ddr_cue_soa_bench_01`; do not auto-run in this turn.
BOARD_PASS declared by AI: NEVER.

## Self-audit (Codex) - attempt 10 closure

- FACT: v14 fixed the TB start race and emitted exactly 16 ID + 32 CUE + 0 PRIOR query AR; committed counters ended ID=16, CUE=0, PRIOR=0.
- INFERENCE: the first unresolved defect is at the CUE R-return/completion boundary; no exact RTL cause is claimed before instrumentation.
- ONE UNKNOWN: Which first invariant fails between MIG R fire, plane-engine returned/pending/in_flight, pf_done_pulse, and the CUE-to-PRIOR phase transition?
- H_CANDIDATE: all 32 CUE R beats return, but completion state is lost or blocked at the plane boundary.
- H_RIVAL: CUE R traffic itself stops or is not accepted before 32 beats.
- FALSIFIER: a bounded trace must identify the first cycle where accepted credit, R fire, returned, pending, in_flight, or phase diverges.
- UNIT: one 64-candidate query; target 4 AR transactions, 52 R beats, 832 bytes, two registered patterns for final confirmation.
- CONTROL: frozen 104-bit descriptor, AOS oracle, laws and frozen RTL lanes unchanged.
- XSim is not board; no COM12/programming; no host gradient/winner/address/answer.
- No frozen bitstream overwrite; no schema/TermGen/scorer/Top-K/LM/encoder/GlassBox change.
- Latest user authorization permits Codex direct implementation for this attempt; only Codex owns product writes while this lock is active.

## Attempt 10 closure R1 result / R2 preregistration

- R1 RESULT: **FAIL**, but the stale completion fix is validated. v15 reached exact ID=16, CUE=32, PRIOR=4, AXI=52 beats/832 bytes.
- R1 FALSIFIER: `phase=DRAIN`, `delivered=48`, `waves=3`, `need_pack=0`, both banks empty; query timed out.
- R1 evidence: `00R/xsim_ddr_cue_soa_attempt10_closure_r1.log`, SHA256 `22E7B589...40F1736B`.
- R2 ONE UNKNOWN: after a wave is consumed and `del` already includes it, does re-arming pack on `del < target` produce exactly the fourth wave and 64/64 completion?
- R2 H_CANDIDATE: one final pack is armed, then `delivered=64`, `waves=4`, `done=1` for both traffic patterns.
- R2 H_RIVAL: another independent drain/consumer/topk invariant still blocks completion.
- R2 FALSIFIER: timeout, waves!=4, delivered!=64, bytes/beats/planes mismatch, data mismatch, or missing final marker.
- R2 patch surface: one drain predicate in `a7ng_cue_soa_wavefront.sv`; TB prereg/snapshot only. No other law/RTL lane/board change.

## Attempt 10 closure R2 result / final confirmation preregistration

- R2 RESULT: `A7NG_DDR_CUE_SOA_XSIM_PASS`; both patterns reached exact 832 B / 52 beats / ID16 CUE32 PRIOR4 / delivered64 / waves4 / mismatch0.
- R2 evidence: `00R/xsim_ddr_cue_soa_attempt10_closure_r2.log`, SHA256 `66511769...E413DA0`.
- EVIDENCE GAP: pattern 2's optional AR-order monitor reported `first4_cnt=0`, and final Top-1 was conditional on a non-sticky pulse. DUT data/beat result passed, but closeout-quality evidence is incomplete.
- CONFIRM ONE UNKNOWN: does unchanged R2 RTL pass when both patterns must retain four ID-first AR addresses and sticky final Top-1 id=57 score=165 over exactly four batches?
- CONFIRM patch surface: TB evidence retention/checks plus v17 snapshot only; no DUT RTL change from v16.
- CONFIRM FALSIFIER: either pattern lacks four ID-first ARs, lacks Top-K evidence, top1 differs from 57/165, batches!=4, or any prior R2 invariant regresses.

### Confirmation compile correction

- v17 did not simulate: XELAB rejected `topk_seen/top1_*_seen` because the new TB-only sticky registers had both `initial` and `always_ff` procedural drivers.
- Correction: remove only the redundant `initial` assignments; reset remains in the monitor while `feed_en=0`. Snapshot bumped to v18. DUT RTL and confirmation criteria unchanged.

## Attempt 10 v18 result / AOS control-parity preregistration

- v18 RESULT: **FAIL 2/2 SCORE_LAW** while transport and conservation remained exact; both patterns produced final per-wave Top-1 `id=55 score=173`.
- Independent executable oracle confirms `55/173` is lawful for the v18 SOA fixture `{cue32,~cue32}, prior=1`; it is not evidence of corrupt DDR data.
- CONTROL mismatch found: sealed AOS wavefront widens cue as `{cue32,cue32}` and supplies prior=3; its final-wave control is `57/165`. The SOA fixture had encoded different logical content, so the earlier AOS==SOA claim was invalid.
- ONE UNKNOWN: with identical AOS logical content encoded in SOA columns, does physical layout preserve final-wave Top-1 `57/165` for both patterns while all transport metrics remain exact?
- H_CANDIDATE: yes; only fixture pack/golden diagnostic values change, no TermGen/scorer/Top-K/transport law.
- H_RIVAL: physical SOA delivery changes content/order despite identical fields.
- FALSIFIER: either pattern differs from 57/165, misses sticky Top-K/AR-order evidence, or regresses any 832/52/16-32-4/64/4 invariant.

### Global control-parity correction before run

- Independent audit corrected the target: `57/165` is only the AOS final-wave diagnostic, historically NON-GATE. Authority requires Global Top-K over all 64 candidates.
- Frozen AOS oracle: Global Top-1 `9/165`; Global Top-8 IDs `9,11,25,27,41,43,57,59`, all score 165.
- The SOA top lacked the already-proven `a7ng_topk_wavefront_global`; v19 was therefore not run.
- Minimal integration: feed the existing reducer from each local NG02 Top-8, clear on `wf_start`, expose its outputs, and block a new wave while the reducer is busy. No comparator/score/TermGen law change.
- Final UNKNOWN: does AOS-identical SOA content reproduce all eight global slots for both traffic patterns while retaining exact transport/conservation metrics?

## Attempt 10 v20 result / final 4-AR authority confirmation

- v20 RESULT: **PASS stress** for burst1/out1 and burst4/out8; exact transport, conservation, 4 global merges, and 8/8 AOS Global Top-K in both patterns.
- AUTHORITY GAP: v20 used 52 and 13 AR transactions respectively, while the 00R transaction plan requires exactly four: ID16, CUE16+16, PRIOR4.
- FINAL UNKNOWN: with burst16 and outstanding 1 vs 8, does the same RTL execute exact AR `(0x01000000,len15)`, `(0x01100000,len15)`, `(0x01100100,len15)`, `(0x03000000,len3)` and retain every v20 metric/oracle result?
- No DUT RTL change from v20; only stricter TB traffic/config/transaction assertions and snapshot v21.

## Attempt 10 v21 audit result / protocol-final preregistration

- v21 RESULT: PASS_NARROW — exact 4 AR, 52/832, planes16/32/4, 64/4, 4 merges, Global Top8 8/8 for both outstanding settings.
- Independent HLB audit: PASS/CLEAN (`AUDIT_attempt10_final_hlb.md`).
- Independent evidence and XSim audits: REJECT promotion because v21 wired but did not assert/print expected/received, RRESP/RLAST/RID, or AR/R stall stability.
- v22 ONE UNKNOWN: do all protocol and conservation counters remain clean when explicitly gated, with no DUT change from v21?
- v22 H_CANDIDATE: `expected=received=consumed=52`, plane sum 52, plane bytes=AXI bytes=832, RRESP/RLAST/RID/stall errors 0, owner idle, plus every v21 invariant.
- v22 FALSIFIER: any nonzero protocol error, conservation mismatch, owner non-idle, or v21 regression.
- Scope: TB checker/prints/assertions plus snapshot only. v21 evidence is preserved.

## Attempt 10 v22 result / non-vacuous stall unit preregistration

- v22 RESULT: PASS for both patterns with protocol counters all zero and exact conservation; evidence and HLB r2 PASS.
- XSim r2 verdict: PASS_NARROW_ENHANCED only because MIG produced zero R backpressure and AR stall coverage was not counted; stability antecedents were vacuous.
- FINAL UNIT UNKNOWN: does the unchanged SOA bridge hold AR and R payloads stable under deliberately injected stalls while preserving all 8 response beats?
- H_CANDIDATE: `ar_stall_seen>0`, `r_stall_seen>0`, stability errors 0, bridge backpressure>0, expected=received=popped=8, bytes128, path idle.
- H_RIVAL: bridge or slave payload changes/drops under stall.
- Scope: new fast TB/Tcl only; no product RTL or long MIG rerun.

### Stall unit TB-race correction

- Unit R1/R2 injected nonzero stalls with zero stability errors but monitor counted beat 0 twice (`popped=9`, bridge received=8).
- Trace proved the consumer set `r_ready` with a blocking assignment on a posedge; checker and bridge could sample different READY values in the same slot. FIFO data sequence itself remained ordered.
- Correction: assert consumer READY on negedge. Product bridge RTL unchanged; failed unit logs preserved.
