# GO-ISSUE-GATE-00 — PREREGISTER (grok-orch-00)

**Gate:** `GO-ISSUE-GATE-00`  
**Tree:** `D:\Jetking_sem4\SEM_4\arty-a7-online-lm-grok-orch-00` only  
**Sealed:** 2026-08-29  
**PROGRAM:** NO. **C_FIX on Cursor tree:** NONE.  
**Not** OPEN-CTRL. **Not** `graph_late_materialize_00`. **Not** 664/744.

## Law (one unknown)

CONTROL this checkout: `cmd_wr_en = m_rst_n && m_go && !cmd_full` (`a7ng_wdma_cdc.sv` @ `140345e`).  
**One wire:** AND `m_owner`.

```text
assign cmd_wr_en = m_rst_n && m_go && m_owner && !cmd_full;
```

Do **not** edit `cmd_rd_en`, tile, top, DMA, QSTAR, frozen 01R/02M/LM-06.

## Scientific frame

| Field | Value |
|-------|-------|
| OBSERVATION | Unowned `m_go` can enqueue (P0-A) on this CDC |
| UNKNOWN | After AND `m_owner`, does unowned `m_go` print `CMD_WR_EN=0` while owned prints `CMD_WR_EN=1`? |
| H_CANDIDATE | CLASS=`ISSUE_GATED` |
| H_RIVAL | unowned still `CMD_WR_EN=1` |
| FALSIFIER | second wire in same hunk; xvlog Cursor files; SoC instantiate; program |
| UNIT | one unowned pulse, then one owned pulse |
| CONTROL | this file before the wire |

## Required prints

```text
CMD_WR_UNOWNED=
CMD_WR_OWNED=
CLASS=
GO_ISSUE_GATE_00_UNIT_PASS
```

CLASS **ISSUE_GATED** iff `CMD_WR_UNOWNED=0` and `CMD_WR_OWNED=1`.  
`UNIT_PASS` = SHA recorded + TB finished. **Not** existence. **Not** `pred=664`.
