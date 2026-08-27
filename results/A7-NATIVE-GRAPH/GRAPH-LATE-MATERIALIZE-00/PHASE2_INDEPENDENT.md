# Phase 2 — independent cores (user-authorized start)

**Written:** 2026-08-27  
**Authority:** human instruction this session — *proceed as if existence pred=664 for scheduling independent Phase 2 cores*  
**Does not declare:** `NATIVE_V1_EXISTENCE_BOARD_PASS`, `BOARD_PASS`, UART `pred=664` on silicon

## Honesty box

| Claim | Class |
|-------|--------|
| Last sealed UART capture E2R-HB-UART-00 r3: LAST=`CORE_START`, **pred=∅**, COM12 closed | BOARD (stall) |
| XSim Native V1 path: BIND_DONE → LM_ACTIVE → PRED_VALID, CONTROL pred **664** | XSIM |
| User authorized independent Phase 2 work now | HUMAN_DISPATCH |
| This file is **not** a silicon closeout | — |

Do not print `pred=664` as BOARD. Host still must not send winner/address/next-token.

## Independent vs blocked

| Work | Depends on UART pred=664? | Track | Owner this wave |
|------|---------------------------|-------|-----------------|
| `graph_late_materialize_00` RTL + XSim | **No** — XSIM evidence class; one unknown = payload after Top-K | Phase C graph IO | **this session + session A** |
| `lm06_wm_trace_00` trace/MRC skeleton | **No** — POST_ROUTE_PROXY later; measure `u_a` lifetime | Phase D LM WM (parallel) | **session B** |
| Host golden / anti-leak / mem_schema consumers | No | NG-00 already DONE | reuse |
| GlassBox Observatory (SYNTHETIC charts) | No | UI only | already shipped; not a core |
| `bram_owner_00` / `lm06_wm_ladder` | Yes (blocked on WM-00 + trace) | Phase E | **do not open** |
| HS-02 teacher-off **semantic** exam | Yes + LM-06 path | Phase G | **do not open** |
| Board reprogram / COM12 existence ladder | silicon existence | E2R | not this wave |
| TermGen / Top-K law retune | forbidden this gate | — | **no** |

## Phase 2 cores in this wave

### Core 1 — `graph_late_materialize_00` (Phase C)

```text
ONE UNKNOWN: Can expensive NodeRecordV1 fetch move after global Top-K
             without changing TermGen / scorer / Top-K law?
PRINCIPLE:   SCORE CHEAP EARLY — FETCH EXPENSIVE LATE
LAW:         a7ng-late-mat-v0
EVIDENCE:    XSIM (not BOARD)
FORBIDDEN:   fetch losers; AR before Top-K commit; host-supplied address;
             TermGen retune; HIT_MAX change; BOARD_PASS
```

RTL: `rtl/native_graph/memory/a7ng_late_materialize.sv`  
TB:  `tests/xsim/tb_a7ng_late_materialize.sv`  
Run: `tests/xsim/run_a7ng_late_materialize.tcl`

### Core 2 — `lm06_wm_trace_00` (Phase D, parallel)

```text
ONE UNKNOWN: What is u_a M_peak lifetime / tile residency under frozen LM-06 law?
NOT:         blind BRAM cut to 32
NOT:         existence ladder
```

Session B writes spec + instrumentation plan only until a freeze candidate exists.

## Skills / workflow

- `a7-fpga-gate`, `a7-native-graph-gate`, `scientific-method-native-ai`
- Blueprint loop: `docs/NATIVE_AI_ARTY_A7_BLUEPRINT/15_CURSOR_BLUEPRINT_LOOP.md`
- Live queue: `results/A7-NATIVE-GRAPH/STATUS/LOOP_STATE.json` (`next=graph_late_materialize_00`, still DEFERRED for *board* quality until existence file is sealed by human)
- Crew: `.agents/workflows/native-graph/{registry.yaml,pipeline.json}`

## Two helper sessions

| Session | character | authority | deliverable |
|---------|-----------|-----------|-------------|
| A | `a7-ng-xsim-verify` | VERIFY_ONLY | run XSim; archive GATE + SHA; no BOARD claim |
| B | `a7-ng-memory-arch` | PATCH_DRAFT | `lm06_wm_trace_00` GATE spec + non-silicon trace harness draft |
