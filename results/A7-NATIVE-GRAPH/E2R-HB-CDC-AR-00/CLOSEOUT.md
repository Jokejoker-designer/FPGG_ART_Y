# E2R-HB-CDC-AR-00 CLOSEOUT — E3-CDC-AR-PROBE

**Worktree:** `arty-a7-online-lm-board` ONLY  
**Agent:** a7-vivado-gate  
**Authority:** `results/A7-NATIVE-GRAPH/STATUS/E2R_E3_CDC_DISPATCH.md`  
**Prior D4:** E2R-HB-MIG-AR-00 CASE A / `CDC_NO_AR`  
**Date:** 2026-08-26T02:20+07

## Verdict

| Claim | Result |
|-------|--------|
| Build / timing / CDC / BRAM gates | **PASS** |
| Board subclass (E3) | **`CDC_INTERNAL_STUCK`** |
| Existence (`pred=664`) | **FAIL** (`NO_PRED`) |

**Subclass:** `CDC_M_ARF`=YES, `CDC_S_ARV`=NO forever → AR accepted on core into CDC master, slave never presents `cdc_arvalid` after Q_GO.  
`CDC_S_ARR`=YES falsifies ready-starve. Do **not** claim MIG broken. No functional fix. DECIDE next.

## Build (post-route)

| Metric | Value | Provenance | Gate |
|--------|-------|------------|------|
| maxThreads | 8 | build_stdout | OK |
| Design WNS | 1.005 ns | post-route timing summary | PASS (≥0) |
| Design TNS | 0.000 ns | post-route | PASS (=0) |
| Design WHS | 0.022 ns | post-route | PASS |
| Design THS | 0.000 ns | post-route | PASS |
| core_clk WNS | 10.716 ns | e2r_metrics | PASS |
| core_clk TNS | 0 ns | e2r_metrics | PASS |
| clk_pll_i (ui) WNS | 2.666 ns | e2r_metrics | PASS |
| clk_pll_i (ui) TNS | 0 ns | e2r_metrics | PASS |
| unsafe_cdc | 0 | e2r_metrics / report_cdc | PASS |
| Block RAM Tile / RAMB36 | 104 / 104 | post-route util | PASS (≤135) |
| DSP48E1 | 19 | post-route util | (info) |
| SIM_FULL | 0 | generic | OK |
| gate_pass | 1 | e2r_metrics | PASS |

Bit archived: `arty_a7_ng_native_v1_hb_cdc_ar_00.bit`  
**BIT_SHA256:** `94C03E066DF4E21C3723B34F60CF27E9496EF54E6C8CD70878804901ED4C4136`

Note: first build attempt `unsafe_cdc=2` (combo AR dbg into ui→100 sync). Fixed by registering `dbg_ar_*` on `s_clk` + DONT_TOUCH stickies; rebuild PASS.

## Board program

| Item | Value |
|------|-------|
| UART arm | COM12 @115200, 180s **before** program |
| JTAG | `Digilent/210319BE776EA` (Arty A7-100T) |
| Program | `HB_CDC_AR_BIT_PROGRAM_PASS` in `bit_program.log` |
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
| LAST_STAGE | CDC_S_ARR |
| STALL_CLASS | AXI_MIG_AR_PATH |
| STALL_SUBCLASS | **CDC_INTERNAL_STUCK** |
| pred | **none** (`NO_PRED`) |

## Classification (preregistered)

| Pattern | Class | Observed |
|---------|-------|----------|
| M_ARF=1, S_ARV=0 forever | **CDC_INTERNAL_STUCK** | **YES** |
| S_ARV=1, S_ARR=0 | CDC_READY_STARVE | NO (S_ARR=YES) |
| S_ARF=1, MIG_AR=0 | MUX_AFTER_CDC | NO |
| M_ARF=0 after Q_GO | AR_BEAT_PRE_QGO | NO (M_ARF=YES) |

H_CANDIDATE (stuck inside `a7ng_axi_read_cdc`) **supported**.  
H_RIVAL (`cdc_arready` starve) **falsified** (`CDC_S_ARR`=YES).

## Forbidden checks

- No B1 re-patch
- No “MIG broken” claim
- No host weight poke / R6 / full BOARD_PASS
- No invented functional fix — stop for DECIDE

## Return block

```
SUBCLASS=CDC_INTERNAL_STUCK
CDC_M_ARF=YES
CDC_S_ARV=NO
CDC_S_ARR=YES
CDC_S_ARF=NO
CDC_HOLD=NO
MIG_AR=NO
OWN_WDMA=NO
pred=NO_PRED
bit_SHA=94C03E066DF4E21C3723B34F60CF27E9496EF54E6C8CD70878804901ED4C4136
EXISTENCE=FAIL
```
