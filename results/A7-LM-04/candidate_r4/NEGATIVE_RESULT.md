# A7-LM-04 R4 — sealed negative development result

**Sealed:** 2026-08-18  
**Status:** `SEALED_NEGATIVE_DEVELOPMENT_RESULT`  
**Confirmation set:** not generated  
**Oracle:** not run  
**Board:** not programmed  

This directory is closed. Do not add epochs 16/32, LR 1/5, new rotations, or new random schedules. Those are not the lever.

## Finding (what R4 answered)

There is **no evidence** that schedule-only search under `lm05-signsgd-v1` makes the 100,352-param model learn a robust 8-way last-token retrieval task.

This is **not** a proof that sign-SGD is impossible. It is a negative development result on the schedules that were actually tried.

Across 10 init seeds and three development sets, the best worst-seed accuracy was **6.25%**. Typical hits were 1–2 target classes. Dominant prediction was often ≥50%.

## What CE alone conceals

A typical `ce_sum` path:

```text
1024 → 896
drop = 12.5%
```

`1024 − 896 = 128 = 8 × 16`. On 64 examples / 8 balanced classes that is one class solved and a near-constant predictor. Scalar `mean_last_loss` 16→14 can coexist with:

```text
unique_pred_count = 1
max_pred_class_fraction = 1.0
entropy = 0
```

That is why R4 dropped fake-PPL and required accuracy + diversity/collapse next to `mean_last_loss`.

## Immutable (do not overwrite)

| Artifact | Role |
|----------|------|
| `dev_sweep.json` | 1-token `board_corpus` schedule grid, 10 seeds, 3 sets |
| `dev_select.json` / `dev_select2.json` | last-token TRAIN/DEV schedule grids |
| `train.json` / `dev.json` | last-token TRAIN/DEV only |
| `CANNOT_FREEZE.md` / `NOT_FROZEN.md` | earlier stop records |
| `docs/contracts/A7-LM-04-R4-CONFIRMATION.md` | procedure; hashes stay PENDING |

R3 was not used to choose a recipe. HELDOUT-R4 does not exist.

## What this does **not** grant

- Not `ARTY_A7_100K_DDR_ONLINE_LM_BOARD_VALIDATED`
- Not LM-04 BOARD_PASS / FROZEN
- Not permission to treat WNS +0.301 as a quality close
