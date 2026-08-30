# GO-H2NOPOISON-SOC-00

**PROGRAM=NO.** COM12 is Cursor's until this bag has BIT_OK and human returns the port.

Branch: `research/native-ai-v1-grok-h2-uart-00` in grok-orch-00 worktree.

## Why pred≠664 (measured)

Silicon EC286E9E: `PACK=FFFFFFFFFFFFFFFF` `pred=733`.
SoC had `.poison_i(1'b1)` + `poison_id=255` → bind packs FF×8, TinyGPT never sees A-FAST `[9,11,25,27,41,43,57,59]`.

H4 XSim `poison=0` → pack `3b392b291b190b09` → 664.

## This bit (one product change + UART fork)

- `.poison_i(1'b0)` so bind uses SOA `topk_id`
- UART `TOPK=` 16 hex = SOA ids at `topk_valid`
- UART `PACK=` 16 hex = bind pack at `ctx_we`
- UART `POISON=0`

Decode after program (later, named token only):

| UART | Meaning |
|------|---------|
| `POISON=0` `TOPK=3B392B291B190B09` `PACK=3B39…` `pred=664` | existence |
| same packs, pred≠664 | H3 flash / numerics |
| `TOPK=3B39…` `PACK=FF…` | poison mux still on |
| `TOPK=FF…` | SOA ids are 255, not A-FAST |

Do not reprogram EC286E9E.
