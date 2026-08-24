# GATE: mig_board

**Agent:** `a7-ng-memory-arch`  
**Evidence class:** **BOARD_MIG** (Digilent AXI MIG silicon stall sweep)  
**Date:** 2026-08-22  
**Law id:** `a7ng-mig-board-v0`  
**Result:** **PASS_NARROW**

## Scientific frame

| Field | Value |
|-------|-------|
| OBSERVATION | MIG_XSIM stall rows exist; §14 board DDR still OPEN |
| UNKNOWN | can silicon Digilent AXI MIG produce ≥1 preregistered stall/throughput row without inventing GB/s? |
| H_CANDIDATE | BOARD_MIG_SWEEP_ROW archived |
| H_RIVAL | XSim sold as board; invent bandwidth |
| FALSIFIER | hand-edit mig.prj; frozen overwrite; BOARD_PASS from XSim |
| UNIT | sweep cell (burst × outstanding) — (1,1) and (4,8), TOTAL=64 |
| CONTROL | MIG-RIVAL XSim rows; mig.prj MATCH AXI |
| METRICS | PE stall_frac; recs/cycle; DROP; ddr_rd_bytes (integers; no GB/s) |

## Verdict

**PASS_NARROW.** H_CANDIDATE **supported**. H_RIVAL **did not fire**.

- Digilent Arty A7-100T `210319BE776EA` present; programmed `arty_a7_ng_mig_board.bit`.
- Official Digilent AXI `mig.prj` **untouched** (SHA MATCH; PortInterface=AXI; app_*=0).
- BOARD_MIG_SWEEP_ROW: (1,1) stall=**0.923261**; (4,8) stall=**0.585366**; DROP=0.
- WNS=**+1.068** ns (HS-12).
- Frozen LM-06 / 01R / 02M / A0.3 **MATCH** (not overwritten).
- **No Native V1 BOARD_PASS. No HS-02. No invent GB/s.**

## Headline

| Claim | Grade |
|-------|-------|
| Silicon (1,1)/(4,8) stall_frac | **EVIDENCE** BOARD_MIG |
| mig.prj Digilent AXI untouched | **EVIDENCE** SHA MATCH |
| MIG_XSIM CONTROL retained | **CONTROL** (≠ board equality) |
| Native V1 BOARD_PASS | **REFUSED** |

## CHANGED

| Path | Role |
|------|------|
| `rtl/board/arty_a7_ng_mig_board_top.sv` | Digilent MIG + ddr_feed auto-sweep + UART |
| `rtl/native_graph/memory/a7ng_ddr_feed_pp.sv` | AR 1-cycle pipe + 16b remain (HS-12) |
| `vivado/tcl/native_graph/build_mig_board.tcl` | synth/impl/bit |
| `results/A7-NATIVE-GRAPH/MIG-BOARD/**` | bit, UART, rows, GATE |
| `docs/native_graph/RESOURCE_BUDGET.md` | measured board stalls |

**NOT changed:** `mig.prj`; frozen LM-06/01R/02M/A0.3 bits.

## TESTS

| ID | Result |
|----|--------|
| JTAG probe Digilent 210319BE776EA | PASS |
| mig.prj SHA / AXI / app_* | MATCH / AXI / 0 |
| Frozen LM/01R/02M/A0.3 | MATCH |
| Impl WNS | +1.068 PASS (HS-12) |
| Program + UART marker | PASS `A7NG_MIG_BOARD_ROW_OK` |
| BOARD_MIG_SWEEP_ROW ≥1 cell | PASS (2 cells) |
| Invent GB/s / hand-edit mig / BOARD_PASS | REFUSED |

## SHA256 (primary)

`EF94BA6B7D7D2ABF3B2E7EFAC965F78AD565E7300657E948062494D7008B2EF1  arty_a7_ng_mig_board.bit`  
`870FA6EEC23436FA8AD2A8772A80865016807CA37542C0C994E9E1E88152190D  mig.prj`  
(full: `SHA256.txt`)

## NEXT

Parent verify / auditor. Continue §14 queue. No Native V1 BOARD_PASS from this gate alone.
