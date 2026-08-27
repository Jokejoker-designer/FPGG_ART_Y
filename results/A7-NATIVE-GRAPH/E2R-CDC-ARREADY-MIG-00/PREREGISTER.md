# E2R-CDC-ARREADY-MIG-00 PREREGISTER — HUMAN_F1D

**Worktree:** `arty-a7-online-lm-board` ONLY  
**Authority:** `STATUS/E2R_F1D_DISPATCH.md`  
**Prior F1b:** E2R-CDC-HOLD-RST-00 / `CDC_INTERNAL_STUCK`

## Scientific frame

| Field | Value |
|-------|-------|
| OBSERVATION | F1a/F1b: `CDC_M_ARF=YES`, `CDC_S_ARR=YES`, `CDC_S_ARV=NO`, `MIG_AR=NO`, no pred |
| UNKNOWN | Does fake `cdc_arready` (not MIG `arready`) prevent CDC slave from presenting stable `cdc_arvalid` to mux? |
| H_CANDIDATE | `cdc_arready = !boot_active && !wdma_owner_ui && arready` (real MIG arready) |
| H_RIVAL | AR FIFO never drains on s_clk / FWFT FSM bug (F1c) |
| FALSIFIER | UART still `CDC_S_ARV=NO` after F1d → reject H_CANDIDATE |
| UNIT | One MIG AR handshake |
| CONTROL | F1b bit `D57E6A51…` UART baseline |
| METRICS | `CDC_S_ARV`, `MIG_AR`, `R_BEAT`, `SOA_Q`, `pred=664`; WNS≥0; BRAM≤135; unsafe_cdc=0 |

## ONE UNKNOWN

Does wiring `cdc_arready` to real MIG `arready` restore `CDC_S_ARV` → `MIG_AR` → R → `pred=664`?

## ONE CHANGE

`rtl/board/arty_a7_ng_native_v1_ab_soc_top.sv` line ~180 only:

```systemverilog
assign cdc_arready = !boot_active && !wdma_owner_ui && arready;
```

Do NOT change CDC module, B1, hold-rst, or heartbeat sequencer.

## Gates

maxThreads 8; WNS≥0; TNS=0; unsafe_cdc=0; BRAM≤135; SIM_FULL=0; COM12 @115200; JTAG `210319BE776E`.
