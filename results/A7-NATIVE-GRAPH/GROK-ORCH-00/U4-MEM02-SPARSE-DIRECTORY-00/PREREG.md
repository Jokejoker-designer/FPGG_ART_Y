# PREREG — U4-MEM02-SPARSE-DIRECTORY-00

```text
GATE        = U4-MEM02-SPARSE-DIRECTORY-00
SCALE       = 256  (ladder first rung; not 800k yet)
PROFILE     = P2_deep
CAND_CAP    = 256
RTL_EDIT    = YES directory unit only
SOC_WIRING  = NO
BIT         = NO
PROGRAM     = NO

PRIMARY_UNKNOWN =
  Can a 2-table BRAM directory emit bounded candidate IDs from qfe keys
  including high-address sentinel 255, with overflow/dedup explicit,
  without scanning all N?

NOT_THIS_GATE = 800k DDR postings, SoC, C9, bitstream
```
