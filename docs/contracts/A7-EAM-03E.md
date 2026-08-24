# A7-EAM-03E — Episodic Encoder

**Status:** A0 locked — see `A7-EAM-03E-A.md`. `XSIM_PASS` / `SILICON_FUNCTIONAL_PASS_WITH_NOTES` / `TIMING_FAIL` / `SEED_ROBUSTNESS_FAIL`. **A1 CLOSED.** Next rungs: **A0.1-T** then **A0.1-L** (`A7-EAM-03E-A01.md`).  
**Law:** `eam03e-a0-signsgd-v1`  
**Depends on:** A7-EAM-02M binding (so a cue has an episode to land in) + frozen 01R.  
**Does not depend on:** LM-06 hidden, Q1, Q2, wordpiece.

## Why this lane exists

02H showed LM-06 is the **wrong source of `h`** for semantic episodic keys.  
02M gives a useful store: many cues → one episode. It does **not** invent a cue for an unseen paraphrase.

03E is the scientific lane:

```
unseen paraphrase
      ↓
episodic encoder          ← this file (not written yet)
      ↓
cue near a bound episode
      ↓
01R retrieves it
```

Only then is **generalized episodic retrieval** a legal claim.

If 03E fails, 02M still stands. Do not roll back 01R or LM-06.

## Split (do not merge)

```
             ┌──────────── A7-LM-06 ────────────┐
text/bytes → │ language / prediction path       │   FROZEN
             └──────────────────────────────────┘

text/bytes → Episodic Encoder → 64-bit cue
                                  ↓
                               EAM-01R
                                  ↓
                          02M episode / value
```

LM solves prediction. The episodic encoder solves similarity/retrieval.  
One representation is not required to do both.

## First encoder (when a workorder opens RTL)

Not a second Transformer.

```
UTF-8 bytes                         ← same tokenizer as LM-06
    ↓
learned byte embedding 256 × 32     ← ~8 192 params
    ↓
32-D recurrent episodic state       ← Elman first (~2k); GRU optional
    ↓
sentence accumulator                ← last state or mean of steps
    ↓
64-bit binary projection            ← sign / frozen ±1, 0 DSP target
    ↓
01R + 02M
```

Budget: **tens of thousands of parameters**, not 803k.  
No DSP on the 64-bit projection if the 02Q Q1 style (add/sub) is reused.

Do **not** change the tokenizer in the first 03E rung. Same bytes, new objective.  
Only if that rung fails may a later contract open subword — never in the same step as a new net.

## Training objective

Not next-token loss.

```
same episode / paraphrase     →  near   (Hamming of 64-bit cues, or cosine of 32-D)
different episode             →  far
```

Host **may** send the relation `SAME` / `DIFF` and the UTF-8 bytes.  
FPGA **must** compute: encoder forward, distance / error, and the weight update.

Host must **not** send: hash, projection weights, memory address, precomputed Hamming winner, or the 64-bit cue.

HOLD / a held-out paraphrase bag is **unused for selection** (same discipline as 02H).  
A single 8-pair Hamming “perfect” split is `RESEARCH` at most — treat as MFE `LEARNABLE_SIGNAL`: not enough to declare generalized retrieval.

## Open / close gates (future WO)

Open RTL only after 02M xsim (and preferably silicon) shows multi-cue bind on frozen 01R.

Close 03E-A (encoder exists, not generalization) when:

- FPGA-only forward bit-exact vs host twin on a frozen vector
- SAME pairs d_H < DIFF pairs on the **train** bag, permutation-null beaten
- HOLD unused

Close 03E-B (generalized retrieval) only when:

- an **unseen** paraphrase of a bound episode hits the **same** `episode_id` at `HIT_MAX=8`
- unrelated HOLD strings miss
- 01R defaults untouched

Impossible-extremeness (PARA d=0 and UNREL d=32 on 8 pairs) is a **bug / overfit flag**, not PASS.

## Forbidden

- Train on LM-06 hidden.
- Open Q2 / HDML on the 02H stream.
- Silent-tune 01R or Q1 to help 03E.
- Claim 02M already did generalization.
- Open A1 if A0 only memorizes the train pair.

## Sibling

**A7-EAM-02M** — bind many exact cues to one episode. Ship that first.
