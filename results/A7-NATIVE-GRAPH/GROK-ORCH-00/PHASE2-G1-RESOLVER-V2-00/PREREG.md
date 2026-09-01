# PHASE2-G1-RESOLVER-V2-00 — preregistration

Date: 2026-09-01
Prompt SHA-256: `DEC3A5AFE4BC65B7080A5C8D6575C99B6975648D21A9DA7BDE72550AB3FAEB96`
Baseline resolver SHA-256: `3A62B4E7942D26DFEFCF4A8F83376C29A36C6D02C3663C79F46A632A59FC15D3`
Contract: `a7ng-feedback-v2` (unit/OOC only). SoC instantiate ABSENT. PROGRAM=NO.

## One unknown

Can a bounded one-outstanding FPGA resolver accept only a correctly echoed reward in TRAIN mode, retain the complete evidence context under downstream backpressure, reject replay/orphan/range/mode-invalid traffic deterministically, and fit `<=500 LUT / <=500 FF / 0 BRAM / 0 DSP` with clean WNS/TNS?

## Law (frozen before coding)

1. Latch only if `learn=1`, `freeze=0`, no pending, no held consume, no held ACK.
2. FPGA mints `txn_o = {gen, seq}`. `seq` skips 0. Host may send only `reward` and `txn_echo`.
3. Consume requires `txn_echo_valid=1` and `txn_echo==pending txn`, reward in `[-3,+3]`, `learn=1`, `freeze=0`.
4. Consume record = `{subj,rel,obj,q_epoch,p_epoch,conf,contradict,signed reward,txn}`. No host address/index/delta/winner.
5. `consume_valid` holds all consume fields until `consume_valid && consume_ready`. Pending does not clear before that handshake, except reset. If `consume_ready=1` in the issue cycle, pending clears in that cycle (handshake-equivalent for the ready sink).
6. ACK is ready/valid held. New events stall while `ack_valid && !ack_ready`.
7. Priority: reset > freeze-drop of non-issued pending > in-flight consume completion > reward classify > latch.
8. Freeze with pending and no consume-in-flight: ACK_DROP, `n_drop`, pending=0, consume_valid=0. Freeze does not invent a consume. In-flight consume (already accepted) is allowed to finish; after it, consume_valid=0.
9. Rejects: RANGE (ack=3), ORPHAN (ack=2), LATE/missing-wrong-echo (ack=4), DUP/replay (ack=6), MODE (ack=7), DROP/freeze (ack=5). CONSUME ack=1.
10. Counters saturate at `16'hFFFF`, never wrap.
11. Wrap: `gen` increments when `seq` overflows; full `{gen,seq}` wrap clears `last_retired` valid. Stale echo of a previous generation cannot match the new pending id unless the entire TXN_W space reused. Residual collision only after `2^TXN_W` mints; documented, not silently accepted via seq-only compare.
12. No host-supplied winner/index/address/delta/answer ports.

## Falsifiers

Existing `tb_a7ng_feedback_resolver` and `tb_resolver_counterexample` must still PASS.
New `tb_a7ng_feedback_resolver_v2_rand` ≥100000 cycles with scoreboard.

## Resource target (OOC)

LUT<=500, FF<=500, BRAM=0, DSP=0, WNS>=0, TNS=0.
If missed: report exact numbers and STOP. Do not weaken semantics.

## Out of scope

PROGRAM, COM12/JTAG, full-chip, MIG, LM/TermGen/scorer/Top-K, graph reset-removal, Cursor worktree, Teacher-Off, Gate14 PASS.
