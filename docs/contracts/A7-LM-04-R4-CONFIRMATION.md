# A7-LM-04-R4-CONFIRMATION

**Status:** `SEALED_NEGATIVE_DEVELOPMENT_RESULT` — no further schedule search. CONFIRMATION was never generated.  
**Date:** 2026-08-18  
**Parent:** `docs/contracts/A7-LM-04.md`  
**law_id:** `lm05-signsgd-v1` (unchanged)  
**Geometry:** 100,352 params (unchanged)  
**MIG:** official AXI, `mig.prj` SHA unchanged  

This document is the R4 close procedure. It does **not** grant the claim. R2 remains `VALIDATION_PASS_WITH_KNOWN_ERRATA`. R3 remains `FAILED_CONFIRMATION_ORACLE` and **must not** be used to choose the R4 recipe.

## Two close levels

| Level | Condition |
|-------|-----------|
| **LM-04 BOARD_PASS / FROZEN** | all conjunctive gates PASS and `WNS ≥ 0`, `TNS = 0` |
| **LM-05 AUTHORIZED** | LM-04 is BOARD_PASS **and** `WNS ≥ +0.20 ns`, `TNS = 0` |

Physical WNS on an ungranted candidate does not authorize LM-05.

## What may change

Allowed:

- Known CDC busy-falling-edge start
- Tile-valid / command_id / tile_index interlock already in R3 RTL
- Train / DEV / confirmation **evaluation** split
- Quality-metric definition (stop calling `exp(mean last_loss)` perplexity)

Forbidden:

- New optimizer, teacher, Morse/ATEC, low-rank, ternary
- Geometry or `law_id` change
- Hand-edit `mig.prj`
- Overwrite FAIL / R2 / R3 evidence
- Extra train steps, LR, or seed changes after this file is frozen
- Re-using HELDOUT-R3 to tune
- Scoring a second K=513 issue

## Underlying rule (all three sets)

```text
prefix length 2–4
distractors in 9..40
last token k ∈ 1..8, balanced
target = 32 + (k - 1)
```

V1 (target independent of prefix) is archived as `FAIL_HELDOUT_INVALID_TASK` only.

## Sets

| Set | Role | When generated |
|-----|------|----------------|
| `TRAIN` | FPGA/oracle updates (`0x32` + `0x34` full) | before recipe selection |
| `DEV` | choose the frozen schedule | before recipe freeze |
| `CONFIRMATION` | one-shot oracle then one-shot board | **after** recipe SHA freeze |

Prefixes of the three sets are pairwise disjoint, and disjoint from R2 and R3.

Confirmation: **n ≥ 64**, 8-way balanced. Init seeds are new (not 2/3/5, not 17/19/23).

## Evaluation semantics (frozen)

`last_loss` is a coarse integer (typically 0 or 16). It is **not** a natural-log NLL.

| Name | Definition |
|------|------------|
| `ce_sum` | sum of FPGA/oracle `last_loss` over the set |
| `mean_last_loss` | `ce_sum / n` — the quality proxy |
| `exact_match_acc` | FPGA argmax == target |
| `pred_entropy_bits` | Shannon entropy of the prediction histogram, base 2 |

Do **not** report `exp(mean_last_loss)` as perplexity.

## Quality gates (conjunctive, 3 frozen seeds)

```text
median relative ce_sum drop >= 5%
mean_last_loss down on all 3 seeds
no seed ce_sum degrade > 2%

AND collapse:
  max_pred_class_fraction <= 0.50
  unique_pred_count >= 4
  pred_entropy_bits > 1.5
  not constant-class
  n >= 64
```

## Recipe freeze rule

Design only on TRAIN + DEV. Then lock:

- `train_recipe_sha256`
- `train_corpus_sha256`
- `dev_set_sha256`
- `confirmation_set_sha256`
- `oracle_sha256`
- `validation_script_sha256`
- 3 confirmation seed IDs
- train step count, LR, sample order
- bitstream SHA (after impl, **before** program)
- source-tree SHA of RTL + scripts used for the run

After that lock: no extra steps, no LR change, no seed change, no re-run because the number looked bad.

If oracle FAIL: this revision is **R4 INVALID**. Do not retune on the confirmation set. A later attempt is **R5** with a new confirmation set.

## Silicon sequence (one program)

```text
PROGRAM ONCE
  identity / SHA
  spot upload + fold0
  one-full exact
  persist flush → DDR reload
  K257 once
  K511 once
  K513 FIRST TRY
  requant 8, 13, 0
  3-seed quality confirmation
  AFTER zero-write
```

`k513_first_try` is ternary: `NOT_RUN` | `PASS` | `FAIL`.

## Frozen hashes

Filled when the recipe is selected. Empty means **not frozen**.

```text
train_recipe_sha256:        PENDING
train_corpus_sha256:        PENDING
dev_set_sha256:             PENDING
confirmation_set_sha256:    PENDING
oracle_sha256:              PENDING
validation_script_sha256:   PENDING
source_tree_sha256:         PENDING
bitstream_sha256:           PENDING
init_seeds:                 PENDING
```

## Claim grant

Only after an immutable `results/A7-LM-04/candidate_r4/MANIFEST.json` records every gate true, first-try K=513 PASS, collapse PASS, confirmation unused for tuning, and the WNS rule for the requested level.
