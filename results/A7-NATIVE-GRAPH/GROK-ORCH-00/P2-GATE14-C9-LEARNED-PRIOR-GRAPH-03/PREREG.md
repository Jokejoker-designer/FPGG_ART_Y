# P2-GATE14-C9-LEARNED-PRIOR-GRAPH-03 — preregistration (before data)

**PROGRAM=NO. FAST / XSim first. No COM12. No JTAG. No board. No unique bit until this bag PASSes XSim + parent regressions + OOC P&R/CDC/resource.**

Parent `P2-GATE14-20FACT-RESIDENT-02` = **FAIL_DIVERGENCE**. Earliest architectural miss is **C9_NO_LEARNED_PRIOR_IN_GRAPH**, not C10 OUT=733.

Preserve:

```text
resident_bit=A0B338E0AF8836056574913B40106D2DA4DE388686067E7EDEF4D009D57F7E2B
FAIL_bag=results/A7-NATIVE-GRAPH/GROK-ORCH-00/P2-GATE14-20FACT-RESIDENT-02
corpus_20=23A4B5039CB80FECC338DF26BAB4E31EC8B314F7DBC178AD3AA572EA06963F8E
G4_DUT=D1BF034018E1BBB28999EEDB6035278934F1AA898849EBA1E1F633B77DD4DAC9
G1=2219DA29…  G2=06143862…  G3=2177073D…
```

Do **not** overwrite the FAIL bag. Do **not** retarget oracle 549 to 733.

## Observation (silicon, already closed)

20/20 A lessons consumed (C5 2→22, txn 4..23). FLUSH/KILL/RELOAD/FREEZE GEN=4 worked. C9 stayed existence pack `3B392B291B190B09`. Persist FAST IDs were never the SoA graph TopK. G5 2-lesson MATCH used persist FAST IDs as LM evidence (preempt). That path is forbidden here.

## Unknown (one)

Can G4 persisted learned prior, keyed by FPGA `{subj,rel,obj,generation}`, feed the **existing** SoA scorer `learned_prior` term **before** the **existing** min-heap so that **C9 is the actual graph TopK after that term moves** — without replacing graph TopK with persist FAST IDs, without a second scorer/TopK/LM, with 20 **distinct** corpus facts (not 20× PRE_A), and with output-only C7 `commit_seq`/`ack_count` (+1 per real write)?

## H_CANDIDATE

Serial lookup/time-mux of the persist working set into `score_terms_t.learned_prior` on the live graph candidate stream changes min-heap order. C3 = same stream with prior forced 0. After 20 distinct A commits, HOLD_A C9 rank-1 is an A-key; C3 rank-1 stays unrel. Unrelated candidate set unchanged. Wrong rel (typed R) misses the A key.

## H_RIVAL

1. Key by slot/subject-only (G4 toy) so 20 distinct triples collide or wrap.
2. C9 still packed from persist FAST IDs (preempt) — FAIL this gate even if OUT looks pretty.
3. Constant prior on all HOLD_A candidates → ranking does not move (C3==C9).
4. C7 addr sticky with ack_count stuck → writes not observable.
5. TRAIN_RESET does not bump GEN / vis_w still true.

## Registered exam (direction, frozen before XSim)

FPGA-owned map: `FACT_MAP.md`. Host does not send idx/delta/address/cue/topk/answer.

HOLD_A mix: A[0..3] entity 8..5 + U[0..3] entity 10..7; other terms 8. Prior=0 ⇒ C3 rank-1 = U0 (`0x80`). One +3 prior on each A fact ⇒ C9 rank-1 = A0 (`0x20`).

UNREL set: U[0..7] only. C9 pack == C3 pack after A train.

CONTRA: HOLD_A IDs, lookup rel=2 (A stored rel=1) ⇒ miss ⇒ C9 rank-1 = U0, **not** HOLD_A C9 rank-1.

C7 `ack_count` = lesson index + 1 after each distinct fact (20 after A, 40 after B). `commit_seq` increments on each store write. Addr is FPGA-owned observability, not host authority.

FLUSH→BRAM_KILL→RELOAD: HOLD_A C9 rank-1 remains A0.

TRAIN_RESET: GEN+=1, A stamps invisible, HOLD_A C9 rank-1 returns to U0.

Mapping B (rel=2, obj C000+i): HOLD_B C9 rank-1 = B0 (`0x40`); HOLD_B pack ≠ HOLD_A pack.

## LM oracle (after C9, not before)

Dump actual C9 packs from XSim. Freeze Python `TinyGPT803k` OUT on those packs **once**. Do not edit ORACLE after the LM compare. Do **not** use G5 549/861/237. Do **not** use 733.

## Must not

Program A0B338E0. Touch FAIL bag. Duplicate scorer/TopK/LM. Preempt graph TopK with persist FAST IDs. 20 repeats of one token. 40 facts. Host address/idx/delta/cue/answer. Self-claim BOARD_PASS / GATE14_PASS / TEACHER_OFF. Unique bit if XSim or OOC fails.
