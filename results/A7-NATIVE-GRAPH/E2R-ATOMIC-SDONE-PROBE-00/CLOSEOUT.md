# E2R-ATOMIC-SDONE-PROBE-00 — CLOSEOUT (CLASS SDONE_HIT, no BOARD_PASS)

**Agent:** `a7-vivado-gate`  
**Workspace:** `D:/Jetking_sem4/SEM_4/arty-a7-online-lm-board`  
**Authority:** `STATUS/E2R_ATOMIC_SDONE_PROGRAM_DISPATCH.md`  
**com12_authorized_gate:** `E2R-ATOMIC-SDONE-PROBE-00` (re-read immediately before `open_hw_manager`)  
**PROGRAM:** **YES**  
**JTAG:** `210319BE776EA` (single target; PYNQ/second target refused)  
**UART:** COM12 115200 armed **before** program  
**UART_BYTES:** 593  
**C_FIX:** **NONE**  
**BOARD_PASS:** **not claimed**  
**EXISTENCE:** **not claimed** (`pred=664` absent)

XSim ≠ board. One query. Classification from frozen ATOM rows only — sequential `SDONE=` / `GRANT=` / `SGO=` / banner `W_STALL` are CONTROL, not class rows. No LiteScope/ILA (hw_server: no soft debug core). No A2 / B1 / `soa_done` / force dest / C-FIX. No rebuild. Did not reprogram SGO `832E55E2…` or F1x `77116381…`.

## Scientific frame

| Field | Value |
|-------|-------|
| OBSERVATION | BUILD_PASS bit SHA `9DC0F8DF…` WNS=0.372. Sequential UART `SDONE=0`. Stub SDONE_ROSE / STILLR SNAP_DONE0 / ACK_ONLY_AFTER_DONE. |
| UNKNOWN | at first dest=4∧owner, packed s_done latch/sticky, w_stall, core_done? |
| H_CANDIDATE | dest=4 and both done bits 0 (`SDONE_MISS`) |
| H_RIVAL | dest=4 and latch or sticky =1 (`SDONE_HIT`) |
| FALSIFIER | sequential `SDONE=` as class; program wrong bit; force dest; C-FIX. **Not used.** |
| UNIT | ATOM0 (first dest=4∧owner) + ATOM1 (next core cycle) |
| CONTROL | SGO ATOM0 `00001B9C`; sequential `SDONE=0` |
| METRICS | ATOM hex, decode, class. Gate PASS = rows decoded. Existence = UART `pred=664` only. |

## Numeric gates (post-route `report_timing_summary.rpt`; BUILD session, not re-run)

| Metric | Value | Provenance | Gate |
|--------|-------|------------|------|
| WNS | 0.372 ns | post-route Design Timing Summary | PASS (≥0) |
| TNS | 0.000 ns | post-route Design Timing Summary | PASS (=0) |
| WHS | 0.013 ns | post-route Design Timing Summary | PASS |
| THS | 0.000 ns | post-route Design Timing Summary | PASS |
| core_WNS | 9.354 ns | intra-clock `core_clk` | PASS |
| core_TNS | 0.000 ns | intra-clock `core_clk` | PASS |
| ui_WNS | 1.276 ns | intra-clock `clk_pll_i` | PASS |
| ui_TNS | 0.000 ns | intra-clock `clk_pll_i` | PASS |
| BRAM36 | 103 | post-route util | reported (≤135) |
| LUT | 55264 | post-route util | reported |
| FF | 56713 | post-route util | reported |
| DSP | 19 | post-route util | reported (SoC; not encoder DSP=0) |
| Route | 102555/102555 nets, 0 errors | `report_route_status.rpt` | PASS |

## Bit (re-hashed before program and after; unchanged)

