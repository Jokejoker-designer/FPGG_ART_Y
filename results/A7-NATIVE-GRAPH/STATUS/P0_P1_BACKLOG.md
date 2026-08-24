# P0/P1/P2 backlog (synced to feedback + BRAM WM + RESET plan)

Authority: `feedback.md`, `BRAM_WORKING_MEMORY_SPEC.md`, `BRAM_RESET_RETRAIN_PLAN.md`, blueprint 04/14/15.
Goal: `NATIVE_V1_MINI_AI_BOARD_PASS` (human stamp).

## BRAM tight ≠ wipe project

When tiles are exhausted: phase-share / DDR spill / smaller WM — **never** erase frozen LM-06, 01R/02M/A0.3, or NG-* archives. Fast path = epoch/generation invalidation (`AUTHORITY_BRAM_RESET_RETRAIN.md`).

## Active order

| Pri | Gate | Status | Owner | Hard stop |
|-----|------|--------|-------|-----------|
| P0 | ng02 Top-K | DONE_ENG | topk-frontier | 100k global Top-8 |
| P0 | ng02r_flow | DONE_ENG | topk-frontier | 100k lossless |
| P1 | ng06_wide_dispatch | OPEN | scientific | util >=80%; no more PE |
| P1 | ng06_epoch + ng04_stale | BLOCKED | scientific | DROP_STALE |
| P1 | termgen / perfmon | BLOCKED | scorer/scientific | no 1.6G overclaim |
| P2 | mem_schema / ddr_feed / frontier_shootout | BLOCKED | memory/topk | measured |
| P3 | bram_wm_00 | BLOCKED | memory-arch | WM-00 no LM |
| P3 | reset_00 | BLOCKED | memory-arch | A7-NATIVE-RESET-00; never wipe LM-06 |
| P3 | integrate_fit | BLOCKED | vivado-gate | after WM/reset architecture |
