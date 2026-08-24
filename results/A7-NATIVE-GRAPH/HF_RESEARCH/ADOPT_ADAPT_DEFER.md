# HF research — ADOPT / ADAPT / DEFER for A7-NATIVE-GRAPH + LM06-LowBit

**Date:** 2026-08-21  
**Agent:** a7-ng-hf-research (REPORT_ONLY)  
**Board:** Arty A7-100T — external models are **not** EVAL backends

## Queried models (Hugging Face Hub)

| Model | Link | Lesson | Tag |
|-------|------|--------|-----|
| microsoft/bitnet-b1.58-2B-4T | https://hf.co/microsoft/bitnet-b1.58-2B-4T | ternary `{-1,0,+1}` / packed W2-style datapath | **ADAPT** |
| microsoft/bitnet-b1.58-2B-4T-gguf | https://hf.co/microsoft/bitnet-b1.58-2B-4T-gguf | deployment packaging only | DEFER |
| Qwen/Qwen2.5-7B-Instruct-AWQ | https://hf.co/Qwen/Qwen2.5-7B-Instruct-AWQ | staged W4 calibration / sensitivity | **ADAPT** |
| Qwen/Qwen2.5-14B-Instruct-AWQ | https://hf.co/Qwen/Qwen2.5-14B-Instruct-AWQ | same W4 lesson at larger scale | DEFER (too big) |

## ADOPT (FPGA-native now)

None yet as drop-in RTL. Artix-7 BRAM/DDR hierarchy forces re-derivation.

## ADAPT (into LM06-LowBit / PE integer path)

1. **BitNet packing:** weight packed access + add/sub/skip instead of full multiply — candidate for NG scorer / LM06 W2 lane after BRAM ownership (LM06-Q0) settles shape-vs-fill.  
2. **AWQ staging:** calibrate sensitive layers first; do not blindly quantize activation BRAM (`u_a` = 66 tiles).

## DEFER

- Running any HF transformer as host teacher-off answer generator  
- GGUF / MLX runtimes on EVAL path  
- Claiming BitNet = Native AI V1

## Link to blueprint

`docs/NATIVE_AI_ARTY_A7_BLUEPRINT/09_LM06_LOWBIT_OPTIMIZATION.md`  
`docs/NATIVE_AI_ARTY_A7_BLUEPRINT/references/REFERENCES.md`
