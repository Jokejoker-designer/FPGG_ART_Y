# E2R-ATOMIC-DGR-PROBE-00 — GO (human DECIDE=F1x)

**Agent:** `a7-vivado-gate`  
**Workspace:** `D:/Jetking_sem4/SEM_4/arty-a7-online-lm-board`  
**Results:** `results/A7-NATIVE-GRAPH/E2R-ATOMIC-DGR-PROBE-00/`  
**com12_authorized_gate:** `E2R-ATOMIC-DGR-PROBE-00` only  
**JTAG:** `210319BE776EA` · **UART:** COM12 115200  
**Arm COM12 capture before program.** One `vivado.exe` writer.

## Do not

A2 / B1 / `soa_done` grant edit / C-FIX / `assign r_path_idle=1` / Phase 2 / `graph_late_materialize_00` / overwrite frozen LM-06 01R 02M A0.3 / steal Grok R6 / declare BOARD_PASS / `pred=664` as this gate PASS.

## Scientific frame

- **OBSERVATION:** UART-SKEW **SKEW** — printed `4` then `0` `0` is not same-cycle. Stub has no same-cycle `4,0,0`.
- **UNKNOWN:** at first core-clock `dbg_tile_dst==D_WAITDONE(4) && wdma_owner`, what is the packed occupancy (ATOM0) and the next-cycle pack (ATOM1)?
- **H_CANDIDATE:** ATOM0 has `dst=4, grant=0, idle=0` (real leftover occupancy).
- **H_RIVAL:** ATOM0 `dst=4, idle=1` (prior UART was skew; B1 may still work).
- **FALSIFIER:** serialize live TILE_DST/GRANT/IDLE as separate rows; force dest; C-FIX; A2.
- **UNIT:** one query; first dest=4∧owner snapshot + exactly one core cycle later.
- **CONTROL:** B-FIX sequential UART; UART-ENC FAITHFUL; UART-SKEW SKEW.
- **METRICS:** ATOM0/ATOM1 hex, decoded fields, class below. Gate PASS = rows captured and decoded. Existence PASS remains `pred=664`.

## Pack (preregistered, 32-bit hex, bits[31:11]=0)

| bits | field |
|------|--------|
| [2:0] | `dbg_tile_dst` |
| [3] | `wdma_owner` |
| [4] | `wdma_owner_grant` |
| [5] | `r_path_idle` |
| [6] | `r_drain_hold` |
| [7] | `fifo_cnt!=0` |
| [8] | `m_axi_rvalid` (`c_rvalid`) |
| [9] | `tr_cnt!=0` |
| [10] | `mgo_sticky` (`wdma_dbg_mgo`) |

All listed wires must be **core_clk**. Hierarchical READ of `u_ab` SOA bridge AND terms is allowed. Sync or omit any UI-domain bit.

Print **only** frozen rows (other boot lines OK):

```text
ATOM0=<8 hex>
ATOM1=<8 hex>
```

## Trigger

First core cycle: `dbg_tile_dst==3'd4 && wdma_owner` → latch ATOM0.  
Next core cycle → latch ATOM1. Do not update again.

If dest=4 never occurs: print `ATOM0=NONE` / `ATOM1=NONE` and classify **NO_DST4**.

## Class (exactly one)

| Class | Decode |
|-------|--------|
| `OCC_400` | ATOM0 or ATOM1: dst=4, grant=0, idle=0 — name idle constituents (ONE vs SET). No auto B1 bypass. |
| `SKEW_IDLE1` | dst=4, idle=1, ATOM1 grant=1 — prior UART was skew; B1 working. |
| `GRANT_STUCK` | dst=4, idle=1, ATOM1 grant=0 — grant FF/wiring; A2 may later be justified, **do not apply A2**. |
| `NO_DST4` | no atomic dst=4 |
| `SET` | dest=4 idle=0 and >1 constituent high |

## RTL / build

Board worktree only. Exclusive tcl (copy B-FIX excl style). Probe-only delta in `arty_a7_ng_native_v1_ab_soc_top.sv` UART/latch. WNS>=0 TNS=0. Archive bit SHA. Do not overwrite frozen LM-06 bits.

## Done

`CLOSEOUT.md` with ATOM0/ATOM1, decode table, class, SHA256, `BOARD_PASS: not claimed`, `EXISTENCE: not claimed`.
