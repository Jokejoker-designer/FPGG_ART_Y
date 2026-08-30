# GO-READY-GATE-00 — PREREGISTER (grok-orch-00)

**Depends:** POP_GATED CDC `C02F0D54…`. **PROGRAM:** NO. This tree only.

## One unknown (P0-B)

CONTROL top @ `140345e`: DMA `.go(dma_go)`, `.m_axi_arready(arready)`, `.m_axi_rvalid(rvalid)` raw.

**One ownership law** in `rtl/board/arty_a7_ng_native_v1_ab_soc_top.sv` (three ANDs, same unknown):

```text
.go(dma_go && wdma_owner_ui)
.m_axi_arready(arready && wdma_owner_ui)
.m_axi_rvalid(rvalid && wdma_owner_ui)
```

Do not edit CDC, tile dest FSM, QSTAR, MIG.

## Vehicle

Do **not** elaborate full SoC/MIG. TB + CDC + `ddr_tile_dma` + bag-local slice with the three ANDs (same as a composition unit). Stub `arready` starts 0 so DMA parks in AR while owned; drop owner; raise stub `arready`; `rvalid` held 0.

CLASS **READY_GATED** iff `OWNED_AR=1` and `DROP_AR_ADVANCE=0`.  
Print `GO_READY_GATE_00_UNIT_PASS`. Not existence. Not 664.
