# GLOBAL-TOPK-MINHEAP-00 — same-run OOC (12.5 MHz / 80 ns)

Part `xc7a100tcsg324-1`. Flatten `rebuilt`. Sequential pair in one Vivado session. **PROGRAM=NO.**

| | Frozen bitonic `a7ng_topk_wavefront_global` | Min-heap `a7ng_topk_wavefront_minheap` |
|--|--:|--:|
| Slice LUT | **8901** | **2958** |
| LUT as Memory | 0 | 0 |
| FF | 1202 | 1674 |
| BRAM | 0 | 0 |
| DSP | 0 | 0 |
| WNS | **+0.636 ns** | **+49.205 ns** |
| TNS | 0 | 0 |
| Clock | 80 ns | 80 ns |
| Route | complete | complete |

```text
LUT_saved = 8901 - 2958 = 5943
LUT_reduction_pct = 5943 / 8901 * 100 = 66.8%
```

Authoritative reduction is **this same-run OOC pair**, not mixed with full-chip hierarchy.

```text
fullchip_projection_vs_u_global_7702 = ENGINEERING_INFERENCE
G0 post-synth u_global = 7701 LUT (hier, poison-off SoC)
If that block scaled by OOC ratio 2958/8901:
  inferred_u_global ≈ 2560 LUT
  inferred_fullchip ≈ 63423 - 7701 + 2560 = 58282 LUT
  vs G4 gate 58500: plausible, NOT a measured full-chip number
```

Do not treat 8901 OOC as equal to 7701 hier.

Cycles/wave (HEAP_CMP_LANES=1, engineering from FSM): ≤8 inserts × few heapify + 8×8 bubble ≈ **< 256**. Bitonic merge is 1–2 cycles. LM ~18.2e6 cycles still dominates.

Reports: `bitonic_util_route.rpt` `bitonic_timing_route.rpt` `minheap_util_route.rpt` `minheap_timing_route.rpt`
