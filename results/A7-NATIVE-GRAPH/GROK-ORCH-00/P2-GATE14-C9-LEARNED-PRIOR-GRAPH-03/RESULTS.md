# P2-GATE14-C9-LEARNED-PRIOR-GRAPH-03 RESULTS

**PROGRAM=NO.** FAST / XSim / OOC only. No COM12, JTAG, or unique bit.  
This agent does **not** declare `GATE14_PASS`, `TEACHER_OFF`, or `BOARD_PASS`.

Parent FAIL `P2-GATE14-20FACT-RESIDENT-02` and resident bit `A0B338E0…` are **preserved**. Oracle 549 was **not** replaced by 733.

## Return

```text
GATE=P2-GATE14-C9-LEARNED-PRIOR-GRAPH-03
CLASS=PASS_C9_GRAPH_XSIM_OOC
LM_RTL=not_run
UNIQUE_BIT=not_created
PROGRAM=NO
C9_LEARNED_PRIOR_GRAPH_XSIM_PASS fails=0 facts=20
HOLD_A C3 r1=0x80  C9 r1=0x20 pack=8382238122802120
UNREL  C3==C9 pack=8786858483828180
CONTRA r1=0x80  (typed R miss)
HOLD_B r1=0x40 pack=8382438142804140
C7 ack_count A=20 B=40  commit_seq matches writes
TRESET GEN 1→2  HOLD_A r1 returns 0x80
ORACLE frozen OUT HOLD_A=653 UNREL=689 CONTRA=237 HOLD_B=60
G5 549/861/237 unused
733 unused
```

## Unknown

Can G4 persisted prior keyed by FPGA `{subj,rel,obj,generation}` enter the **existing** scorer `learned_prior` term **before** the **existing** min-heap so C9 is the actual graph TopK?

## Architecture (EVIDENCE)

One G1, one G2, one `a7ng_learned_prior_store`, one `a7ng_scorer_lane`, one `a7ng_topk_stream_minheap`. Serial lookup. No second scorer/TopK/LM. C9 is graph drain, not persist FAST IDs `0706050403010002`.

20 distinct PRE_A tokens `0x10..0x23` (corpus f01..f20). Not 20 repeats of qid=1.

## XSim — EVIDENCE

`unit_xsim.log` SHA `CB441121…C934A78A`  sim 605800 ns

| Check | Result |
|-------|--------|
| C7 +1/lesson | ack_count 1..20 then 21..40, seq=20 after A |
| HOLD_A C3→C9 | r1 `80` → `20` (U0 → A0) |
| UNREL | C3 pack == C9 pack |
| CONTRA typed R | r1 `80` ≠ HOLD_A `20` |
| FLUSH/KILL/RELOAD | kill hides (r1=80); reload restores A0 |
| TRAIN_RESET | GEN 1→2; HOLD_A r1=80 (A forgotten) |
| Mapping B | HOLD_B r1=`40`; pack ≠ HOLD_A |

C9 packs are **not** existence `3B392B291B190B09` and **not** persist FAST IDs.

## LM oracle — frozen before any LM compare

`ORACLE.json` SHA `062932B3…54C912B`  law `lm06-signsgd-v1`  sanity pred=744

| Query | C9 pack | Python OUT |
|-------|---------|------------|
| HOLD_A | `8382238122802120` | **653** |
| UNREL | `8786858483828180` | **689** |
| CONTRA | `2322832182208180` | **237** |
| HOLD_B | `8382438142804140` | **60** |

RTL TinyGPT ntok=8 was **not** run in this bag (G5 already showed FPGA OUT ≠ this Python law). Do **not** retarget these integers. Unique bit **not** created.

## Parent regression — EVIDENCE

G4 `P2-PERSIST-GEN-FAST-SERIAL-STATE-01` re-run: `PERSIST_GEN_FAST_SERIAL_STATE_XSIM_PASS fails=0 CELLS=7`. G1/G2/G3/G4 source SHA unchanged.

## OOC P&R (`xc7a100tcsg324-1`, 80 ns) — EVIDENCE

```text
LUT  = 2919   (minheap 2430 existing; store 388; G1 46; scorer 42)
FF   = 1493
BRAM = 1.5 tile (RAMB36=1 RAMB18=1) in store
DSP  = 0
WNS  = +51.656  TNS=0
WHS  = +0.125   THS=0
CDC  = empty (single clock)
route_design completed, 0 failed nets
```

OOC ≠ full-chip. No bitstream.

## Classification

| Claim | Label |
|-------|--------|
| C9 graph TopK moves after 20 distinct A commits | EVIDENCE (XSim) |
| Unrelated unchanged; typed R miss; TRESET forgets A; B differs | EVIDENCE |
| C7 commit_seq/ack_count +1 per write | EVIDENCE |
| Parent G4 7-cell still PASS | EVIDENCE |
| OOC timing clean DSP=0 | EVIDENCE |
| Silicon C9 on A0B338E0 now graph-learned | FALSE_OR_OVERCLAIM (not programmed) |
| LM OUT matches frozen Python | NEEDS_EXPERIMENT (RTL LM not run) |
| GATE14_PASS / BOARD_PASS | not claimed |

## Must not (still)

Program `A0B338E0`. Touch FAIL bag. Use 549 or 733. 40 facts. Unique bit without RTL LM on these packs. Host idx/delta/address/cue/answer.

## Next (new token)

SoC glue: wire this store lookup into the live SoA candidate stream (replace persist-FAST-ID preempt). Then RTL LM vs **this** frozen oracle. Then unique bit if that PASSes. PROGRAM remains NO until a human token.
