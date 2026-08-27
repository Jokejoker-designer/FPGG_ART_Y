# E2R-CDC-AR-RST-00 PREREGISTER — HUMAN_F1C

**Worktree:** `arty-a7-online-lm-board` ONLY  
**Authority:** `STATUS/E2R_F1C_DISPATCH.md`  
**Prior F1d:** E2R-CDC-ARREADY-MIG-00 / `CDC_INTERNAL_STUCK`

## Scientific frame

| Field | Value |
|-------|-------|
| OBSERVATION | F1d: `CDC_M_ARF=YES`, `CDC_HOLD=NO`, `CDC_S_ARV=NO` (AR FIFO write without s_clk drain) |
| UNKNOWN | Does AR async FIFO reset tied only to `m_rst_n` leave read-side stuck empty after ui-domain reset? |
| H_CANDIDATE | AR FIFO `.rst = !(m_rst_n && s_rst_n)` (both domains out of reset) |
| H_RIVAL | FWFT FSM bug unrelated to reset |
| FALSIFIER | `CDC_HOLD` still NO after fix |
| UNIT | One AR beat visible on s_clk |
| CONTROL | F1d bit `38C12831…` UART baseline |
| METRICS | `CDC_HOLD`, `CDC_S_ARV`, `MIG_AR`, `R_BEAT`, `pred=664`; WNS≥0; BRAM≤135; unsafe_cdc=0 |

## ONE UNKNOWN

Does dual-domain AR FIFO reset restore `CDC_HOLD` / `CDC_S_ARV` → `MIG_AR` → R → `pred=664`?

## ONE CHANGE

`rtl/board/a7ng_axi_read_cdc.sv` — `u_ar_fifo` instance only:

```systemverilog
// Before:
.rst(!m_rst_n),
// After:
.rst(!(m_rst_n && s_rst_n)),
```

Do NOT change R FIFO reset, FWFT FSM, top-level mux, or heartbeat sequencer.

## Gates

maxThreads 8; WNS≥0; TNS=0; unsafe_cdc=0; BRAM≤135; SIM_FULL=0; COM12 @115200; JTAG `210319BE776E`.
