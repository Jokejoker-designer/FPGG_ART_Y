# A7-EAM-02Q — Query Geometry

**Status:** Q1 SILICON. Geometry on TinyGPT803k last-token: **EAM02A_NOGO**. Not LM-07. Not LM-06 glue.  
**Law:** `eam02q-qenc-v1` (encoder version is frozen per rung; do not silent-tune).  
**Depends on:** A7-EAM-01R router geometry (64-bit Hamming + HIT_MAX + MARGIN_MIN).  
**Does not depend on:** live LM-06 bitstream. Do **not** glue `arty_a7_lm06c3.bit` into this lane until a rung PASSes host geometry.

## Why this lane exists

00G / 01R only tested:

```
stored binary key  vs  stored binary key + artificial bit flips
```

That is **routing + Hamming reject**, not **semantic similarity**.

There is no natural reason that the 64-bit keys of

- “FPGA nào đang dùng?”
- “Board hiện tại dùng chip gì?”

are close in Hamming space if those keys are host-arbitrary.

02Q asks a different question:

> Can an LM-06 hidden/context vector be mapped to a 64-bit code so that
> paraphrase / same-intent pairs land inside `HIT_MAX=8`, while
> unrelated pairs stay near the 00G unrelated cloud (`d≈32…39`, FP=0 at `T≤8`)?

**The papers do not prove our 64-bit encoder will work. This is an experiment.**

## What 01R already owns

01R is the **router**. 02Q is the **query encoder**. They meet only at a 64-bit key.

```
LM-06 hidden / context   ← 02Q input (later)
        ↓
  binary query encoder   ← this lane (Q0 → Q1 → Q2)
        ↓
     64-bit key
        ↓
  A7-EAM-01R MIH router  ← already built; index nominates only
        ↓
  d1 ≤ HIT_MAX ∧ margin ≥ MARGIN_MIN
        ↓
     memory value
```

Gluing LM-06 before Q0/Q1 show separation would mix two unproven things.

## Literature (what each paper actually gives)

