# 09 — LM-06 Low-Bit Optimization Plan

## 1. Why this lane exists

LM-06 is the largest current logic/memory consumer:

```text
37,555 LUT
35,864 FF
132 BRAM
154 DSP
802,816 parameters
```

The goal is not marketing "2-bit AI". The goal is to free memory bandwidth/resources while preserving the frozen LM-06 functional role.

## 2. External lessons

### Qwen-style lesson

Official Qwen quantized releases commonly use Int4/Int8 GPTQ/AWQ-style approaches. Lesson: start with a safer precision rung and use calibration/sensitivity rather than assuming all weights tolerate 2-bit equally.

### BitNet lesson

BitNet b1.58 uses ternary weights `{-1,0,+1}` and W2A8 inference kernels. Lesson: native low-bit computation can replace many multiplications with add/sub/skip and reduce weight bandwidth.

## 3. Do not modify frozen LM-06 directly

Create candidates:

```text
LM06-Q0 baseline audit
LM06-Q1 W4A8
LM06-Q2 W2A8/ternary
LM06-Q3 mixed precision
```

Each gets its own artifacts and gates.

## 4. W4 first

Validate quality/resource trend before W2.

## 5. W2 candidate

Possible block:

```text
32 ternary weights = 64 packed bits
+ block scale metadata
```

Raw 2-bit storage for 802,816 weights:

```text
200,704 bytes
```

At approximately 2.25 effective bits/weight including simple block scale metadata:

```text
~225,792 bytes
```

versus 802,816 bytes at 8-bit weight storage.

This is roughly a 3.56x weight-image reduction, subject to actual metadata/layout.

## 6. FPGA-friendly scale

Prefer power-of-two block scales if quality allows:

```text
scale = 2^k
```

so scaling becomes shifts rather than multipliers.

## 7. Mixed precision

Do not force all state to 2 bit.

Candidate:

```text
linear weights: W2
activations: A8
accumulator: 16–32 bit
norm/sensitive state: higher precision
embedding/output projection: W4/W8 initially
```

## 8. Training warning

A ternary forward representation changes LM learning dynamics. Native W2 online LM training is a separate research claim.

For V1 it is acceptable to use:

```text
low-bit/frozen LM backbone
+
online learned graph/episodic memory
```

rather than destabilizing closure by forcing the LM itself to learn in ternary state.

## 9. Success gate

Quantization must improve at least one scarce resource while keeping:

```text
quality within preregistered bound
timing closed
no new host dependency
LM active in final FPGA response path
```

## 10. BRAM warning — audit done, warning upgraded

Because LM-06 persistent weights are already DDR-resident, BRAM reduction is **not guaranteed** by
weight quantization. The ownership audit has now been run, and its result sharpens this warning.

Measured (`POST_ROUTE`, `results/A7-NATIVE-GRAPH/MEM-00/LM06_BRAM_OWNERSHIP_SOURCE.md`):

| owner | tiles | role |
|-------|------:|------|
| `u_a` | 66 | activation scratch |
| `u_w` | 64 | weight staging / working tiles |
| `u_snap` | 2 | snapshot machinery |

The 132 tiles are LM-06 **working machinery**, not a persistent store of the 802,816 parameters.
`u_w` at 64 tiles × 36 Kbit = 2.36 Mbit can hold at most ~37% of the 6.42 Mbit 8-bit weight image,
so it is a staging buffer by construction.

Consequences for this lane:

- Weight precision touches at most the 64 `u_w` tiles, and only if `u_w` is sized by **logical tile
  shape**. If it is sized by **available BRAM**, low-bit weights stage 4× more per fetch and free
  **nothing** — the gain appears as DDR bandwidth and burst efficiency instead. Which case holds must
  be settled by reading LM-06 buffer sizing, not inferred from tile counts.
- Even in the most favourable case, W2 moves the four-block naive BRAM total from 243/135 to about
  195/135 — still over budget, because the dominant consumers become `u_a` (66) plus 01R (56) plus
  02M (52), none of which weight precision touches.
- Therefore quantization is **not** the load-bearing lever for integration. The load-bearing work is
  the working-set line: DDR delivery characterization → LM-06 working-set equivalence → BRAM ladder →
  phase ownership. See [`00_CURRENT_AUTHORITY.md`](00_CURRENT_AUTHORITY.md) §10 and §12.

Never describe that work as "moving 802,816 weights from BRAM to DDR". That migration already
happened by contract.
