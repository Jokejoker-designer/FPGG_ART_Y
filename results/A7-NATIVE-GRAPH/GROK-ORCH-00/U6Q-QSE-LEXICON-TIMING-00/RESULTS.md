# RESULTS — U6Q

| Stage | WNS ns | TNS ns | fail EP |
|---|---:|---:|---:|
| U6 synth-only (historical) | -4.103 | -3562 | 948 |
| OOC route no RTL | -5.783 | -4471 | 930 |
| HEAPIFY 2-phase | -3.349 | -89 | 50 |
| QSE 30+30 (prior OOC) | -2.140 | (open) | 12 |
| HEAPIFY load/compare + QSE 30+30 | **+0.163** | **0** | **0** |

Hold WHS = +0.132 ns. DSP = 0. LUT 4395 (6.93%). FF 1181 (0.93%).

Worst MET setup: heap `hf_a_reg[s] → hf_do_swap_reg` (compare after load).

XSim (after tok_ready handshake on QSE busy):

- U3Q: `U3Q_R3_XSIM_PASS`
- U6: `U6_TYPECLASS_UNIFIED_RETRIEVAL_PASS`

Not SoC. Not BOARD. HD.CLK_SRC unset (OOC skew estimate).
