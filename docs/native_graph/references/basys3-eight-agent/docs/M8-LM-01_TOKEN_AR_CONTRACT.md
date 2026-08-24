# M8-LM-01 — token autoregression on the existing 8×8

**New bitstream name only:** `build/out/basys3_eight_agent_m8lm01.bit`  
Do **not** overwrite `m8hw06b` / `m8hw04` / `m8hw03` / `m8hw02` / cyclic.

## Goal

After TRAIN, FPGA feeds its own predicted token back until EOS.

Host-only labels (never in `rtl/`):

```
0 XIN  1 CHAO  2 BAN  3 TOI  4 LA  5 FPGA  6 EOS  7 UNK
```

Wire format is 3-bit ids + one-hot spikes.

## Frames

| Kind | Dir | Body |
|------|-----|------|
| `A5 67` | host→FPGA | src, dst — one TRAIN pair |
| `A5 65` | host→FPGA | start, max_len, eos — start generate |
| `A5 5F 09` | host→FPGA | reset weights + token FSM |
| `A5 66` | FPGA→host | step, pred, out, writes, last |

## TRAIN

Host sends dest[src] pairs. Example (ids only):

```
0→1, 1→2, 2→6, 3→4, 4→5, 5→6, 6→6, 7→7
```

Teacher legal. Repeat 32 epochs.

## AFTER generate

Teacher OFF, Learn OFF, Freeze ON, `writes==0`, no host/LLM inside the loop.

| Start | Expected preds |
|-------|----------------|
| 0 | 1, 2, 6 |
| 3 | 4, 5, 6 |

100/100 both. RESET then start 0 ≠ 1,2,6. Retrain dest[0]=3 then start 0 → 3,4,5,6.

## Claim (only if board gates pass)

```
AUTOREGRESSIVE_TOKEN_SEQUENCE_FPGA_BOARD_VALIDATED
```

Not a Transformer. Not open-domain.
