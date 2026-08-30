# GO-TWOPASS-EMB-00 — PREREGISTER (grok-orch-00)

**PROGRAM:** NO. One file: `rtl/lm/tiny_gpt803k_core.sv`.  
**CONTROL SHA:** grok `C47F219D…` (`ST_EMB` interleaved TOK/POS).  
**CANDIDATE:** sealed inventory `355182A7…` (`ST_EMB_POS` then `ST_EMB_TOK`).

May install that exact SHA (read-only source: close664 product file). Do not invent a third schedule.

PASS:

```text
RG_SWITCHES<=2
POS_SETS=1024 TOK_SETS=1024  (ntok=8, D=128)
first pass POS miss, not TOK-without-miss
GO_TWOPASS_EMB_00_UNIT_PASS
```

Not UART 664. Not extra BRAM. Not tile/DMA edit.
