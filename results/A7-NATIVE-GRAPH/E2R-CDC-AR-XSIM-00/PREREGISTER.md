# E2R-CDC-AR-XSIM-00 (F1f) — PREREGISTER

**Date:** 2026-08-26  
**Worktree:** `D:/Jetking_sem4/SEM_4/arty-a7-online-lm-board`  
**Agent:** `a7-ng-xsim-verify`  
**Authority:** `results/A7-NATIVE-GRAPH/STATUS/E2R_F1F_DISPATCH.md` (main repo)  
**Board:** NOT used (observation XSim only; COM12 not touched)

## Scientific frame

| Field | Value |
|-------|-------|
| OBSERVATION | Silicon F1a–F1e: `CDC_M_ARF=YES`, `CDC_HOLD=NO` forever |
| UNKNOWN | Does a lone AR write on `m_clk` ever deassert `ar_empty` / assert `s_axi_arvalid` on `s_clk` in this RTL? |
| H_CANDIDATE | XPM AR FIFO / reset / FWFT wiring loses the beat across domains (sim FAIL) |
| H_RIVAL | Silicon-only (clocking/reset sequencing) — sim PASS |
| FALSIFIER | Sim shows `!ar_empty` and `s_axi_arvalid` within 50 `s_clk` cycles after m AR handshake |
| UNIT | One AR beat write→read |
| CONTROL | Current `rtl/board/a7ng_axi_read_cdc.sv` (F1e direct FWFT + F1c dual rst) — **no RTL edit** |
| METRICS | cycles_to_s_arvalid after m accept; `ar_empty`, `s_axi_arvalid`, `ar_wr_en`, `ar_rd_en`, m handshake |

## ONE UNKNOWN

With isolated DUT clocks/resets and `s_axi_arready=1`, does one m-side AR handshake produce `s_axi_arvalid` within 50 s_clk cycles?

## DUT freeze (observation)

| Item | Value |
|------|-------|
| File | `rtl/board/a7ng_axi_read_cdc.sv` |
| SHA256 | `272026EC609FA51E20DF7293A28AC083DD10EAB65B151A247C65251C9392679F` |
| AR FIFO | `READ_MODE("fwft")`, `FIFO_READ_LATENCY(0)`, `.rst(!(m_rst_n && s_rst_n))` |
| Present | `s_axi_arvalid = s_rst_n && !ar_empty` (F1e direct) |

## Protocol

1. Instantiate **only** `a7ng_axi_read_cdc` (+ Vivado `xpm` lib).
2. `m_clk` period **80 ns** (12.5 MHz); `s_clk` period **10 ns** (100 MHz ui stand-in).
3. Assert both resets ≥20 m_clk; release both; wait for FIFO ready.
4. Drive one AR on m (`valid` until `ready`); hold `s_axi_arready=1`.
5. Log `ar_empty`, `s_axi_arvalid`, `ar_wr_en`, `ar_rd_en`, m handshake.
6. **TB PASS** iff `s_axi_arvalid` asserts within 50 `s_clk` after m AR accept; else **TB FAIL**.

## Interpretation (post-run)

| TB result | Favored hypothesis | Next |
|-----------|--------------------|------|
| FAIL | H_CANDIDATE (RTL loses beat) | Fix CDC RTL (not this gate) |
| PASS | H_RIVAL (silicon-only) | F1g reset/clock sequencing on board |

## Do NOT

- Edit product RTL
- Program board / touch COM12
- Claim existence or `BOARD_PASS`
