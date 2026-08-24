# M8-HW-03R — randomized dense regression

**Status:** BOARD PASS 2026-08-14 — 32/32 and 128/128.  
**Same bitstream:** `basys3_eight_agent_m8hw03.bit` — no Vivado rebuild between seeds.  
**Not conversation.**

## Pattern rule

Each session draws `stimulus` and `teacher` as 8-bit mixed-polarity codes
(not `0x00`, not `0xFF`). Then one TRAIN, then FREEZE.

Pass per session:

```text
changed_cell_count == 64
AND FPGA_after == Python_after
AND freeze == after
AND before neutral after RESET
```

## Gates

1. 32 / 32 PASS  
2. Then 128 / 128 if 32/32 holds  

Store: seed, stim, teacher, before_sha, after_sha, freeze_sha, changed_count.
