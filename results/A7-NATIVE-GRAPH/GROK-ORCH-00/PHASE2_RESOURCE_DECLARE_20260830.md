# Phase 2 resource declaration — 2026-08-30

Silicon: `GLOBAL-TOPK-MINHEAP-BIT-01` SHA `439CC42D…` UART `pred=664`.
Numbers: **post-route** `report_utilization_route.rpt` unless labeled otherwise.
No subagents in this file.

## Device `xc7a100tcsg324-1`

| Resource | Used | Available | Remain | Util |
|----------|-----:|----------:|-------:|-----:|
| Slice LUT | 51361 | 63400 | **12039** | 81.01% |
| LUT as Logic | 48617 | 63400 | 14783 | 76.68% |
| LUT as Memory | 2744 | 19000 | 16256 | 14.44% |
| FF | 57912 | 126800 | **68888** | 45.67% |
| RAMB36 | 103 | 135 | **32** | 76.30% |
| DSP48E1 | 19 | 240 | **221** | 7.92% |
| Unique control sets | 2499 | 15850 | 13351 | 15.77% |
| **Slice** | **15850** | **15850** | **0** | **100%** |

WNS=+0.416 TNS=0 WHS=+0.018 @ 12.5 MHz / 80 ns.

**Constraint:** LUT remaining ≠ free fabric. Every slice is occupied. New logic must share occupied slices (combine LUT/FF) or Place 30-487 returns. BIT-00 (same RTL, no `control_set_merge`) packed 13446 vs 13012 available slices.

Hier post-route: `u_ab` 44172 LUT, `u_global` min-heap **2760** LUT / 1324 FF.
