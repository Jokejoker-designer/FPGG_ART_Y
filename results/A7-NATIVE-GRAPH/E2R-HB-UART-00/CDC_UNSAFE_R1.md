# R1 unsafe CDC (pre-fix)

**Source clock:** `clk_pll_i` (MIG ui_clk)  
**Dest clock:** `sys_clk_pin` (CLK100MHZ / UART domain)  
**Summary row:** Critical · Asynch Clock Groups · endpoints=4 · safe=2 · **unsafe=1** · unknown=1 · No ASYNC_REG=3

**Instance (design delta vs T2 PASS):** `u_hb_sync` in `arty_a7_ng_native_v1_ab_soc_top`

Root cause: combinational `core_live_ui = calib && wmem_done && boot_done` (ui domain) fed into `sync_bits` together with a multi-bit / multi-signal bundle. Vivado classified one `clk_pll_i → sys_clk_pin` endpoint as **Unsafe** (summary-only `report_cdc.rpt` does not print pin names; severity + endpoint delta vs T2 pins the new HB sync).

**Fix (r2):** remove `u_hb_sync`; add single-bit `u_wmem_sync` (`ASYNC_REG` meta); compute `core_live_100 = calib_ui_100 && wmem_100 && boot_ui_100` entirely in `sys_clk_pin` domain.

**r2 CDC:** `clk_pll_i → sys_clk_pin` Warning · endpoints=3 · safe=3 · unsafe=0
