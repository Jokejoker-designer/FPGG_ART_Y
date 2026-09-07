# CLOSEOUT — U6T-TYPECLASS-HEAP-TIMING-00

```text
GATE                 = U6T-TYPECLASS-HEAP-TIMING-00
RESULT               = FAIL
EVIDENCE_CLASS       = POST_ROUTE_OOC
FIRST_DIVERGENCE     = QSE_LEXICON_COMBO (after heap CE path closed)
CONTROL_SYNTH_WNS    = -4.103 ns (unplaced)
PRE_PATCH_ROUTE_WNS  = -5.783 ns  TNS=-4471  fail_ep=930
POST_PATCH_ROUTE_WNS = -3.349 ns  TNS=-89    fail_ep=50
POST_PATCH_WHS       = +0.155 ns
CLK                  = 10.000 ns (100 MHz, production)
RTL_EDIT             = YES (HEAPIFY compare/swap split only)
BEATS_LAW            = UNCHANGED
U6_XSIM              = PASS (U6_TYPECLASS_UNIFIED_RETRIEVAL_PASS)
BIT                  = NO
PROGRAM              = NO
GATE14_PASS          = NO
```

## What closed

Streaming minheap TAKE/HEAPIFY no longer owns WNS. `hf_idx` tournament
CE path is gone. Swap uses registered `hf_idx`/`hf_nxt` only.

## What remains (next one unknown)

Post-route WNS is `u_qse/wbuf → entity_id_o` (23 logic levels, lexicon
scan `QSE_N_LEX` in one cycle). Do **not** mix QSE pipeline into this
heap lake.

## NEXT

`U6Q-QSE-LEXICON-TIMING-00` — pipeline lexicon match, law
`qse-v1-lexicon-hdc-00` outputs unchanged. Not U8R. Not PROGRAM.
