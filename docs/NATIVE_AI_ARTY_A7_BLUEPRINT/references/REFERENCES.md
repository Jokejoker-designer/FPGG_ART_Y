# References and Design Inspirations

This blueprint distinguishes project evidence from external architectural inspiration.

## Project evidence

- Routed utilization reports for A0.3, 01R, 02M and LM-06.
- A0.3 board/twin 5,000/5,000 exact learning-transaction trace.
- Existing 03E learning-law research and corrections.
- Existing DDR bandwidth experiments in the A7-LM line.

## External inspiration

### Qwen quantization

Official Qwen documentation provides Int4/Int8 GPTQ quantized model workflows and AWQ/GPTQ guidance. The lesson used here is staged quantization and sensitivity/calibration, not a claim that official Qwen is a native 2-bit model.

### BitNet b1.58

BitNet b1.58 uses ternary `{-1,0,+1}` weights. Microsoft's current inference work includes W2A8 kernels. The lesson used here is hardware-native low-bit representation, packed weight access and add/sub/skip computation.

Key paper:

- *The Era of 1-bit LLMs: All Large Language Models are in 1.58 Bits* (Ma et al., 2024).
- *BitNet b1.58 2B4T Technical Report* (2025).

### Associative memory / attention

Modern Hopfield/associative-memory literature motivates viewing retrieval as similarity + separation + projection and supports the conceptual link between associative retrieval and attention. This blueprint does not claim equivalence between its sparse graph attention and Transformer attention.

## Important limitation

External CPU/GPU kernels are design references only. FPGA RTL must be re-derived for the Artix-7 memory hierarchy, BRAM, LUT, DSP, clocking and DDR constraints.
