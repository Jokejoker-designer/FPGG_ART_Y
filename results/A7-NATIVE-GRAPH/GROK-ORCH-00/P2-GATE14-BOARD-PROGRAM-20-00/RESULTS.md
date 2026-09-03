# P2-GATE14-BOARD-PROGRAM-20-00 — STOP, not programmed

Human: “Ok cho program”. Token written for this exact gate + SHA  
`6975AB757FE592DBD0EAB68FBDC7463559A3712CAA9A8BD1E429C9A6BDF8B39A`  
`authorize_program=yes`.

## Bit (EVIDENCE)

Live rehash MATCH, 3826011 bytes. Parent D5B not used.

## Transport (EVIDENCE) — FAIL before arm/program

COM12 **absent**. JTAG `210319BE776EA` **absent** (`n_targets=0`).  
List-only connect; never `PROGRAM.FILE`. COM never opened.

## What did not happen

- UART not armed (cannot without COM12).
- Bit not programmed.
- 20-fact sequence not run.
- No recapture (nothing captured).
- No old bit.
- No auto-reprogram.

## Claims

Teacher-Off / Gate14 close / BOARD_PASS: **not claimed**.

## STOP

`WAIT_HUMAN_RECONNECT`. Codex: token is valid; seat is not. Reconnect board, then a new named token if program is still wanted.
