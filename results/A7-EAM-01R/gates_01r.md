# A7-EAM-01R OOC gates (evidence, not estimate)

**Top:** `eam01r_core` OOC, xc7a100tcsg324-1, 100 MHz  
**Script:** `vivado/tcl/build_a7eam01r.tcl`  
**Result:** `A7_EAM01R_GATES_PASS`  
**JSON:** `results/A7-EAM-01R/gates_01r.json`

| Metric | Budget | Actual |
|--------|--------|--------|
| BRAM36-eq | < 60 | **56** (52 RAMB36 + 8 RAMB18) |
| Slice LUT | < 10k | **1252** (1.97%) |
| FF | — | 1322 |
| DSP | 0 | **0** |
| LUTRAM | no explode | 0 |
| WNS / TNS | ≥0 / 0 | **+0.633 / 0.000** |

OOC hold `WHS≈−0.002` is the usual missing `HD.CLK_SRC` artifact, not an on-chip 100 MHz failure. No bitstream. No LM / 00B overwrite.

## RAM shapes (post-route `report_ram_utilization`)

| Block | Inferred | Tiles |
|-------|----------|-------|
| Record `u_rec` | **4096×243** (not 256, not 00B’s 171) | 27× RAMB36 4K×9 |
| Index ×8 | 8192×13 each | **3× RAMB36 8K×4 + 1× RAMB18 8K×1 per bank** |
| Seen-tag | 4096×8 | 1× RAMB36 |

Index packing is the tax: 13-bit SDP did **not** collapse to one 8K×18 RAMB36 per bank. That is why 8 banks cost ~28 BRAM36-eq instead of 8.

Record width 243 = vec kept (core `out_vector` is a port) plus 13 unused flag/tag bits DCE’d. Do not size DDR from 00B’s 171 or from this 243.

## vs nominal

User envelope ~51.5 RAMB36 was bit-math. Vivado used 56. Still inside `< 60`. LUT is far under 10k.
