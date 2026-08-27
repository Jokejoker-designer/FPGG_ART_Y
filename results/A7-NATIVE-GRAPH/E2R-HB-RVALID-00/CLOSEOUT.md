# E2R-HB-RVALID-00 CLOSEOUT — BOARD FAIL (NO_RVALID)

**Date:** 2026-08-25  
**Worktree:** `arty-a7-online-lm-board` ONLY  
**Agent:** a7-vivado-gate  
**Authorization:** HUMAN_D3 — probe-only AXI-R sticky markers; no B1 re-patch; no rebuild this silicon step

## Verdict

| Claim | Result |
|-------|--------|
| `NATIVE_V1_EXISTENCE_BOARD_PASS` | **NO** (pred absent; requires pred=664) |
| Full `BOARD_PASS` / Native V1 mini-AI | **NOT claimed** |
| Gate outcome | **FAIL** — AR + OUTST + RREADY1; **no RVALID** anywhere |
| Stall class | `AXI_MIG_R_PATH` |
| Stall subclass | **NO_RVALID** |
| Recommended next | **DECIDE** (localize done; do not invent second RTL fix in this bag) |

## ONE UNKNOWN (answered)

After AR handshake, why never R beat — no RVALID? wrong RID? CDC FIFO drop? MIG silent?

**Answer (board):** **MIG silent / no RVALID.** Core never saw `c_rvalid` (`RV_SEEN` absent). MIG UI never asserted query-path `rvalid` (`MIG_RV` absent). CDC R path never held data (`CDC_NE` absent). RID never comparable (`RID_OK`/`RID_BAD` absent). Core **was** ready (`RREADY1`) and AR remained outstanding (`OUTST`).

## ONE CHANGE (prior rebuild; not re-run this session)

Probe-only sticky UART markers on real DUT bits + minimal CDC `dbg_r_ne_o`. D1 heartbeats + B1 grant interlock kept. SIM_FULL=0; F2 decimal pred kept.

## Rebuild gates (prior; reused)

| Metric | Value | Gate | Verdict |
|--------|-------|------|---------|
| core_clk WNS | **+7.468 ns** | ≥0 | **PASS** (post-route) |
| core_clk TNS | 0 | =0 | **PASS** |
| ui (clk_pll_i) WNS | **+2.774 ns** | ≥0 | **PASS** |
| ui TNS | 0 | =0 | **PASS** |
| unsafe user CDC | **0** | =0 | **PASS** |
| RAMB36 | **104** | ≤135 | **PASS** |
| SIM_FULL | 0 | =0 | **PASS** |

**Bit SHA256:** `889602B4747DFF95E9FC4064F8A56F35400C59761042FEF83BE402E1862E5ACF`  
**Bit path:** `results/A7-NATIVE-GRAPH/E2R-HB-RVALID-00/arty_a7_ng_native_v1_hb_rvalid_00.bit`  
**On-disk SHA verify (this session):** match

## Board procedure

1. Armed `capture_uart_hb.py` on **COM12 @ 115200** for **180 s** **before** program.
2. Programmed via `vivado/tcl/program_hb_rvalid_00.tcl` — single Vivado batch.
3. JTAG target: `localhost:3121/xilinx_tcf/Digilent/210319BE776EA` (matches `210319BE776E*`).
4. Marker: `HB_RVALID_BIT_PROGRAM_PASS` in `bit_program.log`.

## Board UART result (primary evidence)

| Item | Value |
|------|-------|
| Heartbeats | `BOOT,MIG_OK,WMEM_OK,SOA_OK,CORE_START,OWNER_RDY,Q_GO,SOA_RUN,AR_BEAT,R_BUSY,R_IDLE,RREADY1,OUTST` |
| LAST_STAGE | **OUTST** |
| R_BEAT? | **NO** |
| RV_SEEN | **NO** |
| RREADY1 | **YES** |
| RID_OK / RID_BAD | **NO / NO** |
| OUTST | **YES** |
| MIG_RV | **NO** |
| CDC_NE | **NO** |
| pred | **NO_PRED** |
| STALL_CLASS | **AXI_MIG_R_PATH** |
| STALL_SUBCLASS | **NO_RVALID** |
| BYTES | 97 |
| Capture window | 180 s COM12 @ 115200 |
| `NATIVE_V1_EXISTENCE_BOARD_PASS` | **no** |

### Raw capture (`uart_capture.txt`)

```
BOOT
MIG_OK
WMEM_OK
SOA_OK
CORE_START
OWNER_RDY
Q_GO
SOA_RUN
AR_BEAT
R_BUSY
R_IDLE
RREADY1
OUTST
```

### Subclass interpretation

| Marker pattern | Meaning |
|----------------|---------|
| AR_BEAT + OUTST | AR accepted; outstanding >0 |
| RREADY1 | Core `c_rready` high while waiting after AR |
| no RV_SEEN / no MIG_RV / no CDC_NE | No RVALID at core, MIG UI, or CDC R FIFO |
| no RID_* | RID never observed (no R beat to compare) |
| → **NO_RVALID** | Not RVALID_NO_READY, not RID_MISMATCH, not CDC_DROP |

## Forbidden / not done

- No rebuild this silicon step
- No host weight poke
- No R6 main-tree edits
- No B1 re-patch
- No STARTUPE2
- No full BOARD_PASS self-claim
- No golden edit
- No second RTL fix invented in this gate

## DECIDE — next RTL fix options (pick one; do not implement here)

| Opt | Hypothesis | Next action |
|-----|------------|-------------|
| **E1** | MIG never sees AR (mux/`cdc_arready`/`wdma_owner_ui` still steal after AR sticky) | Probe MIG-side `arvalid&&arready` sticky + `wdma_owner_ui` after Q_GO |
| **E2** | AR reaches MIG but addr/len illegal → silent (no R) | Probe latched ARADDR/ARLEN on ui; compare to SOA DDR map |
| **E3** | CDC AR FIFO accepts but s-side never presents to MIG (`s_ar_hold` stuck / `cdc_arready` window) | Probe CDC s_axi_arvalid sticky + MIG arready |
| **E4** | Pause | Human hold |

Prior B1 form already falsified as sole fix. Preferred: **E1** or **E3** (handshake path to MIG) before address-map deep dive.

## Artifacts

```
results/A7-NATIVE-GRAPH/E2R-HB-RVALID-00/
  PREREGISTER.md
  CLOSEOUT.md (this file)
  BIT_SHA256.txt
  arty_a7_ng_native_v1_hb_rvalid_00.bit
  e2r_metrics.txt
  report_timing_summary.rpt / report_cdc.rpt / report_utilization*.rpt
  bit_program.log / bit_program.jou
  uart_capture.txt
  uart_listen_stdout.txt
  capture_uart_hb.py
```
