# A7-EAM-03E-A — Episodic Encoder (rungs A0 then A1)

**Status (locked A0):**

```
XSIM_PASS
SILICON_FUNCTIONAL_PASS_WITH_NOTES
TIMING_FAIL            WNS −1.891 ns  TNS −990.6 ns
SEED_ROBUSTNESS_FAIL   seed 0x22222222  M = 229−1487 = −1258
A1 CLOSED
```

**Next:** **A0.1-T** (timing only) → L0 telemetry on the closed bit → **A0.2-L** contrastive (`A7-EAM-03E-A02.md`). Do not open A1. Do not rename a law change as A0.1.  
**Law:** `eam03e-a0-signsgd-v1`  
**Parent:** `A7-EAM-03E.md`  
**Depends on:** 02M frozen as a *later* consumer. **A0 does not instantiate 01R, 02M, or LM-06.**  
**Tokenizer:** UTF-8 bytes, unchanged.

## Split

| Rung | Question | Memory |
|------|----------|--------|
| **A0** | Can FPGA learn SAME closer / DIFF farther? | **None** |
| **A1** | Unseen cue of a **trained** association retrieves the bound 02M episode? | Frozen 01R + 02M |

If A0 fails, **HOLD**. Do not glue 01R to hide it. That would be metric memorization wearing a CAM.

## Architecture (both rungs)

```
UTF-8 byte stream
      ↓
256 × 32 learned byte embedding     INT8
      ↓
32-D Elman state  h_t = sat16(E[b_t] + Wh h_{t-1})
      ↓
last state = sentence vector
      ↓
64-bit cue = sign(P h)   P is ±1 from seed, frozen after RESEED
      ↓
(A1 only) 01R + 02M
```

Wx = I. Learned: `E` 8192 + `Wh` 1024 INT8. Projection add/sub only, **0 DSP**.  
Not a second Transformer. Not LM-06 weights.

## Two modes

**TRAIN** (`learn=1`, `freeze=0`)

```
seq A, seq B, label SAME|DIFF
        ↓
FPGA encoder forward both
        ↓
distance + error   (FPGA)
        ↓
FPGA SignSGD on E and Wh
```

**EVAL** (`learn=0`, `teacher=0`, `freeze=1`)

```
sequence → 64-bit cue
```

Host may send: UTF-8 bytes and SAME/DIFF.  
Host must **not** send: 64-bit hash, projection result, gradient, weight update, memory address, 01R winner.

## Update law (`eam03e-a0-signsgd-v1`)

1. Forward both sequences to `hA`, `hB` ∈ INT16³² and cues `cA`, `cB`.
2. `d1 = Σ (|hA_i − hB_i| >> 5)` (u16, avoids 16-bit sat), `dH = popcount(cA xor cB)`.
3. SAME: `g = hA − hB`. DIFF: if `d1 < M` then `g = hB − hA` else `g = 0`. `M=4096` on this **quantized** d1.
4. Broadcast SignSGD: every byte of A (resp. B) has `E[b][i] -= sat8 sign(gA_i)` (resp. gB).
5. Last-step `Wh[i][j] -= sign(g_i * h_{T-1,j})` (skip 0).
6. `P` not trained (SimHash of the 32-D state).
7. `freeze=1` skips 4–5.

This is **local**, not host BPTT. If it cannot move train-pair distances, A0 FAIL — do not add 01R.

## A0 gate (pre-registered)

Random init after bitstream (host seed, **not** weights).

```
RESEED
PAIR learn=0                 → d1_same0, d1_diff0, dH_*
TRAIN mappings (several steps)
TEACHER_OFF / freeze
PAIR learn=0                 → d1_same1, d1_diff1
```

PASS only if **all**:

1. `d1_same1 < d1_same0`
2. `d1_diff1 > d1_same1`
3. RESEED (same or new seed): trained inequality **disappears** (`d1_same` not held below the trained value by a frozen leftover)
4. Retrain **swapped** associations (the old DIFF pair is now SAME): new geometry (`d1` of the new SAME < `d1` of the new DIFF)
5. At least **3 seeds** or **2 mappings**; not a single lucky pair
6. Host trace has no hash / grad / weight / address / winner

Record `dH` every time. A0 does **not** require `dH_same1 < 8` (that is A1/01R). If `d1` moves and `dH` does not, write `PASS_WITH_NOTES` and **do not open A1**.

## A1 (not this bitstream)

Only after A0 PASS without notes on dead Hamming:

```
bind cue(A) → episode X          (02M, exact)
train encoder: A ~ A'            (A' not bound)
teacher OFF
probe A' → encoder cue → 01R → episode X
```

Narrow claim if that hits: **learned unseen-cue retrieval**.  
Not open-domain semantic paraphrase.

**Stop rule:** train SAME close, unseen SAME random → HOLD. Do not use EAM to cover it.

## UART (A0)

Envelope `A5 cmd n payload xor`, reply 20 bytes `5A`.

| CMD | Payload | Action |
|-----|---------|--------|
| `0x01` | — | PING ident `3A` `A0` |
| `0x04` | — | RESEED default |
| `0x13` | — | freeze (EVAL) |
| `0x20` | `{learn, freeze}` | MODE |
| `0x21` | seed u32 LE | RESEED |
| `0x22` | `slot \|\| n \|\| bytes` | BUF A=0/B=1, `n≤46` |
| `0x23` | `label` 1=SAME 0=DIFF | PAIR (fwd both, maybe update) |
| `0x24` | `slot` | ENC → 64-bit cue |

PAIR reply `0xA3`: `dH`, `d1` u16, flags `{updated, freeze, learn}`.  
ENC reply `0xA4`: cue LE 8 bytes.

Raw 01R MAP/PROBE not present on this UART.

## Forbidden

- Glue LM-06, Q1, 01R, 02M in the A0 bit
- Host-side encoder in an evidence run
- Call A0 “semantic paraphrase”
- Open A1 because train pairs overfit
- Change tokenizer
- Silent-tune 01R `HIT_MAX`

## Deliverables (A0)

- this contract
- `rtl/eam/a7eam03e_pkg.sv`, `eam03e_core.sv`, `eam03e_uart.sv`
- `rtl/board/arty_a7_eam03e_top.sv`
- `tests/xsim/tb_a7eam03e.sv`
- `tools/a7eam03e_a0_silicon.py`
- `results/A7-EAM-03E/`
