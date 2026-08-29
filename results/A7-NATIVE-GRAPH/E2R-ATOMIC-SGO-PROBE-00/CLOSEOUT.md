# E2R-ATOMIC-SGO-PROBE-00 — CLOSEOUT (CLASS SGO_HIT, no BOARD_PASS)

**Agent:** `a7-vivado-gate`  
**Workspace:** `D:/Jetking_sem4/SEM_4/arty-a7-online-lm-board`  
**Authority:** `STATUS/E2R_ATOMIC_SGO_PROBE_DISPATCH.md`  
**com12_authorized_gate:** `E2R-ATOMIC-SGO-PROBE-00` only  
**JTAG:** `210319BE776EA` (single target; program refused if second/PYNQ)  
**UART:** COM12 115200 armed **before** program  
**C_FIX:** **NONE**  
**BOARD_PASS:** **not claimed**  
**EXISTENCE:** **not claimed** (`pred=664` absent)

XSim ≠ board. One query. Classification from frozen ATOM rows only — sequential `SGO=` / `DMA_ST=` / `WDMA_OWN_UI=` are CONTROL, not class rows. No LiteScope/ILA (hw_server: no soft debug core). No A2 / B1 / `soa_done` / force dest / C-FIX.

## Scientific frame

| Field | Value |
|-------|-------|
| OBSERVATION | F1x ATOM dest=4 grant=1 leftover SET. Stub SGO_ROSE + LATCH_HIT. Silicon sequential SGO=0 DMA_ST=0 OWN_UI=0. UART SGO is sticky-latched while core_busy_ui. Not GRANT-skew. |
| UNKNOWN | At first core dest=4 && wdma_owner, packed SGO latch/sticky, OWN_UI, DMA_ST (synced to core)? |
| H_CANDIDATE | SGO_MISS (dest=4 grant=1, SGO bits 0) |
| H_RIVAL | SGO_HIT (dest=4 and latch or sticky =1) |
| FALSIFIER | sequential SGO row as class; force dest; C-FIX; A2; LiteScope; unsynced UI bits. **Not used.** |
| UNIT | One query; first dest=4∧owner + next core cycle. |
| CONTROL | ATOM0=`0000059C` (F1x DGR pack); SGO-MUX SGO_ROSE; LATCH_HIT SHA `74433CAE…`; sequential SGO=0. |
| METRICS | ATOM hex, decode, class. Gate PASS = rows captured and decoded. |

## Numeric gates (post-route `report_timing_summary.rpt`)

| Metric | Value | Provenance | Gate |
|--------|-------|------------|------|
| WNS | 0.406 ns | post-route Design Timing Summary | PASS (≥0) |
| TNS | 0.000 ns | post-route Design Timing Summary | PASS (=0) |
| WHS | 0.021 ns | post-route Design Timing Summary | PASS |
| THS | 0.000 ns | post-route Design Timing Summary | PASS |
| core_WNS | 8.796 ns | intra-clock `core_clk` | PASS |
| core_TNS | 0.000 ns | intra-clock `core_clk` | PASS |
| ui_WNS | 1.709 ns | intra-clock `clk_pll_i` | PASS |
| ui_TNS | 0.000 ns | intra-clock `clk_pll_i` | PASS |
| BRAM36 | 103 | post-route util | PASS (≤135) |
| LUT | 55269 | post-route util | reported |
| FF | 56725 | post-route util | reported |
| DSP | 19 | post-route util | reported (SoC; not encoder DSP=0) |
| Route | 102569/102569 nets, 0 errors | `report_route_status.rpt` | PASS |
| unsafe_cdc | 3 | `report_cdc.rpt` clk_pll_i→core_clk | FINDING (requested 3b dma_st `sync_bits`; F1x same path was 0) |

First exclusive write_bitstream aborted after route on a Tcl regex (`[\s\S]` invalid in Vivado Tcl). Bit written from the same `e2r_post_route.dcp` with ja-only NSTD-1/UCIO-1 waived (F1x exclusive list also omitted `e2r_la_pmod_ja.xdc`; no LiteScope). Timing numbers are from the pre-abort route reports.

## Bit

