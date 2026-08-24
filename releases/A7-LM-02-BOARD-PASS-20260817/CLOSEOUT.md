# A7-LM-02 BOARD PASS — 2026-08-17

128-lane tiled tensor engine on official Digilent AXI MIG. No Transformer. No scale-up. No A7-LM-03.

**Claim:** `ARTY_A7_TENSOR_ENGINE_BOARD_VALIDATED`

Not an LLM. Not online training. Not the 1.5M family claim.

## Silicon

| | |
|--|--|
| Board | Digilent Arty A7-100T JTAG `210319BE776EA` / UART `210319BE776EB` |
| UART | COM12 115200 |
| Bit | `arty_a7_lm02.bit` `7CEBA854BDE500DDC87C4742315C45562CB5902C6F66377BCE499DA43BD95CC4` |
| WNS / TNS | +0.446 / 0 |
| DSP / BRAM / LUT / FF | 135 / 18 / 8760 / 5147 |
| Frozen LM-00 | `449A330BD2E23E1D9714ECF94142A0555914D6C76EDE6310EF347A3596534783` unchanged |
| Frozen LM-01 | `96065A174F22B6F79B6A04B79EBA4DDEF094B2BFAF36F5C93F0C376C679507B8` unchanged |
| MIG | official `mig.prj` AXI, not hand-edited |

## Gates (conjunctive, all met)

| Gate | Result |
|------|--------|
| 10 000 signed GEMV/GEMM vs `python/ref/fixed_gemm.py` | exact xor32=`3910408033` add32=`1957547457` macs=`50398207` |
| spot 0,1,7,17,19 (INT8 corner / sat / nonmultiple) | exact |
| DMA PING/PONG hazards | 0 |
| compute-only U_MAC (GEMM 8×16×256) | **1.00** (256 MAC-enable cycles) |
| DDR-streamed GEMV | **0.944 GMAC/s** = **80.7%** of 1.17 GB/s roofline (2892 cycles) |
| WNS | +0.446 |

Mixed 10k batch U_MAC is 0.436 because many cases use N≪128. The compute-roof gate is the sequence-reuse GEMM (`0x27`), not the mixed batch.

## Honest limits

- Host compares fold only. It does not compute the board GEMM/GEMV.
- BRAM is sync-read: schedulers prefetch `k+1` on RUN so MAC sees row `k`.
- DDR roof cycle counter starts after the 32 KB warmup write; it covers streamed 32 KB weight fill + GEMV + capture/fold.
- 135 DSP = 128 MAC lanes plus fill/xorshift helpers.
- AXI wrapper around unmodified Digilent preset.

## Next

A7-LM-03 (first scaled model) only after this archive is treated as frozen and the user opens 03.