| Item | Value |
|------|-------|
| ARTIFACT | `results/A7-NATIVE-GRAPH/E2R-ATOMIC-SDONE-PROBE-00/arty_a7_ng_native_v1_atomic_sdone_probe_00.bit` |
| SHA256 | `9DC0F8DFF7BF068A92ED3E5A1A5B66FF5C56BEB7D6B3FACA7911912D498F951B` |
| CONTROL SGO | unchanged `832E55E26232B4F2A5D84199EB86AEA1C7EBEEFEF30E51842BC44D8BB16385D2` |
| CONTROL F1x | unchanged `771163814B6914CECB872839A36BD95ED0249E839038E16C46D48755E66C48EA` |
| Frozen LM-06 / 01R / 02M / A0.3 | not overwritten |

Program log: `HW_TARGETS=localhost:3121/xilinx_tcf/Digilent/210319BE776EA` · `E2R_ATOMIC_SDONE_PROBE_00_EXCL_PROGRAM_PASS`. COM12 armed first. Tcl: `vivado/tcl/program_e2r_atomic_sdone_probe_00_excl.tcl` (refuses SGO/F1x/B-FIX/R6/frozen/lm06).

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
ATOM0=0000059C
ATOM1=0000059D
```

Sequential `SDONE=0` `SGO=0` `WDMA_GRANT=0` and banner `W_STALL` / `PHASE=01` are CONTROL (print-path / latch window), **not** the class.

## ATOM decode (preregistered pack, `[31:13]=0`, `[12:11]=0`)

| Field | bits | ATOM0 `0000059C` | ATOM1 `0000059D` |
|-------|------|------------------|------------------|
| dest | [2:0] | 4 | 5 |
| owner | [3] | 1 | 1 |
| grant | [4] | 1 | 1 |
| idle | [5] | 0 | 0 |
| sdone_latch (UI→core) | [6] | 0 | 0 |
| sdone_sticky (UI→core) | [7] | **1** | **1** |
| w_stall | [8] | 1 | 1 |
| core_done | [9] | 0 | 0 |
| mgo | [10] | 1 | 1 |
| reserved | [12:11] | 0 | 0 |
| hi | [31:13] | 0 | 0 |

Trigger: ATOM0 latched first `dest==4 && owner`; ATOM1 = next core cycle only. `hi_ok=True` both rows.

## Classification (exactly one, first match)

**CLASS = SDONE_HIT**  
ATOM0 dest=4 and bit7 (`sdone_sticky` synced)=1. Do not use sequential `SDONE=`.

| Class | This query |
|-------|------------|
| NO_DST4 | no (ATOM0 dest=4) |
| SDONE_HIT | **yes** (sticky=1) |
| WSTALL | no (SDONE_HIT matches first; bit8=1 is decode only) |
| SDONE_MISS | no (sticky=1) |

## Hypothesis status (this unit only)

| Hypothesis | Status |
|------------|--------|
| H_CANDIDATE (`SDONE_MISS`) | **not supported** — ATOM0 dest=4 sticky=1 |
| H_RIVAL (`SDONE_HIT`) | **supported** — dest=4 and synced sticky=1 |

n=1 query. Descriptive only. Sequential UART `SDONE=0` remains print-path versus same-trigger ATOM sticky=1.

## Gate

| Item | Value |
|------|-------|
| GATE | E2R-ATOMIC-SDONE-PROBE-00 |
| CHANGED | PROGRAM only. Wrote exclusive program tcl + SDONE capture script. No RTL rebuild. |
| TESTS | re-hash bit; COM12 arm; JTAG `210319BE776EA` program; UART decode |
| EXPECTED | ATOM0/ATOM1 hex printed and decoded; this bit SHA only |
| ACTUAL | ATOM0=`0000059C` ATOM1=`0000059D`; CLASS=SDONE_HIT; SHA `9DC0F8DF…`; UART 593 B; `pred=664` absent |
| PASS\|FAIL | **PASS** (rows captured and decoded) |
| CLASS | SDONE_HIT |
| ATOM0 | 0000059C |
| ATOM1 | 0000059D |
| WNS | 0.372 ns (post-route BUILD; not re-run) |
| TNS | 0.000 ns (post-route BUILD; not re-run) |
| C_FIX | NONE |
| BOARD_PASS | not_claimed |
| EXISTENCE | not_claimed (`pred=664` absent) |
| NEXT | `a7-evidence-auditor` on this PROGRAM PASS; existence still OPEN |
