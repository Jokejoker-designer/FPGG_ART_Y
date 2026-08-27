# E2R-HB-CORE-BIND-00 CLOSEOUT

**Date:** 2026-08-25  
**Worktree:** `arty-a7-online-lm-board` ONLY  
**Agent:** a7-vivado-gate  
**Parent decision:** HUMAN **A+** confirmed (finer post-`CORE_START` heartbeats)

## ONE UNKNOWN (answered)

Where between `CORE_START` and `BIND_DONE` does silicon stall?

**After `Q_GO`, before `SOA_Q` — query SOA wavefront never completes (`soa_done` sticky never asserts).**

## Heartbeats (COM12 @ 115200, 180 s, listener armed before program)

```
BOOT
MIG_OK
WMEM_OK
SOA_OK
CORE_START
OWNER_RDY
Q_GO
```

| Stage | Seen? |
|-------|-------|
| BOOT | YES |
| MIG_OK | YES |
| WMEM_OK | YES |
| SOA_OK | YES |
| CORE_START | YES |
| OWNER_RDY | YES |
| Q_GO | YES |
| SOA_Q | **NO** |
| TOPK | **NO** |
| ACCEPT | **NO** |
| PACK | **NO** |
| BIND | **NO** |
| FWD | **NO** |
| LM | **NO** |
| `NATIVE_V1_EXIST_ROW,pred=` | **NO** |

**LAST_STAGE:** `Q_GO`  
**pred:** none  
**BYTES:** 53

## Rebuild gates (post-route)

| Metric | Value | Gate | Verdict |
|--------|-------|------|---------|
| core_clk WNS | **+6.285 ns** | ≥0 | **PASS** |
| core_clk TNS | 0 | =0 | **PASS** |
| ui (clk_pll_i) WNS | **+2.068 ns** | ≥0 | **PASS** |
| ui TNS | 0 | =0 | **PASS** |
| unsafe user CDC | **0** | =0 | **PASS** |
| RAMB36 | **104** | ≤135 | **PASS** |
| SIM_FULL | 0 | =0 | **PASS** |
| F2 decimal pred format | kept | — | **PASS** |

**Bit SHA256:** `139526F78D390174002F60A4CBE1BBD9555F1992A85BFAD10FA8E83AD74A5EB5`  
**JTAG program:** **PASS** `210319BE776EA`  
**Flash @ 0x400000:** unchanged (not reprogrammed this gate)

## Verdict

| Gate | Verdict |
|------|---------|
| A+ HB rebuild (timing/CDC/BRAM/bit) | **PASS** |
| A+ localize | **PASS** — LAST_STAGE=`Q_GO` |
| Gate 4 existence (`pred=664`) | **FAIL** — no SOA_Q / BIND / pred |
| `NATIVE_V1_EXISTENCE_BOARD_PASS` | **NOT claimed** |

## Interpretation

- Boot path still healthy: `BOOT→MIG_OK→WMEM_OK→SOA_OK→CORE_START`.
- Dual-owner / `owner_ready` **clears** (`OWNER_RDY` seen) and query **starts** (`Q_GO` seen).
- Hang is **inside query SOA** (QS_WAIT_SOA waiting on `soa_done`) — AXI/DDR cue fetch or wavefront completion after start.
- **B1 `r_path_idle` ownership interlock:** **not applied** this turn — evidence does **not** show pre-start ownership stall (OWNER_RDY+Q_GO already). B1 remains PLAUSIBLE only if next probe ties SOA_Q stall to R-path hang mid-query.

## DECIDE (next)

| Opt | Action |
|-----|--------|
| **D1** | Probe query-SOA AXI/R-path: sticky on `soa_running`, AR/R beat counters, `r_path_idle` mid-query |
| **D2** | B1 `r_path_idle` interlock only if D1 shows R-path non-idle hang after Q_GO |
| **C** | Pause Gate 4; human board bring-up |

**Recommendation:** **D1** (finer mid-query SOA/AXI heartbeats) before B1 patch.

## Forbidden not done

- No host weight poke  
- No STARTUPE2 (B) — deferred; WMEM_OK already  
- No self-claim full `NATIVE_V1_MINI_AI_BOARD_PASS`  
- No B1 mux hazard patch without mid-query evidence  
- No R6 main tree  

## Artifacts

```
results/A7-NATIVE-GRAPH/E2R-HB-CORE-BIND-00/
  PREREGISTER.md
  CLOSEOUT.md (this file)
  e2r_metrics.txt
  BIT_SHA256.txt
  arty_a7_ng_native_v1_hb_core_bind_00.bit
  uart_capture.txt
  uart_listen_stdout.txt
  bit_program.log
  vivado_build.log
  report_timing_summary.rpt
  report_cdc.rpt
  capture_uart_hb.py
```
