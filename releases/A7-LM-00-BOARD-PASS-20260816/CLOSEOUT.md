# A7-LM-00 BOARD PASS — 2026-08-16

Bit-exact Arty port of Basys LM-05. Same `law_id=lm05-signsgd-v1`. No DDR. No scale-up.

**Claim:** `ARTY_A7_LM05_BITEXACT_PORT_BOARD_VALIDATED`

Not an LLM. Not A7-LM-01. Not the 1.5M family claim.

## Silicon

| | |
|--|--|
| Board | Digilent Arty A7-100T `210319BE776EA` |
| UART | COM12 115200 |
| Bit | `arty_a7_lm00.bit` `449A330B…34783` (unchanged from first program) |
| WNS / TNS | +72.324 / 0 |

## Ladder (retry = 0)

| Stage | Result |
|-------|--------|
| T0 parser (no board) | 4 passed |
| T2 same-case `[2]` ×1000 | **1000/1000** complete, crc=0 |
| T3 alternate 0/1 ×500 | **1000/1000** |
| T4 golden 1000 | **1000/1000** |
| T5 one session AND | logits 1000 · grads 128 · gen 20 · CE 512→304 · AFTER 0 · 9/9 banks |

First 950/1000 was host dumpz (`read(n)` + stale `0x74` after snap), not RTL. Same bitstream SHA.

## Next

A7-LM-01 MIG/DDR only after this archive is treated as frozen.
