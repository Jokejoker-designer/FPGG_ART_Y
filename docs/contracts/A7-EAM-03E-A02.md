# A7-EAM-03E-A0.2-L — Contrastive law (after timing)

**Parent:** `A7-EAM-03E-A.md`  
**Depends on:** A0.1-T **timing closed** (WNS ≥ 0, TNS = 0) and golden d1 frozen.  
**A1:** still **CLOSED**. Do not glue 01R / 02M / LM-06.  
**Tokenizer:** UTF-8, unchanged.

A0 proved **plasticity** (can move pairwise geometry).  
A0 did **not** prove **discriminative** geometry. Seed `0x22222222`:

```
M_L1 = d(A,N) − d(A,P) = 229 − 1487 = −1258
```

That is **DIFF collapse**, not a metric footnote. A0.1-T must not “fix” it by changing the law.

A0.1-L as originally written (same law, many seeds) is **not** the law-change vehicle. After T closes, a new law is a **new version**: this file.

## Split of authority

| Path | Owns | Must not |
|------|------|----------|
| **TRAIN** | L1 distances + SignSGD (L0) or triplet hinge (L1+) | Cosine / divide / sqrt in the update |
| **EVAL telemetry** | `d1`, `dH`, `n1`, `max_abs`, `mean_abs`, `dot`, `M_cos` | Change weights |

Host still sends only UTF-8 bytes + SAME/DIFF (L0) or one **triplet** (A, P, N) per TRAIN transaction (L1+).  
Host must **not** send hashes, gradients, weights, addresses, winners, or precomputed cosine.

## Hypothesis test (cheap)

Log on every EVAL / PAIR:

```
d1_pos, d1_neg
n1(A), n1(P), n1(N)          Σ |h_i|
max_abs(h), mean_abs(h)
dot(A,P), dot(A,N)           INT32 MAC, 0 DSP target if serialized
M_L1  = d1_neg − d1_pos
M_cos = cos(A,P) − cos(A,N)  host-side from (dot, n2²) or FPGA Q15 approx
```

| Observation | Conclusion |
|-------------|------------|
| `M_L1 < 0` but `M_cos > 0` | metric/norm is lying; do not retune law first |
| `M_L1 < 0` **and** `M_cos < 0` | law cannot create margin (repulsion missing) |
| both norms collapse while distances collapse | later justify cheap power-of-two norm (L2) |

**Do not** put exact L2 normalize (`square / sum / sqrt / divide`) in RTL until L0/L1 logs show norm collapse.

## Ablation (provenance)

Cosine is **measured on every run**. TRAIN law changes only at L1+.

| Run | Law id | TRAIN | Notes |
|-----|--------|-------|--------|
| **L0** | `eam03e-a0-signsgd-v1` | current SAME pull / DIFF gated push | Baseline on **T-closed** datapath + EVAL telemetry |
| **L1** | `eam03e-a02-triplet-v1` | one combined triplet update | **Priority 1** |
| **L2** | `eam03e-a02-triplet-norm-v1` | L1 + cheap shift-norm | Only if L0/L1 logs show norm collapse |
| **L3** | angular/cosine surrogate | not opened | Only if L1+L2 still fail `M_cos` |

If L1 rescues seed `0x22222222`, the missing mechanism is **repulsion**. Do not add normalization.

## L1 law (`eam03e-a02-triplet-v1`)

One TRAIN transaction, **not** two independent PAIR updates (order would be a confound):

```
forward A, P, N
     ↓
d_pos = Σ |A_i − P_i|     (same >>5 d1 as A0)
d_neg = Σ |A_i − N_i|
     ↓
if d_pos + m < d_neg:
    no update
else:
    pull P toward A
    push N away from A
     ↓
one combined SignSGD on E and Wh
```

Hinge:

```
L = max(0, d(A,P) − d(A,N) + m)
```

`m` is a **fixed** integer (same scale as quantized `d1`; start `m = E3_MARG` or a registered smaller constant — freeze before the confirmation bag, do not silent-tune per seed).

SignSGD on L1: gradient is the sign of each coordinate difference.

```
gP_i = sign(P_i − A_i)     # pull P toward A  (subtract gP from P path)
gN_i = sign(A_i − N_i)     # push N away from A
gA_i = −gP_i − gN_i        # only if both terms active; skip 0
```

(Exact INT8 broadcast matches A0 style: every byte of that sequence sees `E[b][i] -= sat8 sign(g_i)`.)

**Forbidden in L1:**

- SAME PAIR then DIFF PAIR as two UART commands counting as one train step
- Host-side combined gradient
- Changing `m` after the confirmation set is frozen
- Cosine in the update
- Opening A1 because train-pair `dH` dropped

## EVAL cosine (telemetry only)

FPGA may compute `dot = Σ hA_i * hB_i` (serialized 16×16→32, `use_dsp = "no"` unless T already closed with spare slack).  
`n2sq = Σ h_i * h_i` per vector.  
Host (or a later Q15 core) forms:

```
cos(A,B) ≈ dot / sqrt(n2sq_A * n2sq_B)
M_cos    = cos(A,P) − cos(A,N)
```

A first silicon step may ship `dot` + `n2sq` and let the host finish `cos` **as telemetry**, not as TRAIN authority. Record that split in the ladder JSON.

`sign(P h)` is homogeneous in positive scale: a cheap positive shift-norm of `h` must **not** be required to change the binary cue. That is why norm control can stabilize TRAIN geometry without being a new representation.

## Gate (per seed)

A seed **PASS** only if **all**:

1. `d_pos_post < d_pos_pre`
2. `M_L1_post > 0`
3. `M_cos_post > 0`
4. DIFF does not collapse (`d_neg_post` not below `d_pos_post`)
5. RESEED erases geometry
6. swapped labels create **new** geometry
7. Host trace has no hash / grad / weight / address / winner

## Multi-seed confirmation

Worst-seed rule for this milestone (seed inversion **is** the bug):

```
worst-seed M_L1_post  ≥ 0
worst-seed M_cos_post ≥ 0
no seed inversion
```

A 90% average with one inverted seed is **FAIL**.

Confirmation bag may include Kidi-style paraphrases from `KIDI_TRAINING_LESSON_PLAN.md` **after** L1 is frozen. They must not retune `m`.

## UART (L1 sketch; not on the A0.1-T bit)

Keep A0 PING ident until L1 ships; then ident `3A` `A2`.  
New CMD (do not reuse 0x23 as a second PAIR pretending to be a triplet):

| CMD | Payload | Action |
|-----|---------|--------|
| `0x25` | slots A,P,N already BUF’d + `m` | TRIPLET TRAIN/EVAL |
| `0x26` | slot | EVAL telemetry block (`d1`,`dH`,`n1`,`max_abs`,`dot`,`n2sq`) |

PAIR `0x23` remains for L0 baseline only.

## Forbidden

- Change A0.1-T law, seed, dataset, or golden integers
- Declare A0 BOARD_PASS from telemetry
- Exact L2 normalize in L1
- Glue 01R/02M because L1 `dH` improved on the train pair
- Silent-tune `m` or `E3_MARG` per failing seed

## Deliverables

- this contract
- L0 telemetry (after T close): same law, extra EVAL fields
- L1 RTL + xsim + silicon ladder vs L0 on the **same** confirmation seeds
- `results/A7-EAM-03E/a02l/`
