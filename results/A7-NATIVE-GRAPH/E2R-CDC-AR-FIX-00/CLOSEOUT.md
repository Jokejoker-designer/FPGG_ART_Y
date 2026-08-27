# E2R-CDC-AR-FIX-00 CLOSEOUT — HUMAN_F1A

**Worktree:** `arty-a7-online-lm-board` ONLY  
**Agent:** a7-vivado-gate  
**Authority:** `STATUS/E2R_F1_CDC_FIX_DISPATCH.md`  
**Prior E3:** E2R-HB-CDC-AR-00 / `CDC_INTERNAL_STUCK`  
**Date:** 2026-08-26T03:22+07

## Ack

`HUMAN_F1A` — ONE change: AR FIFO → FWFT + simple `s_arvalid` hold in `a7ng_axi_read_cdc.sv`. **F1b not applied.**

## ONE UNKNOWN (answered)

Does F1a restore `CDC_S_ARV` → MIG_AR → R → `pred=664`?  
**NO.** F1a **falsified** on board.

## Verdict

| Claim | Result |
|-------|--------|
| Build / timing / CDC / BRAM gates | **PASS** |
| F1a functional (CDC_S_ARV restored) | **FAIL** |
| Board subclass | **`CDC_INTERNAL_STUCK`** (unchanged) |
| Existence (`pred=664`) | **FAIL** (`NO_PRED`) |

**Do not claim** existence PASS or full BOARD_PASS. **DECIDE F1b** next (sever `core_hold` from CDC `m_rst_n`). Do not silently stack F1a+F1b without a new bag.

## ONE CHANGE (applied)

`rtl/board/a7ng_axi_read_cdc.sv` SHA256=`6EB56E608D1E734EEB89B7AF64DE96EA2B1A980CD4BDD4E0B0646E33B079842C`

- AR `xpm_fifo_async`: `READ_MODE("fwft")`, `FIFO_READ_LATENCY(0)`
- Removed std latency-1 `s_ar_pend` FSM
- Simple hold: when `!ar_empty && !s_ar_hold` capture `dout` → `s_axi_ar*`, assert `s_arvalid`; on handshake pulse `ar_rd_en` / clear hold
- R-side unchanged; `dbg_ar_*` still registered on `s_clk`

**Latent hazard (not fixed this bag):** top still wires  
`u_axi_cdc.m_rst_n = core_rst_n && !core_hold` — F1b candidate.

## Verify path

- Narrow xvlog of CDC module: **PASS** (VRFC 10-311)
- No dedicated AR-CDC TB → board is falsifier

## Build (post-route)

| Metric | Value | Provenance | Gate |
|--------|-------|------------|------|
| maxThreads | 8 | build_stdout | OK |
| Design WNS | 1.276 ns | report_timing_summary | PASS (≥0) |
| Design TNS | 0.000 ns | post-route | PASS (=0) |
| Design WHS | 0.015 ns | post-route | PASS |
| Design THS | 0.000 ns | post-route | PASS |
| core_clk WNS | 10.669 ns | e2r_metrics | PASS |
| core_clk TNS | 0 ns | e2r_metrics | PASS |
| clk_pll_i (ui) WNS | 1.539 ns | e2r_metrics | PASS |
| clk_pll_i (ui) TNS | 0 ns | e2r_metrics | PASS |
| unsafe_cdc | 0 | e2r_metrics / report_cdc | PASS |
| Block RAM Tile / RAMB36 | 104 / 104 | post-route util | PASS (≤135) |
| DSP48E1 | 19 | post-route util | (info) |
| SIM_FULL | 0 | generic | OK |
| gate_pass | 1 | e2r_metrics | PASS |

Bit archived: `arty_a7_ng_native_v1_cdc_ar_fix_00.bit`  
**BIT_SHA256:** `678E3541CD5FA9AD060E4AD83EF7F0813527E703E6789DDA2F7606ACDDC039A8`

## Board program

| Item | Value |
|------|-------|
| UART arm | COM12 @115200, 180s **before** program |
| JTAG | `Digilent/210319BE776EA` (Arty A7-100T) |
| Program | `CDC_AR_FIX_BIT_PROGRAM_PASS` in `bit_program.log` |
| Ports seen | COM12,COM3,COM4 |

## UART markers (board)

```
BOOT MIG_OK WMEM_OK SOA_OK CORE_START OWNER_RDY Q_GO SOA_RUN
AR_BEAT R_BUSY R_IDLE RREADY1 OUTST
CDC_M_ARF CDC_S_ARR
```

| Marker | Seen |
|--------|------|
| AR_BEAT | YES |
| CDC_M_ARF | **YES** |
| CDC_S_ARV | **NO** |
| CDC_S_ARR | **YES** |
| CDC_S_ARF | **NO** |
| CDC_HOLD | **NO** |
| MIG_AR / CDC_AR / MUX_CDC / OWN_WDMA | NO |
| R_BEAT | NO |
| LAST_STAGE | CDC_S_ARR |
| STALL_CLASS | AXI_MIG_AR_PATH |
| STALL_SUBCLASS | **CDC_INTERNAL_STUCK** |
| pred | **none** (`NO_PRED`) |

## Classification

| Pattern | Class | Observed |
|---------|-------|----------|
| M_ARF=1, S_ARV=0 forever | **CDC_INTERNAL_STUCK** | **YES** (F1a did not clear) |
| S_ARV=1, S_ARR=0 | CDC_READY_STARVE | NO |
| S_ARF=1, MIG_AR=0 | MUX_AFTER_CDC | NO |

**FALSIFIER hit:** after F1a rebuild+program, still `CDC_S_ARV=0` with `CDC_M_ARF=1`.

## Forbidden checks

- No B1 re-patch
- No host weight poke / R6 / STARTUPE2
- No F1b stacked in this bag
- No full BOARD_PASS / existence PASS claim

## Next (DECIDE)

**F1b:** `u_axi_cdc.m_rst_n = core_rst_n` only — never `&& !core_hold` (hold must not wipe AR FIFO); backpressure without reset. New bag required.

## Return block

```
HUMAN_F1A=ACK
F1a=FAIL
SUBCLASS=CDC_INTERNAL_STUCK
CDC_S_ARV=NO
CDC_M_ARF=YES
CDC_S_ARR=YES
MIG_AR=NO
R_BEAT=NO
pred=NO_PRED
bit_SHA=678E3541CD5FA9AD060E4AD83EF7F0813527E703E6789DDA2F7606ACDDC039A8
EXISTENCE=FAIL
DECIDE=F1b
```
