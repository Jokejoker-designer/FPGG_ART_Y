# GO-REQUEST-PENDING-00 — PREREGISTER (grok-orch-00)

**PROGRAM:** NO. This tree only. One file: `rtl/board/a7ng_wdma_cdc.sv`.  
**CONTROL:** live-write `cmd_wr_en = m_rst_n && m_go && m_owner && !cmd_full` (ISSUE_GATED).  
Keep `cmd_rd_en && s_owner` (POP_GATED).

## Law (m_clk)

```text
m_go && !hold_valid → latch {m_wr,m_addr,m_bytes}, hold_valid=1
hold_valid && m_owner && !cmd_full → cmd_wr_en=1 once, then hold_valid=0
m_go while hold && !accept → overflow sticky, no overwrite
same-cycle accept && m_go → accept old, latch new, hold stays 1
```

## Marker (Case A delayed grant)

```text
CLASS=REQUEST_HELD
CMD_WR_COUNT=1
S_GO_COUNT=1
PAYLOAD_MATCH=1
UNOWNED_S_GO=0
UNOWNED_FALSE_AR=0
GO_REQUEST_PENDING_00_UNIT_PASS
```

Cases B (full), C (never grant), D (duplicate) required. Not existence. Not 664.
