# E2R-WDMA-CMDCDC-TB-SBUSY1 — probe table (one `m_go`, `s_busy` held 1)

Source: `probe_table.csv`. Clocks: m=80 ns, s=10 ns. `s_busy=1` for the whole window.

Columns: `m_go` vs `s_busy`, `cmd_wr_en`, `cmd_full`, `cmd_empty`, `cmd_rd_en`, `cmd_pend`, `s_go_r`, `s_go`.

## Key events

| t (ns) | clk | event | m_go | s_busy | cmd_wr_en | cmd_full | cmd_empty | cmd_rd_en | cmd_pend | s_go_r | s_go |
|--------|-----|-------|------|--------|-----------|----------|-----------|-----------|----------|--------|------|
| 5955000 | post_recovery | XPM ready | 0 | 1 | 0 | 0 | 1 | 0 | 0 | 0 | 0 |
| 5960000 | m | `m_go` assert | 1 | 1 | 0 | 0 | 1 | 0 | 0 | 0 | 0 |
| 6040000 | m | write sampled | 1 | 1 | 1 | 0 | 1 | 0 | 0 | 0 | 0 |
| 6120000 | m | `m_go` low | 0 | 1 | 0 | 0 | 1 | 0 | 0 | 0 | 0 |
| 6175000 | s | empty clears | 0 | 1 | 0 | 0 | 0 | 0 | 0 | 0 | 0 |
| 6195000 | s | CONTROL `s_go` slot | 0 | 1 | 0 | 0 | 0 | 0 | 0 | 0 | 0 |
| 6615000 | s | window last | 0 | 1 | 0 | 0 | 0 | 0 | 0 | 0 | 0 |

CONTROL TB-00 (`s_busy=0`) at the same times: `cmd_rd_en=1` at 6175000, `s_go=1` at 6195000 (8 `s_clk` after `m_go`).

This run: `cmd_rd_en` never 1; `s_go` never 1; `cmd_empty` stays 0 after 6175000 (unread beat sits in FIFO). Window=50 `s_clk`.

`FIRST_MISSING_MARKER=NONE` (write accepted; empty cleared; no `rd_en`/`s_go` fire).
