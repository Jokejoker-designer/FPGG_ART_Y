# E2R-CDC-RST-PROBE-00 PREREGISTER — F1g

**Worktree:** `arty-a7-online-lm-board` ONLY  
**Authority:** `STATUS/E2R_F1G_DISPATCH.md`  
**Prior:** F1e silicon CDC_M_ARF=YES / CDC_HOLD=NO; F1f XSim PASS (s_arv in 16 s_clk)

## Scientific frame

| Field | Value |
|-------|-------|
| OBSERVATION | Silicon: M_ARF yes, HOLD no. Sim: same RTL presents s_arv |
| UNKNOWN | Does `m_rst_n`/`core_rst_n` or `s_rst_n`/`ui_rst_n` glitch LOW after Q_GO (clearing AR FIFO after sticky M_ARF)? |
| H_CANDIDATE | Post-Q_GO reset glitch clears AR FIFO → explains M_ARF without HOLD |
| H_RIVAL | Other silicon issue (clock stop, probe bug) — RST_LO markers stay NO |
| FALSIFIER | No RST_LO after Q_GO on UART |
| UNIT | One query boot after program |
| CONTROL | F1e UART + F1f sim PASS |
| METRICS | `M_RST_LO`, `S_RST_LO` (new); existing CDC_*; pred |

## ONE UNKNOWN

Does post-Q_GO `core_rst_n` or `ui_rst_n` go LOW on silicon (UART `M_RST_LO` / `S_RST_LO`)?

## ONE CHANGE (probe only)

`rtl/board/arty_a7_ng_native_v1_ab_soc_top.sv` heartbeat/sticky only:

- Sync `core_rst_n` / `ui_rst_n` into CLK100MHZ (`clk_locked` reset only).
- After `qgo_100` seen: latch `sticky_m_rst_lo_100` if `!core_rst_n_100`; `sticky_s_rst_lo_100` if `!ui_rst_n_100`.
- Emit UART `M_RST_LO` / `S_RST_LO` after `CDC_S_ARR` (stages 26/27).

Do NOT change `a7ng_axi_read_cdc.sv`, mux, or arready.

## Gates

maxThreads 8; WNS≥0; TNS=0; unsafe_cdc=0; BRAM≤135; SIM_FULL=0; COM12 @115200; JTAG `210319BE776E`.

## Success path

- If `M_RST_LO` or `S_RST_LO` YES → F1h freeze AR FIFO rst after first release
- If both NO → F1h alternate (clock enable / CDC empty probe raw)
- Existence PASS only if `pred=664`
