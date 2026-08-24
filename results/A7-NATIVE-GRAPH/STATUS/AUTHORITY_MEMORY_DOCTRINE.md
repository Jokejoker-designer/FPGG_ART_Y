# AUTHORITY — Native AI memory doctrine (LOCKED 2026-08-22)

Derived from `feedback.md` §9/§13/§14/§15 and `BRAM_WORKING_MEMORY_SPEC.md` §2/§9/§29/§31,
plus file-backed evidence: `MIG-METRIC-00/CLOSEOUT.md`, `BRAM-CONSOLIDATE/`, `TINYGPT-CONSOL/`.

## Locked doctrine

1. **LM-06 persistent weights are already DDR-resident.** The integration problem is not weight capacity.
2. **The integration problem is working-set BRAM:** LM-06 ~132 tiles + Native memory > 135 physical tiles.
3. **Final architecture:**
   - `DDR` = persistent capacity
   - `BRAM` = bounded active working set
   - `LUTRAM/FF` = ultra-hot state and control

## Forbidden (NO)

```text
UA128 + LM06 132 stacking
zero-BRAM LM
GRAPH and LM simultaneous BRAM ownership
```

## Required (YES)

```text
bounded tiles
ping-pong buffering
explicit phase ownership
```

## Locked gate order — one unknown per gate, no self-chaining

**Updated 2026-08-22** to match `LOOP_STATE.json` evidence. Historical ordering rationale preserved.

```text
MIG-METRIC-00       DONE_ENG (MIG_XSIM)
MIG-BOARD           DONE_ENG PASS_NARROW (pre-metric rows QUARANTINED)
MIG-BOARD-R2        DONE_ENG (BOARD_MIG — 16/16 silicon grid; quarantine superseded)
        ↓
DDR-WAVEFRONT-00    DONE_ENG PASS_NARROW (MIG_XSIM_WAVEFRONT)
        ↓
LM06-WM-00          DONE_ENG PASS_NARROW (LM06_WM_XSIM — bit-exact vs frozen CONTROL)
        ↓
LM06-WM-LADDER      BLOCKED — human re-open only (96/64/48/32 Pareto; 32 not mandatory)
        ↓
BRAM-OWNER-00       BLOCKED by ladder
        ↓
FULL INTEGRATION    BLOCKED by ownership + §14 gaps
```

**Current orchestrator stop:** `LOOP_STATE.next = STOP` (session_override `stop_after=mig_board_r2`).

**Rationale for ordering (unchanged):** cutting LM-06's 132 tiles before DDR delivery buffering is
measured would pick ladder targets blind. DDR-WAVEFRONT + LM06-WM-00 now satisfy that precondition
at XSim; ladder remains BLOCKED until human re-open.

## Session law

A Cursor session must not use "continue §14 queue" to auto-run multiple unknowns.
Orchestrator updates `LOOP_STATE` first, then opens exactly the first OPEN gate.

## Ladder stop rule (Pareto, not roadmap numbers)

Stop at the first rung with a good Pareto point. Reaching 32 is **not** mandatory.

```text
example:
64 BRAM  WNS +0.3  DDR stall acceptable  exact  -> WINNER
48 BRAM  WNS -0.2  DDR stall explodes            -> FALSIFIED
```

Do not force 32 merely because the roadmap contains the number 32.

## Gate contracts

### DDR-WAVEFRONT-00 (narrow)

UNKNOWN (only one): *From correctly measured MIG, can a bounded candidate/cue working set feed
16 physical lanes with exactly measured traffic?*

Path to try first:

```text
DDR -> sequential/burst compact cue fetch -> ping buffer A/B
    -> 16-candidate wave -> existing 16-lane scorer -> existing true Top-K
```

Must NOT change: 01R law, HIT_MAX, TermGen, Top-K, relation law, LM-06, 02M, training.

Metrics: `ddr_bytes_per_candidate`, `ddr_bytes_per_query`, `beats_per_query`,
`wavefront_fill_cycles`, `memory_wait_fraction`, `jobs_per_cycle_during_wave`,
`candidate_conservation`, `data_mismatch`.

**PE utilization >= 80% is NOT a hard gate here** — that is a scheduler-local gate.
A DDR path may be healthy while PEs work in bursts.

### LM06-WM-00

UNKNOWN: *Can the current working-set structure be replaced by bounded/ping-pong tiles and stay
bit-exact with frozen LM-06?* No 64/48/32 optimization at this step.

Gate = same input, same frozen weights, same arithmetic, same forward fold, same update fold,
same persist/reload result. Open the ladder only if `candidate == frozen CONTROL`.

### BRAM-OWNER-00

Minimum FSM:

```text
GRAPH -> BLOCK_NEW_WORK -> DRAIN_PE -> DRAIN_QUEUE -> DDR_COMMIT_IF_DIRTY
      -> VERIFY_QUIESCENT -> OWNER_SWITCH -> LM
LM    -> DRAIN -> OWNER_SWITCH -> GRAPH
```

Hard invariant: one physical bank -> one writer authority -> one cycle.
Stale entries die by `owner` / `epoch` / `valid` / `generation` — payload scrubbing per switch is
not required.
