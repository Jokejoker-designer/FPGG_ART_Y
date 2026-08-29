# E2R-ATOMIC-SGO-PROBE-00 — GO (human board plugged)

**Agent:** `a7-vivado-gate`  
**Workspace:** `D:/Jetking_sem4/SEM_4/arty-a7-online-lm-board`  
**Results:** `results/A7-NATIVE-GRAPH/E2R-ATOMIC-SGO-PROBE-00/`  
**com12_authorized_gate:** `E2R-ATOMIC-SGO-PROBE-00` only  
**JTAG:** `210319BE776EA` · **UART:** COM12 115200  
**Arm COM12 capture before program.** One `vivado.exe` writer.

Human plugged the board 2026-08-27 ~22:23 +07 after MASTER named this observer. Do **not** reprogram F1x bit `77116381…`. New exclusive probe bit.

## Do not

A2 / B1 / `soa_done` / C-FIX / `assign r_path_idle=1` / LiteScope/ILA / Phase 2 / `graph_late_materialize_00` / overwrite frozen LM-06 01R 02M A0.3 / steal Grok R6 / declare BOARD_PASS / treat `pred=664` as this gate PASS / serialize live `SGO=` as the class row.

## Scientific frame

- **OBSERVATION:** F1x ATOM dest=4 grant=1 leftover SET. Stub SGO_ROSE + LATCH_HIT. Silicon sequential UART `SGO=0` `DMA_ST=0` `WDMA_OWN_UI=0`. UART SGO is sticky-latched while `core_busy_ui`, not a live pulse. Not GRANT-skew.
- **UNKNOWN:** at first core-clock `dbg_tile_dst==4 && wdma_owner`, what are packed SGO-latch, SGO-sticky, OWN_UI, DMA_ST (UI bits **synced to core**)?
- **H_CANDIDATE:** dest=4 grant=1 and SGO latch/sticky both 0 (`SGO_MISS`) — true miss vs stub.
- **H_RIVAL:** dest=4 and SGO latch or sticky =1 (`SGO_HIT`) — silicon did fire; sequential `SGO=0` is print-path, not occupancy.
- **FALSIFIER:** live sequential `SGO=` as class; force dest; C-FIX; A2; LiteScope; omit CDC and pack raw UI bits on core_clk.
- **UNIT:** one query; first dest=4∧owner + next core cycle (ATOM1).
- **CONTROL:** F1x ATOM0=`0000059C`; SGO-MUX SGO_ROSE; SGO-LATCH LATCH_HIT SHA `74433CAE…`; sequential UART `SGO=0`.
- **METRICS:** ATOM hex, decode, class. Gate PASS = rows captured and decoded. Existence remains `pred=664`.

## Pack (32-bit hex, `[31:13]=0`)

| bits | field | domain |
|------|--------|--------|
| [2:0] | `dbg_tile_dst` | core |
| [3] | `wdma_owner` | core |
| [4] | `wdma_owner_grant` | core |
| [5] | `r_path_idle` | core |
| [6] | `latched_sgo_f1u` synced to core | UI→core |
| [7] | `dbg_s_go_sticky` synced to core | UI→core |
| [8] | `wdma_owner_ui` synced to core | UI→core |
| [11:9] | `dma_st` (3b) synced to core | UI→core |
| [12] | `mgo_sticky` | core |

Sync with existing `sync_bits` / `xpm_cdc_single` (same 2/3 FF as SoC). **Do not** sample UI bits on core_clk without CDC.

Print only:

```text
ATOM0=<8 hex>
ATOM1=<8 hex>
```

(`ATOM0=NONE` if dest=4 never occurs.)

## Trigger

First `dbg_tile_dst==3'd4 && wdma_owner` → ATOM0. Next core cycle → ATOM1. Freeze.

## Class (exactly one, first match)

| Class | Decode |
|-------|--------|
| `NO_DST4` | no dest=4 |
| `SGO_HIT` | dest=4 and (bit6 or bit7)=1 |
| `OWN_UI0` | dest=4, SGO bits 0, own_ui=0 |
| `SGO_MISS` | dest=4, SGO bits 0, own_ui=1 |
| `SET` | dest=4 and both SGO=1 and own_ui=0 (report both; no C-FIX) |

## RTL / build

Probe-only in `rtl/board/arty_a7_ng_native_v1_ab_soc_top.sv`. Exclusive tcl (F1x/B-FIX excl style).  
`$env:XILINXD_LICENSE_FILE='D:\Xilinx\licenses\vivado_basic.lic'`  
WNS≥0 TNS=0. New bit SHA. Confirm JTAG `210319BE776EA` only. Recapture if 0-byte UART.

## Done

`CLOSEOUT.md` + uart + SHA. `C_FIX=NONE`. `BOARD_PASS: not claimed`. `EXISTENCE: not claimed`.
