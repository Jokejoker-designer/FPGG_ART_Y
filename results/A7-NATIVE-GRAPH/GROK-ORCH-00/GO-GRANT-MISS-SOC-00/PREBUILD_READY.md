# PREBUILD_READY — GO-GRANT-MISS-SOC-00

**YES** as of 2026-08-30 14:18. Policy `BIT_FIRST_COM12_SECOND`.  
**PROGRAM=NO.** Do not arm COM12 until `BRIDGE.json` names this exact gate.

| Item | Value |
|------|--------|
| Bit | `arty_a7_ng_native_v1_grok_orch_grant_miss_00.bit` |
| BIT SHA256 | `885DC99C559B92129C29207FF0870F9E7AF1688A2446D65FB6A761FB231A59D4` (re-hash match) |
| WNS / TNS | **+0.287 / 0** (file Design Timing Summary; `-return_string` NA is regex only) |
| core / ui WNS | +9.598 / +2.226 |
| RAMB36 | 103 |
| CDC | clk_pll_i→core_clk uns=2 **FINDING_ONLY** (`u_wdma_rel_sync`); clkgen 3 |
| DRC at bitgen | 0 errors (ja NSTD/UCIO waived, no LiteScope) |
| XSim3 | GO=1152 DONE=1152 GO_WHILE_BUSY=0 |
| Source SHA | match SOURCE_SHA.txt (CDC `5AF2FBDA…` top `F8792219…` tile `DFF70FA7…` core `355182A7…` dma `20BAE36E…`) |
| Program Tcl | `program_go_grant_miss_soc_00_excl.tcl` |
| UART capture | `capture_uart_grant_miss_00.py` 90 s / `NATIVE_V1_EXIST_ROW` / `pred=664` |
| Rollback | `B64B2649…` (371) — **not** this token |
| Forbidden | pulse `125978D3` waitbusy `157D6B73` close664 qualify |

When COM12 is released:

1. Re-read `BRIDGE.json`.
2. Require `com12_authorized_gate=GO-GRANT-MISS-SOC-00` and `program_authorized=true`.
3. Re-hash source + bit; mismatch STOP.
4. JTAG `210319BE776EA` only.
5. Arm COM12 first, DTR/RTS false.
6. Program **this** bit only. No synth while holding COM12.
7. UART to exist-row / pred=664 / 90 s.
8. Consume token, release COM12/JTAG, archive.
9. AI does not stamp BOARD_PASS.

Current BRIDGE token `E2R-QUALIFY-CDC-RVALID-PROGRAM-00` is **Cursor** — refuse.
