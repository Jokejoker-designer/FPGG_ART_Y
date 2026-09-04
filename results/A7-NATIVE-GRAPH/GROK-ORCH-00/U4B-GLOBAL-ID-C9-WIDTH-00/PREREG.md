# PREREG — U4B-GLOBAL-ID-C9-WIDTH-00

```text
GATE        = U4B-GLOBAL-ID-C9-WIDTH-00
WAIT_FOR    = U2R impl complete (C9 glue / bind are in U2R fileset)
BIT         = NO
PROGRAM     = NO
ORACLE      = HOLD
PHYS        = 4

PRIMARY_UNKNOWN =
  Can >=20-bit node IDs survive router -> scorer -> Local/Global TopK ->
  C9 observe -> LM ctx pack, including sentinel 799999 = 0xC34FF,
  without low-8 alias?

HARD =
  ID_W>=20 on cand_id, scorer cand_id, topk_id, C9 path, LM ctx
  sentinel 0xC34FF distinguishable from 0xFF / 0x4FF
  forbid pack[8*i +: 8] = id[7:0] as the live ID path
  legacy c9_topk_o 64-bit may remain diagnostic only

NOT_THIS_GATE = bitstream, SoC query-time host cue, U5
```