| Paper | Gives | Does **not** give |
|-------|--------|-------------------|
| Norouzi, Fleet, Salakhutdinov — *Hamming Distance Metric Learning*, NIPS 2012 ([hash `59b90e1…`](https://proceedings.neurips.cc/paper/2012/hash/59b90e1005a220e2ebc542eb9d950b1e-Abstract.html)) | A **learned** map from high-d data → binary codes that tries to keep semantic neighbors close in Hamming; triplet ranking + a piecewise-smooth bound. CIFAR-10 / MNIST retrieval. | A proof that **our** LM-06 INT16 hidden → 64-bit code will separate Vietnamese paraphrases. Not a Q0/Q1 construction. |
| Norouzi, Punjani, Fleet — *Fast Exact Search in Hamming Space with Multi-Index Hashing*, arXiv:1307.2982 | Exact Hamming kNN via substring tables. **This is 01R**, not the encoder. | Any semantic encoder. |
| Khandelwal et al. — *Generalization through Memorization: Nearest Neighbor Language Models* (kNN-LM) | Continuous LM embeddings + datastore kNN can help rare/factual next-token. | 64-bit Hamming, FPGA, or our `HIT_MAX=8`. |
| Wu et al. — *Memorizing Transformers* | Internal LM representations can feed an external kNN memory at test time. | That a 64-bit sign-code of a 128-d TinyGPT hidden is enough. |

Q1 (fixed ±1 hyperplanes) is **SimHash / random projection** (Charikar 2002), not HDML. HDML is the warrant for **opening Q2 only if Q1 fails**.

## Source representation (when we later read LM-06)

Frozen LM-06: `d_model=128`, context 128, INT16 activations, vocab 1024.  
Default query vector for 02Q: **last-token hidden** `h ∈ Z^{128}` (INT16).  
Pooled / mean-over-context is a named variant (`pool-mean`), not the default.  
Do not invent a second hidden width.

## Encoder ladder

Do **not** jump to learned projection.

### Q0 — selected / sign bits

```
h[127:0]  →  pick 64 dimensions (even indices, frozen)  →  sign  →  64 bits
```

Zero maps to 0. Cost: wiring. No adder tree.

**Pass (host):** paraphrase mean `d_H` clearly below unrelated mean, and unrelated FP=0 at `T≤8` on a **pre-registered** pair list.

### Q1 — fixed random hyperplane (recommended first FPGA rung)

\[
b_i = \mathrm{sign}\Bigl(\sum_j s_{ij}\, h_j\Bigr),\quad s_{ij}\in\{-1,+1\}
\]

- `i = 0..63`, `j = 0..127`
- One **frozen** ±1 matrix, seed documented (`Q1_SEED`). Add/sub only. **0 DSP.**
- `sign(0) = 0`.
- Version: `eam02q-q1-rh-v1`. Changing seed **changes the law**. New filename, no silent overwrite.

This is the image the user posted. It is **not** HDML; it is LSH.

### Q2 — learned binary projection

Open **only if** Q1 fails separation (paraphrase cloud overlaps unrelated at `T≤8`, or margin collapses).

Rules:

1. Train **off-FPGA**, freeze weights + `law_id`, then FPGA runs the frozen map.
2. **No silent-tune** on the confirmation set. Confirmation pairs are registered **before** Q2 training, same spirit as `A7-LM-06-CONFIRMATION.md`.
3. Prefer ±1 / power-of-two coefficients so Arty stays adder-tree. A dense INT8 GEMM is a new resource argument, not a sneak-in.
4. HDML is the citation, not the claim of success.

## Geometry gates (host, before any LM-06 glue)

Pre-register three bags (Vietnamese + English, same intent):

| Bag | Role |
|-----|------|
| `PARA` | paraphrase / same-fact pairs (the FPGA/chip example lives here) |
| `UNREL` | unrelated pairs (different fact, different topic) |
| `HOLD` | confirmation, **not** used to pick seed / threshold / Q2 weights |

Report, per encoder version:

- mean / p50 / p90 `d_H` on PARA and on UNREL
- TP at `T∈{0,1,2,4,8}` on PARA (pair treated as query vs stored)
- FP at same `T` on UNREL
- collision / margin if a third code is in the store

**Q0/Q1 may stay host-only.** FPGA Q1 is authorized only after Q0 or Q1 host PASSes UNREL FP=0 @ `T≤8` and PARA TP is not identically 0.

Failing Q1 does **not** authorize stretching `HIT_MAX` to bury the overlap. That would re-open 00G’s false-accept question.

## Forbidden

- Glue LM-06 / start LM-07 because 02Q exists.
- Treat 00G bit-flip TP as semantic evidence.
- Tune `Q1_SEED`, selected dimensions, or Q2 weights on `HOLD`.
- Claim HDML / kNN-LM / Memorizing Transformers proved our 64-bit code.
- Full-scan 4096, MIG, overwrite `arty_a7_lm*.bit` or 01R/00B bits.
- Let the host send a precomputed Hamming winner to the FPGA.

## Q1 deliverables (this rung)

FPGA runs Q1. Host does **not** send a 64-bit key for MAP_H/PROBE_H.

| Piece | Path |
|-------|------|
| Frozen ±1 ROM | `rtl/eam/eam02q_q1_signs.svh` (`tools/gen_q1_rom.py`, seed `0x0EA10201`) |
| Encoder | `rtl/eam/eam02q_q1.sv` — 128 add/sub cycles, `use_dsp=no`, `sign(0)=0` |
| UART | `eam02q_uart.sv` — `0x09` LOADH (16×16 B), `0x0C` ENC → kind `0x84` key LE, `0x0A`/`0x0B` MAP_H/PROBE_H |
| PING | `Q1R` |
| xsim | `A7EAM02Q_XSIM_PASS` — 16/16 host twin + encode-then-01R |
| Bit | `build/out/arty_a7_eam02q.bit` (never an LM name) |

Raw `0x02`/`0x03` (host key) still exists for 01R debug only. Semantic bags remain **text-only** until LM-06 last-token dumps exist.

## Geometry result (2026-08-19)

See `results/A7-EAM-02Q/lm06_geometry.json`.

Q1 PARA mean `d_H=26.25`, UNREL `23.75`, TP@`T=8` = 0. HOLD unused. Native last-token same-k vs diff-k also overlap (~25).

**Do not open EAM-02A.** Do not enlarge DDR. Do not retune 01R. Next is Q2 / representation.

