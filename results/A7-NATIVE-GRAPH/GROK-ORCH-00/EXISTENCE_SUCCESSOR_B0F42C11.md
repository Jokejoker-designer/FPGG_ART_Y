# Existence successor freeze — B0F42C11

Codex prompt `PROMPT_GROK_SUPPORT_20260831.md` + independent audit
`CODEX-INDEPENDENT-DUAL-BRANCH-AUDIT-20260831/REPORT.md`.

```text
PASS_NARROW_BOARD_EXISTENCE
BOARD_PASS=not_claimed
TEACHER_OFF=not_evidenced
CONTEXTUAL_LEARNING=not_evidenced
MINI_AI_SECTION_14=open
```

This bit is **existence telemetry-handshake repair**, not Phase-2 learning.
Do not reopen pred=664 unless contradictory UART appears.

| Item | SHA256 / value |
|------|----------------|
| Bit | `B0F42C119A3E00D9B2F2A17957A9613F1D90F5A6DDFDAEA1A5106A0AC5DDBA37` |
| Prior control | `439CC42D…` GLOBAL-TOPK-MINHEAP-BIT-01 — keep, do not overwrite |
| UART arm | 2026-08-31T02:05:06+07:00 DTR/RTS false, before program |
| JTAG | `210319BE776EA` startup HIGH |
| UART | TOPK=PACK=3B392B291B190B09 POISON=0 pred=664 |
| Slice | 15847/15850 — **3 free; no learner on this bit** |
| CDC candidate | 2× `clk_pll_i -> core_clk` (not waived for ship) |

`HEAP_CMP_LANES` unused; do not claim heap parallelism.

Next gate: `RESOURCE-CLOSURE-00` (prereg). **No program from support prompt.**
