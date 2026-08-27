# E2R-B1-RPATH-00 CLOSEOUT — BOARD FAIL (no R_BEAT)

**Date:** 2026-08-25  
**Worktree:** `arty-a7-online-lm-board` ONLY  
**Agent:** a7-vivado-gate  
**Authorization:** HUMAN_BOARD_BACK — D2 silicon finalize ONLY; no rebuild

## Verdict

| Claim | Result |
|-------|--------|
| `NATIVE_V1_EXISTENCE_BOARD_PASS` | **NO** (pred absent; requires pred=664) |
| Full `BOARD_PASS` / Native V1 mini-AI | **NOT claimed** |
| Gate outcome | **FAIL** — AR fires, **no `R_BEAT`**, stall class `AXI_MIG_R_PATH` |
| Recommended next | **D3** (honest fail; no extra unrelated RTL in this bag) |

## ONE UNKNOWN (answered)

Does B1 `r_path_idle` ownership interlock restore R beats → SOA_Q → pred=664?

**Answer (board):** **No.** UART saw `AR_BEAT` then `R_BUSY` / `R_IDLE` without ever emitting line-exact `R_BEAT`; no `SOA_Q` / `TOPK` / `pred=`.

## ONE CHANGE (prior rebuild; not re-run this session)

`rtl/board/arty_a7_ng_native_v1_ab_soc_top.sv`: registered `wdma_owner_grant` — grant only when `wdma_owner && r_path_idle`; release on `!wdma_owner`; CDC `m_owner` = grant. D1 heartbeats + F2 decimal pred kept. SIM_FULL=0.

## Board procedure (this session)

1. Human confirmed board plugged in (`BOARD_BACK`).
2. Armed `capture_uart_hb.py` on **COM12 @ 115200** for **180 s** **before** program (`uart_capture_r2.txt` / `uart_listen_stdout_r2.txt`).
3. Programmed via `vivado/tcl/program_b1_rpath_00.tcl` — single Vivado batch.
4. JTAG target: `localhost:3121/xilinx_tcf/Digilent/210319BE776EA` (matches `210319BE776E*`).
5. Marker: `B1_RPATH_BIT_PROGRAM_PASS` in `bit_program_r2.log`.

## Bit / rebuild gates (unchanged; no rebuild)

| Metric | Value | Gate | Verdict |
|--------|-------|------|---------|
| core_clk WNS | **+12.031 ns** | ≥0 | **PASS** (post-route, prior) |
| core_clk TNS | 0 | =0 | **PASS** |
| ui (clk_pll_i) WNS | **+2.893 ns** | ≥0 | **PASS** |
| ui TNS | 0 | =0 | **PASS** |
| unsafe user CDC | **0** | =0 | **PASS** |
| RAMB36 | **104** | ≤135 | **PASS** |
| SIM_FULL | 0 | =0 | **PASS** |

**Bit SHA256:** `87C04F573210312C09AB00F977160ED21F4ACA773A0B0E0FCDC521D0AF0D6616`  
**Bit path:** `results/A7-NATIVE-GRAPH/E2R-B1-RPATH-00/arty_a7_ng_native_v1_b1_rpath_00.bit`  
**On-disk SHA verify (this session):** match

## Board UART result (primary evidence)

| Item | Value |
|------|-------|
| Heartbeats | `BOOT,MIG_OK,WMEM_OK,SOA_OK,CORE_START,OWNER_RDY,Q_GO,SOA_RUN,AR_BEAT,R_BUSY,R_IDLE` |
| LAST_STAGE | **R_IDLE** |
| R_BEAT? | **NO** |
| pred | **NO_PRED** (no `NATIVE_V1_EXIST_ROW,pred=`) |
| STALL_CLASS | **AXI_MIG_R_PATH** |
| BYTES | 83 |
| Capture window | 180 s COM12 @ 115200 |
| `NATIVE_V1_EXISTENCE_BOARD_PASS` | **no** |

### Raw capture (`uart_capture_r2.txt`)

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
```

## Forbidden / not done

- No rebuild / re-synth / re-impl
- No host weight poke
- No R6 main-tree edits
- No full BOARD_PASS self-claim
- No golden edit

## Artifacts

```
results/A7-NATIVE-GRAPH/E2R-B1-RPATH-00/
  PREREGISTER.md
  CLOSEOUT.md (this file — replaces PARTIAL HOLD)
  BIT_SHA256.txt
  arty_a7_ng_native_v1_b1_rpath_00.bit
  e2r_metrics.txt
  report_timing_summary.rpt / report_cdc.rpt / report_utilization*.rpt
  bit_program_r2.log / bit_program_r2.jou
  uart_capture_r2.txt
  uart_listen_stdout_r2.txt
  capture_uart_hb.py
```
