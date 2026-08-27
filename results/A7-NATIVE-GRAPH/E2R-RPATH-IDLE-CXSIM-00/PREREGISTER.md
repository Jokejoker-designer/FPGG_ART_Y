# E2R-RPATH-IDLE-CXSIM-00 — PREREGISTER

**Date:** 2026-08-27  
**Worktree:** `D:/Jetking_sem4/SEM_4/arty-a7-online-lm-board`  
**Agent:** `a7-ng-xsim-verify`  
**Authority:** `results/A7-NATIVE-GRAPH/STATUS/E2R_CXSIM_DISPATCH.md` (main)  
**Preflight:** `results/A7-NATIVE-GRAPH/STATUS/MASTER_PREFLIGHT.md`  
**Class:** C-XSIM (unit XSim only)  
**Board:** NOT used. No COM12. No program. No bitstream Vivado. No `vivado.exe` impl writer.

## Scientific frame

| Field | Value |
|-------|-------|
| OBSERVATION | Silicon F1v/F1w/B2/B-FIX UART `RPATH_IDLE=0` `GRANT=0` at `TILE_DST=4`. Grant law in soc_top: `wdma_owner && r_path_idle`. |
| UNKNOWN | After one completed SOA-like AR/R drain (TILE_DST=4-equivalent dest-wait), which of `r_drain_hold`, `fifo_cnt!=0`, `m_axi_rvalid`, `tr_cnt!=0` keeps `r_path_idle=0`? |
| H_CANDIDATE | `r_drain_hold` stays 1 after `metric_clear` / SOA complete (OWN_CLEAR 1-cycle pulse then dest-wait). |
| H_RIVAL | Leftover `fifo_cnt`, leftover `tr_cnt`, or stuck `m_axi_rvalid`. |
| FALSIFIER | All four clear and `r_path_idle=1` after SOA-complete stimulus; **or** more than one wire independently holds idle=0 (STOP, name set, no C-FIX). |
| UNIT | One SOA-complete query-equivalent (one metric_clear + one AR burst fully returned and consumed), **not** a 100k-cycle farm. |
| CONTROL | Silicon `RPATH_IDLE=0` on BIT `6023D9A3…` / `4933B19B…`. XSim ≠ board. |
| METRICS | XSIM compile+run; four-wire snapshot; leave-one-dirty independence count; named `WIRE_THAT_HOLDS_IDLE_0`; `C_FIX_CONSTITUENT`. |

## DUT freeze (observation)

| Item | Value |
|------|-------|
| File | `rtl/native_graph/memory/a7ng_ddr_soa_axi_bridge.sv` |
| SHA256 | `40170C5C8A5D0DFC7FA400762918DE7A363256B047ABE0667E3248F4D697A7FB` |
| Idle law | `r_path_idle = !r_drain_hold && (fifo_cnt==0) && !m_axi_rvalid && (tr_cnt==0)` |
| Clear law | `metric_clear` sets `r_drain_hold<=1`, zeros fifo/tr; hold releases when `!m_axi_rvalid && fifo==0 && tr==0` |

## ONE CHANGE

New unit TB only: `tests/xsim/tb_e2r_rpath_idle_cxsim_00.sv`.  
Instantiate isolated `a7ng_ddr_soa_axi_bridge`. Hierarchical probe of the four constituents. Force/clear each wire one at a time.  
**No** product RTL edit. **No** `assign r_path_idle=1`. **No** grant bypass.

## Protocol (confirmatory; locked before run)

1. Reset; `m_axi_arready=1`; consumer `r_ready_i=1`; `m_axi_rvalid=0`. Expect idle=1 (reset CONTROL).
2. **Phase A (UNIT):** 1-cycle `metric_clear` (OWN_CLEAR stand-in). Wait ≤8 clk for hold release. Issue one AR (`len=3`, `size=4`, 4 beats). Return exactly 4 R beats with RLAST. Settle 16 clk (dest-wait stand-in). Snapshot four wires + idle.
3. **Phase B (H_CANDIDATE window):** 1-cycle `metric_clear` after Phase A. Settle 8 clk. Snapshot again.
4. **Phase C (law / force table):** From a forced-clean quad, dirty **exactly one** wire at a time (combo, no clock), record idle, then restore clean. Positive control that each term *can* hold idle=0.
5. If a snapshot has idle=0: **leave-one-dirty** — force the other three clean, observe whether idle stays 0. Count independent holders.

## Decision rule (do not rewrite after peeking)

| Snapshot result | `WIRE_THAT_HOLDS_IDLE_0` | `C_FIX_CONSTITUENT` |
|-----------------|--------------------------|---------------------|
| Idle=1, dirty_count=0 at A and B | `NONE` | `NONE` |
| Idle=0, exactly one independent dirty | that wire | that wire |
| Idle=0, independent count ≠ 1 | `AMBIGUOUS` | `NONE` |

Naming priority: Phase A (SOA-complete UNIT). If A is `NONE` and B has a unique leftover, B names the wire (H_CANDIDATE window). Phase C does not name C-FIX by itself.

- XSIM=PASS iff xvlog/xelab/xsim succeed and probes are recorded (including `NONE` / `AMBIGUOUS`).
- XSIM=FAIL iff compile/elab/run fails or probes are missing.
- No EXISTENCE. No BOARD_PASS. No `assign r_path_idle=1`.

## Interpretation (post-run; do not rewrite this table)

| Result | Favored |
|--------|---------|
| B unique leftover = `r_drain_hold` | H_CANDIDATE **supported** |
| A/B idle=1, all four clear | H_CANDIDATE **falsified** on isolated complete drain; H_RIVAL **not observed** |
| Unique leftover = fifo / tr / rvalid | H_RIVAL **supported**; H_CANDIDATE **falsified** |
| Independent count ≠ 1 | **STOP** — not unique, no C-FIX |
