# LIMIT — LM-06 weights ABSENT on SoC teacher-off vehicle

**Gate:** `teacher_off_exam`  
**SoC SHA:** `D65F3524BE1BD53D6B461CD8CD872DDCF8DE04EC4B7B0C8FB4CA4F959559A4DF`  
**Authority:** `INTEGRATE/GATE_integrate_fit_soc.md` + this UART run  

## What silicon proved

- UART stub alive after programming SoC (not proxy).
- Status framing `0x91` + `exam_mode=1` after host mode byte `0xE0`.
- `mig_calib=1` observed.
- `lm_path=0` on both probes — consistent with **no LM-06 weight fabric** on this bit.

## What is blocked (honest LIMIT)

Meaningful retrieval / HS-22 “LM in FPGA output path” cannot be claimed:

1. Integrate SoC deliberately omits LM-06 weight BRAM fabric (device BRAM budget).
2. Stub protocol has **no** query-token → answer-token path.
3. Host must **not** invent LM-06 answers to fill the gap (H_RIVAL — refused).

## Non-claims

- Not Native V1 BOARD_PASS  
- Not semantic generalization / held-out wording proof  
- Not EVAL weight-write counter proof beyond stub framing  

This LIMIT is **evidence**, not a failure of honesty. Full HS-02 retrieval requires a later vehicle with weights (or an explicitly non-LM claim scope).
