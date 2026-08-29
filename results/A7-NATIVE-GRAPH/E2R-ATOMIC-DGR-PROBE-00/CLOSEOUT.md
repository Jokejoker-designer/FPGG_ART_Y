# E2R-ATOMIC-DGR-PROBE-00 — CLOSEOUT (CLASS SET, no BOARD_PASS)

**Agent:** `a7-vivado-gate`  
**Workspace:** `D:/Jetking_sem4/SEM_4/arty-a7-online-lm-board`  
**Authority:** `STATUS/E2R_ATOMIC_DGR_PROBE_DISPATCH.md` (human DECIDE=F1x)  
**com12_authorized_gate:** `E2R-ATOMIC-DGR-PROBE-00` only  
**JTAG:** `210319BE776EA` (single target; program refused if second/PYNQ)  
**UART:** COM12 115200 armed **before** program  
**C_FIX:** **NONE**  
**BOARD_PASS:** **not claimed**  
**EXISTENCE:** **not claimed** (`pred=664` not this gate)

XSim ≠ board. One query. Classification from frozen ATOM rows only — sequential `TILE_DST`/`GRANT`/`RPATH_IDLE` are CONTROL (UART-SKEW), not class rows. No LiteScope/ILA (hw_server: no soft debug core). No A2 / B1 / `soa_done` / force dest.

## Scientific frame

| Field | Value |
|-------|-------|
| OBSERVATION | UART-SKEW **SKEW** — printed `4` then `0` `0` is not same-cycle. Stub has no same-cycle `4,0,0`. |
| UNKNOWN | At first core-clock `dbg_tile_dst==4 && wdma_owner`, what is ATOM0 and ATOM1 (next core cycle)? |
| H_CANDIDATE | ATOM0/1: `dst=4, grant=0, idle=0` (real leftover occupancy). |
| H_RIVAL | ATOM0: `dst=4, idle=1` (prior UART was skew; B1 may still work). |
| FALSIFIER | Serialize live TILE_DST/GRANT/IDLE as class; force dest; C-FIX; A2. **Not used.** |
| UNIT | One query; first dest=4∧owner + exactly one later core cycle. |
| CONTROL | B-FIX sequential UART; UART-ENC FAITHFUL; UART-SKEW SKEW. |
| METRICS | ATOM hex, decode, class. Gate PASS = rows captured and decoded. |

## Numeric gates (post-route `report_timing_summary.rpt`)

TCL `e2r_metrics.txt` WNS/TNS printed NA (regex miss); signoff from the report file.

| Metric | Value | Provenance | Gate |
|--------|-------|------------|------|
| WNS | 0.265 ns | post-route Design Timing Summary | PASS (≥0) |
| TNS | 0.000 ns | post-route Design Timing Summary | PASS (=0) |
| WHS | 0.016 ns | post-route Design Timing Summary | PASS |
| THS | 0.000 ns | post-route Design Timing Summary | PASS |
| core_WNS | 10.582 ns | intra-clock `core_clk` | PASS |
| core_TNS | 0.000 ns | intra-clock `core_clk` | PASS |
| ui_WNS | 2.505 ns | intra-clock `clk_pll_i` | PASS |
| ui_TNS | 0.000 ns | intra-clock `clk_pll_i` | PASS |
| BRAM36 | 103 | post-route util | PASS (≤135) |
| unsafe_cdc | 0 | `report_cdc.rpt` user_unsafe | PASS |
| DSP | 19 | post-route util | reported (not this gate) |
| LUT | 55257 | post-route util | reported |
| FF | 56705 | post-route util | reported |

## Bit

| Item | Value |
|------|-------|
| ARTIFACT | `results/A7-NATIVE-GRAPH/E2R-ATOMIC-DGR-PROBE-00/arty_a7_ng_native_v1_atomic_dgr_probe_00.bit` |
| SHA256 | `771163814B6914CECB872839A36BD95ED0249E839038E16C46D48755E66C48EA` |
| CONTROL B-FIX | unchanged `6023D9A340FD19056C736AB37408A05C31EFF44B1B12F6F0DEE84924969D28A1` |
| Frozen LM-06 | not overwritten |

Program log: `HW_TARGETS=localhost:3121/xilinx_tcf/Digilent/210319BE776EA` · `E2R_ATOMIC_DGR_PROBE_00_EXCL_PROGRAM_PASS`.

## UART (one boot query; COM12 armed first)

593 bytes. File: `uart_capture.txt`.

```text
TILE_DST=4
WDMA_OWNER=1
WDMA_GRANT=0
RPATH_IDLE=0
MGO=1
ATOM0=0000059C
ATOM1=0000059D
```

Sequential `GRANT=0` `IDLE=0` after `TILE_DST=4` is the UART-SKEW CONTROL, **not** the class.

## ATOM decode (preregistered pack, `[31:11]=0`)

| Field | bits | ATOM0 `0000059C` | ATOM1 `0000059D` |
|-------|------|------------------|------------------|
| dest | [2:0] | 4 | 5 |
| owner | [3] | 1 | 1 |
| grant | [4] | 1 | 1 |
| idle | [5] | 0 | 0 |
| drain | [6] | 0 | 0 |
| fifo_ne | [7] | 1 | 1 |
| c_rvalid | [8] | 1 | 1 |
| tr_nz | [9] | 0 | 0 |
| mgo_sticky | [10] | 1 | 1 |
| hi | [31:11] | 0 | 0 |

Trigger: ATOM0 latched first `dest==4 && owner`; ATOM1 = next core cycle only.

## Classification (exactly one)

**CLASS = SET**  
Constituents high on ATOM0 (dest=4, idle=0): **`fifo_ne`, `c_rvalid`**.  
SET is >1 constituent — **no single wire named. No C-FIX. No B1 bypass. No A2.**

| Class | This query |
|-------|------------|
| OCC_400 | no (ATOM0 grant=1, not grant=0) |
| SKEW_IDLE1 | no (ATOM0 idle=0; ATOM1 dest=5 not dest=4 idle=1 grant=1) |
| GRANT_STUCK | no (idle≠1) |
| NO_DST4 | no (ATOM0 dest=4) |
| SET | **yes** |

## Hypothesis status (this unit only)

| Hypothesis | Status |
|------------|--------|
| H_CANDIDATE (`dst=4, grant=0, idle=0`) | **not supported** — ATOM0 grant=1 idle=0 |
| H_RIVAL (`dst=4, idle=1`) | **falsified** — ATOM0 dest=4 idle=0 |

n=1 query. Descriptive only. Sequential UART `4,0,0` remains SKEW versus same-cycle ATOM `4,1,0`.

## Gate

| Item | Value |
|------|-------|
| GATE | E2R-ATOMIC-DGR-PROBE-00 |
| CHANGED | probe-only ATOM latch + UART rows in `arty_a7_ng_native_v1_ab_soc_top.sv`; exclusive tcl |
| TESTS | exclusive synth/impl/bit; COM12 arm; JTAG `210319BE776EA` program; UART decode |
| EXPECTED | ATOM0/ATOM1 hex printed and decoded; WNS≥0 TNS=0 |
| ACTUAL | ATOM0=`0000059C` ATOM1=`0000059D`; WNS=0.265 TNS=0.000 |
| PASS\|FAIL | **PASS** (rows captured and decoded) |
| CLASS | SET |
| ATOM0 | 0000059C |
| ATOM1 | 0000059D |
| WNS | 0.265 ns (post-route) |
| TNS | 0.000 ns (post-route) |
| C_FIX | NONE |
| BOARD_PASS | not_claimed |
