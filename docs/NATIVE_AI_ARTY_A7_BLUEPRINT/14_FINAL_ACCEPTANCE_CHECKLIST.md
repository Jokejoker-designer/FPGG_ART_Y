# 14 — Final Native AI V1 Acceptance Checklist

> **Masterplan V2 note.** No gate below has been weakened. The additions clarify what already had to
> be true and make the required evidence class explicit. Every ticked box needs a file-backed
> artifact and one evidence label from
> `BOARD | POST_ROUTE | OOC | MIG_XSIM | XSIM | ENGINEERING_ESTIMATE | HISTORICAL_ESTIMATE`,
> with BOARD-class evidence wherever `04_HARDSTOPS.md` requires silicon.
> Current per-box status: `results/A7-NATIVE-GRAPH/PROJECT_COMPLETE.md`.
> Corrections and doctrine: [`00_CURRENT_AUTHORITY.md`](00_CURRENT_AUTHORITY.md).

## Hardware

- [ ] Integrated design fits `xc7a100t`.
- [ ] WNS >= 0.
- [ ] TNS = 0.
- [ ] Bitstream SHA archived.
- [ ] DDR map archived.
- [ ] Resource report archived.
- [ ] Physical PE count measured from RTL/report, not inferred.

## Learning boundary

- [ ] Host sends no gradients.
- [ ] Host sends no ΔW.
- [ ] Host sends no winner/address/hash.
- [ ] Teacher only supplies supervision during TRAIN.
- [ ] Learned graph/episode state changes on FPGA.

## Query attention

- [ ] Native derives entity anchor.
- [ ] Native derives intent/context cue.
- [ ] Same entity/different intent changes search ranking.
- [ ] Teacher sends no attention hint in blind exam.

## Knowledge graph

- [ ] Directed typed relations.
- [ ] Contextual bomb/prune.
- [ ] Wrong path does not reset global knowledge.
- [ ] Top-K evidence includes path/relation structure.

## Parallelism

- [ ] At least the declared number of physical lanes is truly concurrent.
- [ ] Logical agent count reported separately.
- [ ] Lane utilization measured.
- [ ] DDR stalls measured.

## Memory

- [ ] Persistent LM weights DDR-backed.
- [ ] Persistent graph/episodes DDR-backed.
- [ ] Persistent index DDR-backed where the final architecture claims it.
- [ ] BRAM used as a **bounded** active working set — declared bound and measured occupancy, both archived.
- [ ] Physical BRAM ownership documented: hierarchy, tiles, role, phase, persistent?, shareable?, DDR-backable?
- [ ] No two writers to one physical bank in one cycle.
- [ ] DDR bytes/query measured.
- [ ] Candidates/query measured.
- [ ] No hidden 800k full scan.
- [ ] 800k scale reports bytes/query and candidates/query.

Scope note: this section does **not** require every future experimental storage migration to have
happened. If Native V1 ships another evidence-backed configuration, the acceptance wording must be
edited to describe **the actual final design**, and each box must still be satisfied by that design
with its own artifact. It may not be satisfied by a migration that was only planned.

## Teacher-off

Required where the final contract supports the flag:

- [ ] teacher=0.
- [ ] external_LLM=0.
- [ ] learn=0.
- [ ] freeze=1.
- [ ] host_semantic_cue=0.
- [ ] host_winner=0.
- [ ] host_episode_address=0.
- [ ] host_next_token=0.
- [ ] host_weight_writes=0.
- [ ] held-out wording.
- [ ] unrelated reject.
- [ ] contradiction probe.

A UART framing stub or a constant flag readback does not satisfy these boxes. They require live
evidence on the programmed bit during the blind exam.

## LM-06

- [ ] LM-06 active on FPGA response path.
- [ ] Structured Native evidence is its input context.
- [ ] Host does not generate final answer.

The LM path requires the full chain:

```text
actual structured Native evidence
  -> LM-06 active compute path
  -> FPGA token generation
```

A probe, a stub, an `lm_path` sticky flag, or an evidence-compose marker alone must **NOT** satisfy
this section (`EVIDENCE_PACKET_PASS != LM06_ACTIVE_INTEGRATION_PASS`, HS-22).

## Reset/retrain

- [ ] Forget/reset removes learned behavior.
- [ ] Retraining a different mapping creates different behavior.

## Claims

- [ ] `P_LM = 802,816` reported separately.
- [ ] encoder parameters reported separately.
- [ ] graph nodes/episodes not added to parameter count.
- [ ] no open-domain/LLM/human-level claim without evidence.
- [ ] on-chip compute ceilings reported separately from sustained end-to-end throughput.

Parameter scaling beyond `P_LM = 802,816` (for example 1.5M) is a possible future scalability
consequence, **not** a Native V1 gate, and may not be claimed until evidenced.

## Final verdict

Only when every required item passes:

```text
NATIVE_V1_MINI_AI_BOARD_PASS
```
