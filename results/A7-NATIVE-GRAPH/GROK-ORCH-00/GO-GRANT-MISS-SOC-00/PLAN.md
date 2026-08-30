# 371-path standby bit — PROGRAM=NO until Cursor returns COM12

371 completed forward (`pred=371`) because dest **held go** until `dma_busy` (grant eventually rose).
Wait-busy / 1-pulse left dest waiting `dma_busy` with **GRANT=0** forever (`PHASE=01`).

This bit keeps dest **1-cycle go + wait busy** (XSim3 1152/1152) and raises grant when
`(wdma_owner || tile_miss) && r_path_idle` so the pulse is owned.

CDC: do not relatch hold on accept+m_go (371 3× GO).

| File | SHA256 |
|------|--------|
| top | `F8792219…8FA74C43` |
| CDC | `5AF2FBDA…06539D` |
| tile | `DFF70FA7…C50DA2` (wait-busy, unchanged) |

PROGRAM=NO. Bit path: `arty_a7_ng_native_v1_grok_orch_grant_miss_00.bit`
