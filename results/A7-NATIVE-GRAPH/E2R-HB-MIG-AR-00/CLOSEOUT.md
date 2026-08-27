# E2R-HB-MIG-AR-00 CLOSEOUT — D4-MIG-AR-ACCEPT

**Worktree:** `arty-a7-online-lm-board` ONLY  
**Agent:** a7-vivado-gate  
**Authority:** `results/A7-NATIVE-GRAPH/STATUS/E2R_D4_MIG_AR_ACCEPT.md`  
**Date:** 2026-08-26T00:39+07

## Verdict

| Claim | Result |
|-------|--------|
| Build / timing / CDC / BRAM gates | **PASS** |
| Board CASE (MIG AR accept) | **CASE=A** |
| Existence (`pred=664`) | **FAIL** (`NO_PRED`) |

**CASE=A:** core `AR_BEAT`=1, `MIG_AR`=`MIG_ARF`=0 → fault **before** MIG (CDC / bridge / mux / handshake).  
Do **not** claim MIG broken. B1 remains falsified. RID N/A (no RVALID). ARADDR latch / D4b **not** indicated (Case B only).

## Build (post-route)

| Metric | Value | Provenance | Gate |
|--------|-------|------------|------|
| maxThreads | 8 | build_stdout | OK |
| Design WNS | 0.731 ns | post-route timing summary | PASS (≥0) |
| Design TNS | 0.000 ns | post-route | PASS (=0) |
| Design WHS | 0.008 ns | post-route | PASS |
| Design THS | 0.000 ns | post-route | PASS |
| core_clk WNS | 13.395 ns | e2r_metrics | PASS |
| core_clk TNS | 0 ns | e2r_metrics | PASS |
| clk_pll_i (ui) WNS | 3.064 ns | e2r_metrics | PASS |
| clk_pll_i (ui) TNS | 0 ns | e2r_metrics | PASS |
| unsafe_cdc | 0 | e2r_metrics / report_cdc | PASS |
| Block RAM Tile / RAMB36 | 104 / 104 | post-route util | PASS (≤135) |
| DSP48E1 | 19 | post-route util | (info) |
| Slice LUTs | 54796 | post-route util | (info) |
| gate_pass | 1 | e2r_metrics | PASS |

Bit archived: `arty_a7_ng_native_v1_hb_mig_ar_00.bit`  
**BIT_SHA256:** `8E1E393D71DC3699A849010A13C53F305C855CC03F24B7811B8FF579C1B81E05`

## Board program

| Item | Value |
|------|-------|
| UART arm | COM12 @115200, 180s **before** program |
| JTAG | `Digilent/210319BE776EA` (Arty A7-100T) |
| Program | `HB_MIG_AR_BIT_PROGRAM_PASS` in `bit_program.log` |
| Ports seen | COM12,COM3,COM4 |

## UART markers (board)

```
BOOT MIG_OK WMEM_OK SOA_OK CORE_START OWNER_RDY Q_GO SOA_RUN
AR_BEAT R_BUSY R_IDLE RREADY1 OUTST
```

| Marker | Seen |
|--------|------|
| AR_BEAT | YES |
| RV_SEEN / MIG_RV / CDC_NE | NO |
| MIG_AR | **NO** |
| OWN_WDMA | **NO** |
| CDC_AR | **NO** |
| MUX_CDC | **NO** |
| LAST_STAGE | OUTST |
| STALL_CLASS | AXI_MIG_AR_PATH |
| STALL_SUBCLASS | CDC_NO_AR |
| pred | **none** (`NO_PRED`) |

## Classification (preregistered)

| Case | Pattern | Observed |
|------|---------|----------|
| **A** | AR_BEAT=1, MIG_ARF/MIG_AR=0 | **YES** |
| **B** | MIG_ARF/MIG_AR=1, no RVALID | NO |

H_CANDIDATE (MIG never sees query AR after Q_GO) **not falsified** — UART never printed `MIG_AR`.  
Subclass `CDC_NO_AR`: CDC never presented `s_axi_arvalid` sticky after Q_GO (also no WDMA steal marker).

## Forbidden checks

- No B1 re-patch as primary
- No “MIG broken” claim (Case A = pre-MIG)
- No host weight poke / R6 steal / BOARD_PASS
- No invented functional fix; no D4b ARADDR latch (Case B only)

## Return block

```
CASE=A
MIG_AR=NO
OWN_WDMA=NO
CDC_AR=NO
MUX_CDC=NO
pred=NO_PRED
bit_SHA=8E1E393D71DC3699A849010A13C53F305C855CC03F24B7811B8FF579C1B81E05
EXISTENCE=FAIL
```
