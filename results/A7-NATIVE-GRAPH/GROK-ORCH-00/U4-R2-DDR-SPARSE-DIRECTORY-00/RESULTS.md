# RESULTS — U4-R2-DDR-SPARSE-DIRECTORY-00

```text
RTL     = rtl/native_graph/memory/a7ng_sparse_dir_axi.sv
SOC     = NO
BIT     = NO
PROGRAM = NO
XSIM    = U4_R2_DDR_SPARSE_DIRECTORY_PASS

CASE_A  emit=4 dup=1 ovf=1 stall=6 sentinel=0xC34FF (20-bit)
CASE_B  emit=8 trunc=4  (CAND_CAP=8, 12 postings)
CASE_C  epoch mismatch skips table0; table1 id=88
CASE_D  empty emit=0

DIR_ENTRY = base[27:0] count[47:32] overflow[48] epoch[79:64]
POSTINGS  = AXI AR/R, 4 x 32b IDs / 128b beat, INDEX_BASE=NG_DDR_INDEX_BASE
GEOMETRY  = parameterized; no [2][16][8][32] on-chip heads
HANDSHAKE = cand_v/cand_ready; stall holds cand_id
```

Not MEM02 800k fill. Not SoC. U5 still closed.
