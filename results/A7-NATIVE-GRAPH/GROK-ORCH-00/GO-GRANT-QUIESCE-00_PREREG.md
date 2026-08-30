# GO-GRANT-QUIESCE-00 — PREREGISTER (grok-orch-00)

**PROGRAM:** NO. One file: `rtl/board/arty_a7_ng_native_v1_ab_soc_top.sv`.  
Keep ready-gate ANDs. Do not edit CDC.

## CONTROL (this tree now)

```text
else if (!wdma_owner) wdma_owner_grant <= 0;  // drop immediately
```

## Law

```text
wdma_owner && r_path_idle → grant=1
!wdma_owner && cmd_empty && DMA IDLE && AR/R outstanding==0 → grant=0
else hold grant while drain
```

UI facts: `cmd_empty` from CDC, DMA IDLE = `wdma_dbg_st==0`, AR/R count on owned AR handshake / RLAST. Sync to core_clk.

CLASS **QUIESCE_HOLD** iff grant stays 1 while DMA in AR after tile dest drop, and grant falls only after idle+empty+quiet.

Print `GO_GRANT_QUIESCE_00_UNIT_PASS`. Slice TB, no MIG. Not 664.
