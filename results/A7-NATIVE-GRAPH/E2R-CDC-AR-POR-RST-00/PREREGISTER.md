# E2R-CDC-AR-POR-RST-00 PREREGISTER — F1i

**Worktree:** `arty-a7-online-lm-board` ONLY  
**Authority:** `STATUS/E2R_F1I_DISPATCH.md`  
**Prior:** F1g RST_LO NO; F1h board-seq XSim PASS → not sequencing; silicon XPM/rst coupling open

## Scientific frame

| Field | Value |
|-------|-------|
| OBSERVATION | Isolated CDC OK in XSim; board M_ARF without HOLD; no post-Q_GO rst LO |
| UNKNOWN | Does tying AR FIFO `.rst` to live `!(m_rst_n&&s_rst_n)` leave XPM gray pointers wedged on silicon after domain bring-up? |
| H_CANDIDATE | POR-only AR FIFO reset (assert once both clocks run, then hold rst=0 forever) restores `CDC_HOLD`/`CDC_S_ARV` |
| H_RIVAL | SoC mux/other — POR-only still stuck |
| FALSIFIER | UART still CDC_HOLD=NO after F1i |
| UNIT | One query boot after program |
| CONTROL | F1g UART |
| METRICS | CDC_HOLD, CDC_S_ARV, MIG_AR, pred=664; unsafe_cdc=0; WNS≥0 |

## ONE UNKNOWN

Does POR-only AR FIFO reset (release after both domains high ≥16 wr_clk, never re-assert) restore `CDC_S_ARV` and `CDC_HOLD` on silicon?

## ONE CHANGE

`rtl/board/a7ng_axi_read_cdc.sv` AR FIFO only:

- Replace `.rst(!(m_rst_n && s_rst_n))` with POR-only `ar_fifo_rst`.
- Assert while either domain in reset OR until both high for ≥16 `m_clk` cycles.
- After release, hold `fifo_rst=0` forever (ignore later domain rst).
- R FIFO / AR FWFT direct presentation unchanged.

## Gates

maxThreads 8; WNS≥0; TNS=0; unsafe_cdc=0; BRAM≤135; SIM_FULL=0; COM12 @115200; JTAG `210319BE776E`.

## Success path

- If `CDC_S_ARV` YES and `CDC_HOLD` YES → existence check `pred=664`
- If still stuck → H_RIVAL (SoC mux / MIG / clock stop)
- Existence PASS only if `pred=664`
