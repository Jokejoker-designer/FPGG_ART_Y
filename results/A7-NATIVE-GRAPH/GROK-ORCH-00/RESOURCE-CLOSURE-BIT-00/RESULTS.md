# RESOURCE-CLOSURE-BIT-00 — results

**PROGRAM=NO.** Do not program. Do not overwrite `B0F42C11` / `439CC42D`.

```text
BIT_OK sha256=DD4842DCA24B1DA6A845906870A7893FD3260FFA54F905E1C35BBD675EB3D615
WNS=+1.174 TNS=0 RAMB36=103 DSP=19
```

| | Existence `B0F42C11` | This bit `DD4842DC` | Δ |
|--|--:|--:|--:|
| LUT | 50668 | 50665 | −3 |
| FF | 57412 | 57404 | −8 |
| Slice | 15847 / 15850 | **15839 / 15850** | **−8** |
| Free slices | 3 | **11** | +8 |
| WNS | +1.004 | +1.174 | +0.170 |

Prereg target: ≥1000 free slices (used ≤14850).

```text
RESOURCE_CLOSURE_HYPOTHESIS = FALSIFIED
saved_slices=8  free=11  need>=1000
```

UART_SLIM debug-strip does not unlock Phase-2 learner packing. Next (Codex order): control-set consolidation / compact mailbox — **not** FIFO BRAM→LUTRAM. Board token not requested.
