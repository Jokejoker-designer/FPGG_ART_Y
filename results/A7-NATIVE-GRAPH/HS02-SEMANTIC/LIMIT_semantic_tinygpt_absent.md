# LIMIT — Semantic HS-02 held-out retrieval cannot close on this SoC

**Gate:** `hs02_semantic`  
**Vehicle:** `arty_a7_ng_lm06_ua_soc.bit` SHA `4451AFD9B07D8FF52791CCBF6338862FF36B721DF9FBB9BD19EC726BEA67F40E`  
**Board:** Digilent Arty A7-100T `210319BE776EA` COM12  

## Why LIMIT (not invent)

| Blocker | Evidence |
|---------|----------|
| TinyGPT / DSP answer core | **ABSENT** — post-route DSP=0 (`LM06-UA/lm06_ua_util.rpt`); UART `pe_alive=0` |
| UART query / answer protocol | **ABSENT** — stub accepts only `0xE0` enter + `0x53` status (`a7ng_exam_uart_stub.sv`) |
| Held-out wording → FPGA token | **NO PATH** — host cannot send query bytes; FPGA returns no answer bytes |
| HS-22 LM on response path | **OPEN** — sticky `lm_path=1` ≠ TinyGPT decode |

## What this gate does claim

- Honest **PASS_NARROW / LIMIT** for the scientific unknown: *must we LIMIT because TinyGPT ABSENT?* → **YES**.
- CONTROL UART framing + `lm_path=1` reconfirmed (`91B9`) under MODE-only TX.
- **HLB CLEAN** — no host cue/winner/grad/answer; no invented TinyGPT responses.

## What this gate does NOT claim

- Full HS-02 teacher=0 / external_LLM=0 / learn=0 / freeze=1 as **live semantic** board exam
- Held-out wording retrieval on silicon
- `NATIVE_V1_MINI_AI_BOARD_PASS` / BOARD_PASS
- Closing §14 Teacher-off OPEN rows to PASS
