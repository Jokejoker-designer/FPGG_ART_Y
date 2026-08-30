# GO-POP-GATE-00 — PREREGISTER (grok-orch-00)

**Depends:** `GO-ISSUE-GATE-00` CLASS=`ISSUE_GATED` (CDC SHA `A036F216…`).  
**PROGRAM:** NO. This tree only. One unknown.

## Law

CONTROL now: `cmd_rd_en` has no `s_owner`.  
**One wire:** AND `s_owner`.

```text
assign cmd_rd_en = s_rst_n && (cmd_st == C_IDLE) && !cmd_pend && !cmd_empty &&
                   (!s_busy || ghost_busy_rel) && s_owner;
```

Do not edit cmd_wr_en again, tile, top, DMA, QSTAR.

## Unknown

After an **owned** enqueue, drop `m_owner` before the slave pops: does `s_go` stay 0 while `s_owner=0`? A later owned window must still pop (`GRANT_S_GO=1`).

| Print | Meaning |
|-------|---------|
| `DROP_S_GO` | 1 iff `s_go` while `s_owner=0` after drop |
| `GRANT_S_GO` | 1 iff `s_go` while `s_owner=1` |

CLASS **POP_GATED** iff `DROP_S_GO=0` and `GRANT_S_GO=1`.  
Print `GO_POP_GATE_00_UNIT_PASS`. Not existence. Not 664.
