# A7-LM-04 R4 — confirmation not created (2026-08-18)

Procedure in `docs/contracts/A7-LM-04-R4-CONFIRMATION.md` is locked.  
R3 was **not** used to choose a recipe. CONFIRMATION was **not** generated.  
Oracle was **not** run. Board was **not** programmed.

## Why

DEV selection on a last-token TRAIN set (same rule as the intended confirmation) failed the collapse bar on every UART-legal schedule tried:

| Pass | Best median CE drop | Collapse on all DEV seeds |
|------|---------------------|---------------------------|
| select1 (fwd/rot/0x3A, 2–4 full epochs) | 12.5% | no |
| select2 (round-robin, 1-token mix) | 12.5% | no |

Typical pattern: `ce_sum` 1024→896 (exactly 12.5%, one class of eight × last_loss 16) and a constant predictor. More epochs made collapse worse.

Creating a confirmation set now would only produce another R3-style one-shot FAIL, or invite post-hoc recipe edits. That is forbidden.

## What is ready

- TRAIN n=64 seed 71 and DEV n=64 seed 73, last-token rule, disjoint R2/R3: `train.json`, `dev.json`
- Metrics without fake PPL: `tools/_r4_metrics.py`
- Silicon sequence and collapse gates written into the confirmation contract
- R3 bit already has CDC + tile_valid; first-try K=513 ladder exists and must not be used until a recipe freezes

## What is not allowed next

- Do not invent HELDOUT-R4 and call it frozen after looking at DEV collapse.
- Do not lower collapse gates after seeing these numbers and still call this revision R4.
- A later attempt that changes the **task**, the **gates**, or the **law** is **R5**, with a new confirmation set generated after the new recipe freeze.
