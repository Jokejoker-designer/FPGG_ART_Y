# E2R-HB-UART-00 CLOSEOUT

**Date:** 2026-08-25  
**Worktree:** `arty-a7-online-lm-board` ONLY  
**Agent:** a7-vivado-gate  
**Parent decision:** Option **A** (early UART heartbeat)

## ONE UNKNOWN (answered)

Does early UART heartbeat appear on COM12 after reprogram, localizing where silicon hangs before pred?

**YES — hang is after `CORE_START`, before `BIND_DONE` / pred.**

## Heartbeats (COM12 @ 115200, 180 s, listener armed before program)

```
BOOT
MIG_OK
WMEM_OK
SOA_OK
CORE_START
```

(Sequence observed twice after JTAG program — no later stage.)

| Stage | Seen? |
|-------|-------|
| BOOT | YES |
| MIG_OK | YES |
| WMEM_OK | YES |
| SOA_OK | YES |
| CORE_START | YES |
| BIND_DONE | **NO** |
| LM_ACTIVE | **NO** |
| `NATIVE_V1_EXIST_ROW,pred=` | **NO** |

**Last heartbeat:** `CORE_START`  
**pred:** none  
**BYTES:** 76

## Rebuild gates (post-route, r3 paced UART)

| Metric | Value | Gate | Verdict |
|--------|-------|------|---------|
| core_clk WNS | **+6.870 ns** | ≥0 | **PASS** |
| core_clk TNS | 0 | =0 | **PASS** |
| ui (clk_pll_i) WNS | **+2.464 ns** | ≥0 | **PASS** |
| ui TNS | 0 | =0 | **PASS** |
| unsafe user CDC | **0** | =0 | **PASS** |
| RAMB36 | **104** | ≤135 | **PASS** |
| F2 decimal pred format | kept in RTL | — | **PASS** |

**Bit SHA256:** `261C0CA1E147F2AE37F85C08321430CE653E34E8DC0A425788B0C0442B05504F`  
**JTAG program:** **PASS** `210319BE776EA`  
**Flash @ 0x400000:** unchanged from T2 (not reprogrammed this gate)

## Build notes

| Rev | Result |
|-----|--------|
| r1 | `unsafe_cdc=1` (combo `core_live` before sync) → no bit |
| r2 | Gates PASS; UART NBA race dropped every other char (`BO`/`MGO`/…) but still showed progress through CORE |
| r3 | LOAD/WAIT_BUSY/WAIT_IDLE pace fix → clean ASCII heartbeats |

## Verdict

| Gate | Verdict |
|------|---------|
| HB rebuild (timing/CDC/BRAM/bit) | **PASS** |
| Option A localize | **PASS** — last stage `CORE_START` |
| Gate 4 existence (`pred=664`) | **FAIL** — no BIND / no pred |
| `NATIVE_V1_EXISTENCE_BOARD_PASS` | **NOT claimed** |

## DECIDE (next)

Hang is **post-core-start** (graph/bind/LM path), not MIG and not QSPI→DDR wmem load.

| Opt | Action |
|-----|--------|
| **B** | Retarget SCK to `STARTUPE2` USRCCLKO (flash path) — **lower priority now**; wmem already reached `WMEM_OK` |
| **A+** | Further A: heartbeat/LED on `owner_ready` / `soa_done` (query) / `final_accept` / `bind_done` inside core FSM — localize bind stall |
| **C** | Pause Gate 4; human board bring-up |

**Recommendation:** **A+** (finer post-`CORE_START` markers) before B — B is less indicated given `WMEM_OK`+`SOA_OK`.

## Forbidden not done

- No host weight poke  
- No self-claim full `NATIVE_V1_MINI_AI_BOARD_PASS`  
- B1 mux hazard not patched (PLAUSIBLE only)

## Artifacts

```
results/A7-NATIVE-GRAPH/E2R-HB-UART-00/
  PREREGISTER.md
  CLOSEOUT.md (this file)
  e2r_metrics.txt
  BIT_SHA256.txt
  arty_a7_ng_native_v1_hb_uart_00.bit
  uart_capture.txt
  uart_listen_stdout.txt
  uart_capture_r2_garbled.txt
  bit_program_r3.log
  vivado_build.log
  report_timing_summary.rpt
  report_cdc.rpt
```
