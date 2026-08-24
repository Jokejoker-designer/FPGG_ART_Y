# A7-LM-04 R4 — cannot freeze (2026-08-18)

`heldout_r3_used_for_selection`: **false**  
`HELDOUT-R4`: **not created**  
Board: **not programmed**  
`law_id`: `lm05-signsgd-v1` unchanged

Eight UART-mappable schedules were trained on `board_corpus` only (0x3A head + host 0x34 full, class order fwd/rev/rot/rot_rev, LR 2/3/4, extra full 2/4/8). Evaluated on R2 + DEV_A (seed 53, n=64) + DEV_B (seed 59, n=64). Ten development init seeds: 2,3,5,7,11,13,29,31,37,43.

Freeze bar (all sets, all seeds): median CE drop ≥30%, acc ≥25%, ≥7/8 classes, dominant pred ≤40%, no degrade.

**Result: `can_freeze=false`.** Best worst-seed accuracy is 6.25% (`h48_f4_rot`). Typical pattern remains 1–2 target classes and a dominant prediction ≥50%. Extra full passes and class rotation did not produce 8-way last-token retrieval from 1-token `[k]` training.

Do not create a confirmation set from this grid. That would only manufacture another R3-style oracle fail.

Evidence: `dev_sweep.json`, `dev_corpora.json`.
