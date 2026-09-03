# P2-GATE14-20FACT-RESIDENT-02 — preregistration

**PROGRAM=NO. RESIDENT_ONLY.** Do not `program_hw_devices`. Do not set `PROGRAM.FILE`.

Parent `P2-GATE14-LM-START-WIRE-01` = **PASS_NARROW_C10_G5_MATCH** (2-lesson surrogate, `cons_last=2`). Not Gate14-20.

Resident bit SHA (named):

```text
A0B338E0AF8836056574913B40106D2DA4DE388686067E7EDEF4D009D57F7E2B
```

Frozen corpus CONTROL (not UART payload):

```text
results/A7-NATIVE-GRAPH/TRAIN-V2/corpus_20.json
SHA256=23A4B5039CB80FECC338DF26BAB4E31EC8B314F7DBC178AD3AA572EA06963F8E
n_facts=20
```

## Unknown (one)

On the **resident** bit, can 20 A lessons each do query→C6 txn echo reward→C5 consume +1 exactly once→C7 MIG addr/busy settle, then FLUSH/KILL/RELOAD/FREEZE, emit live C0–C11 with GEN≠0, exam HOLD_A/UNREL/CONTRA match registered packs/OUT, TRAIN_RESET prove A forgotten, then 20 B lessons with the same txn/C7 discipline, FREEZE ADIG≠BDIG, blind HOLD_B match — without reprogramming?

## H_CANDIDATE

20× PRE_A (qid=1 train latch) + reward(+3, live txn) wraps the 20-fact CONTROL. Persist C7 AXI write after each consume is the MIG ACK. TRESET bumps GEN so A stamps are invalid (`a_for=1`, HOLD_A OUT≠549). Mapping B is 20× PRE_B.

## H_RIVAL

1. Config lost (C0 mismatch / no CFRAME) → `WAIT_NEW_TOKEN`.
2. 2-lesson surrogate already in working set; 20th consume does not move C5.
3. C7 pulse missed and addr sticky with no busy settle → cannot prove MIG ACK.
4. 20 rewards change persist ranking so C9 pack/OUT diverge from 549/861/237.

## Falsifier

Stop on first divergence. Preserve raw UART + CFRAME SHA. No 40-fact. No BOARD_PASS.

## Must not

Program any bit. Host idx/delta/address/cue/topk/answer/MODE. `refuse_corpus` on UART objects only (corpus JSON `contradiction` key is CONTROL, not a command). Call 2-lesson a 20-fact PASS.