| Item | Value |
|------|-------|
| ARTIFACT | `results/A7-NATIVE-GRAPH/E2R-ATOMIC-SGO-PROBE-00/arty_a7_ng_native_v1_atomic_sgo_probe_00.bit` |
| SHA256 | `832E55E26232B4F2A5D84199EB86AEA1C7EBEEFEF30E51842BC44D8BB16385D2` |
| CONTROL F1x | unchanged `771163814B6914CECB872839A36BD95ED0249E839038E16C46D48755E66C48EA` |
| Frozen LM-06 | not overwritten |

Program log: `HW_TARGETS=localhost:3121/xilinx_tcf/Digilent/210319BE776EA` · `E2R_ATOMIC_SGO_PROBE_00_EXCL_PROGRAM_PASS`. COM12 armed first.

## UART (one boot query; COM12 armed first)

593 bytes. File: `uart_capture.txt`.

```text
TILE_DST=4
WDMA_OWN_UI=0
DMA_ST=0
SGO=0
WDMA_OWNER=1
WDMA_GRANT=0
RPATH_IDLE=0
MGO=1
ATOM0=00001B9C
ATOM1=00001B9D
```

Sequential `SGO=0` `DMA_ST=0` `WDMA_OWN_UI=0` is CONTROL (print-path / latch window), **not** the class.

## ATOM decode (preregistered pack, `[31:13]=0`)

| Field | bits | ATOM0 `00001B9C` | ATOM1 `00001B9D` |
|-------|------|------------------|------------------|
| dest | [2:0] | 4 | 5 |
| owner | [3] | 1 | 1 |
| grant | [4] | 1 | 1 |
| idle | [5] | 0 | 0 |
| sgo_latch (UI→core) | [6] | 0 | 0 |
| sgo_sticky (UI→core) | [7] | **1** | **1** |
| own_ui (UI→core) | [8] | 1 | 1 |
| dma_st (UI→core) | [11:9] | 5 (R) | 5 (R) |
| mgo_sticky | [12] | 1 | 1 |
| hi | [31:13] | 0 | 0 |

Trigger: ATOM0 latched first `dest==4 && owner`; ATOM1 = next core cycle only. UI bits via `sync_bits` 2-FF onto `core_clk`.

## Classification (exactly one, first match)

**CLASS = SGO_HIT**  
ATOM0 dest=4 and bit7 (`sgo_sticky` synced)=1. Do not use sequential `SGO=`.

| Class | This query |
|-------|------------|
| NO_DST4 | no (ATOM0 dest=4) |
| SGO_HIT | **yes** (sticky=1) |
| OWN_UI0 | no (SGO_HIT matches first) |
| SGO_MISS | no (sticky=1) |
| SET | no (own_ui=1; SET_COND=false) |

## Hypothesis status (this unit only)

| Hypothesis | Status |
|------------|--------|
| H_CANDIDATE (`SGO_MISS`) | **not supported** — ATOM0 dest=4 grant=1 sticky=1 |
| H_RIVAL (`SGO_HIT`) | **supported** — dest=4 and synced sticky=1 |

n=1 query. Descriptive only. Sequential UART `SGO=0` remains print-path versus same-trigger ATOM sticky=1.

## Gate

| Item | Value |
|------|-------|
| GATE | E2R-ATOMIC-SGO-PROBE-00 |
| CHANGED | probe-only ATOM pack + UI→core `sync_bits` in `arty_a7_ng_native_v1_ab_soc_top.sv`; exclusive tcl |
| TESTS | exclusive synth/impl; DCP bitstream; COM12 arm; JTAG `210319BE776EA` program; UART decode |
| EXPECTED | ATOM0/ATOM1 hex printed and decoded; WNS≥0 TNS=0; new bit SHA |
| ACTUAL | ATOM0=`00001B9C` ATOM1=`00001B9D`; CLASS=SGO_HIT; WNS=0.406 TNS=0.000; SHA `832E55E2…` |
| PASS\|FAIL | **PASS** (rows captured and decoded) |
| CLASS | SGO_HIT |
| ATOM0 | 00001B9C |
| ATOM1 | 00001B9D |
| WNS | 0.406 ns (post-route) |
| TNS | 0.000 ns (post-route) |
| C_FIX | NONE |
| BOARD_PASS | not_claimed |
| EXISTENCE | not_claimed (`pred=664` absent) |
