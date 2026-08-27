# E2R-CDC-AR-HS-BYPASS-00 PREREGISTER — F1k

**Worktree:** `arty-a7-online-lm-board` ONLY  
**Authority:** `STATUS/E2R_F1K_DISPATCH.md`  
**Prior:** F1j — `AR_FIFO_NE=NO`, `CDC_M_ARF=YES` (write never reaches rd_clk)

## Scientific frame

| Field | Value |
|-------|-------|
| OBSERVATION | XPM `xpm_fifo_async` AR: master handshake yes, `ar_empty` never clears on s_clk |
| UNKNOWN | Does replacing AR XPM async FIFO with `xpm_cdc_handshake` restore `CDC_S_ARV` / `AR_FIFO_NE` / `pred=664`? |
| H_CANDIDATE | XPM AR async FIFO gray/CDC fails on this silicon; handshake CDC works |
| H_RIVAL | Broader SoC/clock issue — handshake also stuck |
| FALSIFIER | Still `CDC_S_ARV=NO` and no `AR_FIFO_NE` after F1k |
| UNIT | One query boot after program |
| CONTROL | F1j UART + bit `B732E788…` |
| METRICS | `AR_FIFO_NE`, `CDC_S_ARV`, `CDC_HOLD`, `MIG_AR`, `R_BEAT`, `pred=664`; unsafe_cdc=0; WNS≥0 |

## ONE CHANGE

`rtl/board/a7ng_axi_read_cdc.sv` AR path only: remove `u_ar_fifo` + POR rst; 47b `{arburst,arsize,arid,arlen,araddr}` via `xpm_cdc_handshake` (1 outstanding). R FIFO unchanged. Probes + top UART `AR_FIFO_NE` kept.

## Gates

Narrow XSim first (s_arv ≤50 s_clk). Then maxThreads 8; WNS≥0; TNS=0; unsafe_cdc=0; BRAM≤135; COM12 @115200; JTAG `210319BE776E`.

## Success

Existence PASS only if `pred=664`.
