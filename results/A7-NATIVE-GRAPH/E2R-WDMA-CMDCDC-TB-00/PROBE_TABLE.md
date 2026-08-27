# E2R-WDMA-CMDCDC-TB-00 — probe table (one `m_go`)

Source: `probe_table.csv`. Clocks: m=80 ns, s=10 ns. `s_busy=0`.

Columns: `m_go` vs `cmd_wr_en`, `cmd_full`, `cmd_empty`, `cmd_rd_en`, `cmd_pend`, `s_go_r`, `s_go`.

## Key events

| t (ns) | clk | event | m_go | cmd_wr_en | cmd_full | cmd_empty | cmd_rd_en | cmd_pend | s_go_r | s_go |
|--------|-----|-------|------|-----------|----------|-----------|-----------|----------|--------|------|
| 5955000 | post_recovery | XPM ready | 0 | 0 | 0 | 1 | 0 | 0 | 0 | 0 |
| 5960000 | m | `m_go` assert | 1 | 0 | 0 | 1 | 0 | 0 | 0 | 0 |
| 6040000 | m | write sampled | 1 | 1 | 0 | 1 | 0 | 0 | 0 | 0 |
| 6120000 | m | `m_go` low | 0 | 0 | 0 | 1 | 0 | 0 | 0 | 0 |
| 6175000 | s | empty clears | 0 | 0 | 0 | 0 | 1 | 0 | 0 | 0 |
| 6185000 | s | pend | 0 | 0 | 0 | 1 | 0 | 1 | 0 | 0 |
| 6195000 | s | `s_go` pulse | 0 | 0 | 0 | 1 | 0 | 0 | 1 | 1 |
| 6205000 | s | pulse done | 0 | 0 | 0 | 1 | 0 | 0 | 0 | 0 |

`s_go` at **8** `s_clk` after `m_go` (window=50). Payload `s_wr=1 s_addr=0001000 s_bytes=64`.

`FIRST_MISSING_MARKER=NONE` (this TB only).
