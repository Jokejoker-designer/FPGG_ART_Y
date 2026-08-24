# M8-LM-00 — freeze LEGACY and open the LM track

**Status:** software/evidence gate (no new RTL).  
**Profile:** `BUILD_PROFILE=LEGACY` frozen. `BUILD_PROFILE=LM` starts at M8-LM-02.

## Goal

Turn M8-HW-01..06B into an immutable baseline. Do not change those
bitstreams, claims, or UART kinds already boarded.

## Acceptance

- `scripts/verify_frozen_hw_sha.py` PASS
- `scripts/verify_no_semantic_hardcode.py` PASS
- Existing pytest for HW-02..06B still PASS
- New files only: `results/immutable/`, `python/lm/`, `milestones/M8-LM-*`
- No token/phrase names added to `rtl/`

## Not claimed

No Transformer. No new board claim. Next is M8-LM-01.
