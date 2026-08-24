# LIMIT — TinyGPT / full HS-22 still OPEN (HLB re-probe)

HLB VERIFY/REPROBE closed **board-visible `lm_path≠0`** only (UART bit5 via FPGA sticky; host MODE-only).

- TinyGPT core / DSP path: **ABSENT** (post-route DSP=0)
- `pe_alive=0` on UART flags
- Not semantic retrieval / not HS-22 answer-path claim
- Not `NATIVE_V1_MINI_AI_BOARD_PASS`

Programmed repair SHA: `4451AFD9B07D8FF52791CCBF6338862FF36B721DF9FBB9BD19EC726BEA67F40E`  
Independent HLB RX: `91B9` (`lm_path=1`, `exam_mode=1`)
