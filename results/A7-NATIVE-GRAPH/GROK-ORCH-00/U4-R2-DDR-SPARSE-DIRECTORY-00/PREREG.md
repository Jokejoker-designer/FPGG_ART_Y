# PREREG — U4-R2-DDR-SPARSE-DIRECTORY-00

```text
GATE        = U4-R2-DDR-SPARSE-DIRECTORY-00
RTL         = rtl/native_graph/memory/a7ng_sparse_dir_axi.sv  (NEW)
SOC         = NO
BIT         = NO
PROGRAM     = NO
PHYS        = 4 (untouched)

PRIMARY_UNKNOWN =
  Can a parameterized AXI DDR directory+posting walker emit candidates
  with valid/ready, honor overflow/epoch, dedup and truncate, without
  on-chip [N_TABLES][N_BUCKETS][HEAD][CAND] geometry?

DIR_ENTRY 16B / 128b beat =
  [27:0]  base     posting page byte address
  [47:32] count    posting count
  [48]    overflow
  [79:64] epoch
  else reserved

POSTINGS =
  from NG_DDR_INDEX_BASE map; 4 x 32-bit IDs per 128b beat; ID_W>=20

HARD XSim =
  protocol stall (cand_ready low holds AR/R)
  overflow flag observed, overflowed ids still listed if present in page
  dedup across tables
  truncation at CAND_CAP
  empty count=0
  epoch mismatch skips
  no hard-coded [2][16][8][32] ID array in RTL

NOT_THIS_GATE = SoC integration, U5 800k fill, bitstream
```
