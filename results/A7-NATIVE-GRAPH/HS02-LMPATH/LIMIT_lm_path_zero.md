# LIMIT — hs02_lm_path

## Board-observed

- Programmed vehicle: `arty_a7_ng_lm06_ua_soc.bit` SHA `D2C6CF4B…B9A92C` (MATCH).
- UART COM12 framing: status `0x91`, `exam_mode=1` after `0xE0`, `mig_calib=1`.
- **`lm_path=0`** on every probe through **t+210s** (flags `0x99`).

## Not claimed

- HS-02 semantic retrieval / held-out wording answers.
- HS-22 full LM participation (TinyGPT / DSP core **ABSENT** on this SoC — DSP=0 post-route).
- `BOARD_PASS` / `NATIVE_V1_MINI_AI_BOARD_PASS`.

## CONTROL retained

- Prior TEACHER_OFF stub on `D65F3524…` with `lm_path=0` remains CONTROL for framing-only silicon.
- This gate does **not** invent a host `lm_path=1` flag.
