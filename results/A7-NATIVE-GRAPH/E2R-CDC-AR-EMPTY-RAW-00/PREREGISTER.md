# E2R-CDC-AR-EMPTY-RAW-00 PREREGISTER — F1j

**Worktree:** `arty-a7-online-lm-board` ONLY  
**Authority:** `STATUS/E2R_F1J_DISPATCH.md`  
**Prior:** F1i POR-only rst FAIL — UART identical to F1g

## Scientific frame

| Field | Value |
|-------|-------|
| OBSERVATION | `CDC_M_ARF=YES`, `CDC_HOLD=NO`, all CDC RTL fixes falsified; XSim PASS |
| UNKNOWN | On silicon, does AR async FIFO `ar_empty` ever deassert after M_ARF? |
| H_CANDIDATE | Write never reaches rd_clk (`AR_FIFO_NE=NO`) — true CDC silicon/XPM gap |
| H_RIVAL | FIFO has data (`AR_FIFO_NE=YES`) but `cdc_arvalid`/mux never fires — presentation bug |
| FALSIFIER | `AR_FIFO_NE=YES` on UART |
| UNIT | One query boot after program |
| CONTROL | F1i UART |
| METRICS | `AR_FIFO_NE`, `CDC_S_ARV`, `CDC_HOLD`, `pred=664` |

## ONE CHANGE (probe only)

1. `a7ng_axi_read_cdc.sv`: `dbg_ar_empty_o` = registered `ar_empty` on `s_clk`.
2. `arty_a7_ng_native_v1_ab_soc_top.sv`: sticky `AR_FIFO_NE` if `!dbg_ar_empty_o` after `sticky_qgo_ui`; UART after `CDC_S_ARR`.

Do NOT change FIFO rst, FWFT, mux, arready.

## Gates

maxThreads 8; WNS≥0; TNS=0; unsafe_cdc=0; BRAM≤135; COM12 @115200; JTAG `210319BE776E`.

## Success path

- `AR_FIFO_NE=NO` → F1k: XPM CDC depth/sync or bypass (DECIDE)
- `AR_FIFO_NE=YES` + `CDC_S_ARV=NO` → F1k: mux/`s_axi_arvalid` path (DECIDE)
- Existence PASS only if `pred=664`
