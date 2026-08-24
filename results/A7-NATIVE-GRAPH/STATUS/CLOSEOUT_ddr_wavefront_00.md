# STATUS closeout — ddr_wavefront_00

**RESULT:** DONE_ENG **PASS_NARROW** · `Evidence_class=MIG_XSIM_WAVEFRONT` · marker `A7NG_DDR_WAVEFRONT_XSIM_PASS`
**allow_loop_done_eng:** true (`a7-evidence-auditor`)
**next:** STOP — `lm06_wm_00` stays BLOCKED on `human_reopen`

## The unknown, answered

*From correctly measured MIG, can a bounded candidate/cue working set feed 16 physical lanes with
exactly measured traffic?* — **Yes for width and traffic; no for sustained throughput.**

| Pattern | burst | out | bytes | bursts | beats | conserv. | mismatch |
|---------|------:|----:|------:|-------:|------:|---------:|---------:|
| P1 | 1 | 1 | 1024 | 64 | 64 | 1 | 0 |
| P2 | 4 | 8 | 1024 | 16 | 64 | 1 | 0 |
| P3 | 4 | 8 (1-in-8 throttle) | 1024 | 16 | 64 | 1 | 0 |
| P4 | 16 | 8 | 1024 | 4 | 64 | 1 | 0 |

`jobs_per_emit_cycle = 16.0000`, 4/4 full waves, `min_wave_width = 16`,
`ddr_bytes_per_candidate = 16.0000`. Traffic is byte-identical to the MIG-METRIC-00 control, so the
wavefront cost zero extra DDR bytes.

## Why NARROW

- Sustained throughput **0.441** cand/cycle vs the prior one-per-cycle service's **0.444**. Widening
  the wave bought correctness and boundedness, **not** throughput.
- `memory_wait_fraction` **0.815–0.998**. `feedback.md` §9 DDR starvation is now *measured*, not solved.
- `bank_full_stall = 0` in 4/4 → boundedness is proven as **headroom**, not as a measured
  overflow-refusal. A saturating pattern is still owed.

## Verify

| Agent | Verdict |
|-------|---------|
| `a7-ng-xsim-verify` | PASS_NARROW (re-derived every number from the raw log) |
| `a7-vivado-gate` | PASS (19/19 live rehash MATCH; `mig.prj` AXI untouched; no build, no COM12) |
| `a7-evidence-auditor` | PASS_NARROW, `allow_loop_done_eng=true`, 10 findings |
| `a7-hlb-auditor` | PASS / HLB CLEAN, 0 violations |

Honesty checks all clean: per-run deltas (not cumulative), no undérived GB/s, backpressure is not
called a drop, PE utilization is a diagnostic not a gate, no board or Native V1 claim.

## Findings the parent acted on

1. **MAJOR — duplicate implementer dispatch.** Two implementers ran on one OPEN gate (orchestrator
   error after a session fork). Authority recorded in `AUTHORITY_DDR_WAVEFRONT_ARTIFACTS.md`; only
   the `tb_a7ng_ddr_wavefront` set is citable. `PINGPONG16/` is RETAINED but UNCITED, and its
   near-miss marker `A7NG_DDR_WAVEFRONT00_XSIM_PASS` is now named explicitly so it cannot be cited
   by accident.
2. **MAJOR — the carry-in number was overstated.** `max_resident` sums all 16 banks; per-bank peak
   was never instrumented, and `in_ready_o` stalls when any *single* bank fills. The 512 B figure is
   now labelled ENGINEERING_INFERENCE in `LOOP_STATE`, with instrumenting per-bank peak as a
   precondition on `lm06_wm_00`.
3. **HLB R1 carried forward.** Top-K here is per-batch 16→8 with no cross-wave reduction, so wave
   membership decides which candidates compete. Safe in this gate only because sequential `node_id`
   fixes the partition. Recorded on `lm06_wm_00` as `carried_risk_r1`.

## What this gate bought the roadmap

Candidate **delivery** is not the structure competing with LM-06's ~132 tiles. That conclusion
survives the caveats even though the exact 512 B number does not — which is precisely why this gate
ran before any LM-06 BRAM cutting.

## Session law honored

One unknown. No self-chaining. No COM12. No board latch. No later gate opened.
GOAL = **NOT EVIDENCED**. Human declares `NATIVE_V1_MINI_AI_BOARD_PASS`.
