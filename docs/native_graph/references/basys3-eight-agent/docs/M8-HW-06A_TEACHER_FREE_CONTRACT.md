# M8-HW-06A — teacher-free single-turn interaction

**Status:** BOARD PASS 2026-08-16 (`results/M8-HW-06A/run_002`).  
**Bitstream:** reuse `basys3_eight_agent_m8hw04.bit` (`DEEFE548…`). No rebuild.  
Do not overwrite frozen 01–04 bits. Do not start M8-HW-06B until this file is BOARD PASS.

05 proved two phrases can share a learned basin **while the teacher is still
legal in TRAIN**. 06A is the first **after-train** gate: the same weights
must answer once, with the teacher cut.

## TRAIN (teacher legal)

```text
External teacher
      ↓
phrase examples   ("xin chào", "hello") → basin encode("chào bạn")
      ↓
FPGA learns readout W
```

Same host encoder as M8-HW-05. No HELLO id in `rtl/`.

## AFTER (hard switch — host latch, one way)

```text
Teacher            OFF
External LLM       0 calls
Learn              OFF
Freeze             ON
Weight writes      0
```

Allowed UART after the latch: `A5 63` probe and `A5 5F 03` dump only.  
Forbidden: `A5 62` sample (carries teacher), `A5 5F 07` TRAIN, any HTTP/SDK.

## First test

```text
"xin chào"
    ↓
host encoder
    ↓
FPGA  (learn=0, teacher=0)
    ↓
R1 = 0x88
    ↓
local decoder  (codebook from TRAIN targets, keyed by FPGA out only)
    ↓
"chào bạn"
```

Decoder is **not** `prompt → response`. Unknown FPGA out → empty string.

## Provenance (must appear on the host UI / transcript)

```text
INPUT SOURCE       User
ENCODER            Local
INFERENCE          FPGA
TEACHER            DISCONNECTED
EXTERNAL LLM       0
WEIGHT WRITES      0
LEARN              OFF
FREEZE             ON
```

## Silicon AND-gates

- FPGA out for `xin chào` == R1
- Local decode == `chào bạn`
- `hello` (same basin) also decodes to `chào bạn`
- `tạm biệt` does **not**
- DUMP SHA before AFTER infer == DUMP SHA after
- After latch: train cmds = 0, sample frames = 0, LLM calls = 0
- `rtl/` still has no demo strings

If and only if every gate holds:

```text
TEACHER_FREE_AFTER_TRAIN_SIMPLE_INTERACTION_BOARD_VALIDATED
```

**Not claimed:** conversation, multi-turn, name memory (those are 06B).
