# E2R-HB-SOA-AXI-00 CLOSEOUT

**Date:** 2026-08-25  
**Worktree:** `arty-a7-online-lm-board` ONLY  
**Agent:** a7-vivado-gate  
**Parent decision:** HUMAN **D1** confirmed (mid-query SOA/AXI sticky after A+ `Q_GO`)

## ONE UNKNOWN (answered)

Why does query SOA never assert `soa_done` after `Q_GO`?

**AR fires after Q_GO; R never handshakes (`R_BEAT` absent). Hang class = AXI/MIG R-path.**

## Heartbeats (COM12 @ 115200, 180 s, listener armed before program)

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

| Stage | Seen? |
|-------|-------|
| BOOT | YES |
| MIG_OK | YES |
| WMEM_OK | YES |
| SOA_OK | YES |
| CORE_START | YES |
| OWNER_RDY | YES |
| Q_GO | YES |
| SOA_RUN | YES |
| AR_BEAT | YES |
| R_BEAT | **NO** |
| R_BUSY | YES |
| R_IDLE | YES |
| SOA_Q | **NO** |
| TOPK | **NO** |
| ACCEPT | **NO** |
| PACK | **NO** |
| BIND | **NO** |
| FWD | **NO** |
| LM | **NO** |
| `NATIVE_V1_EXIST_ROW,pred=` | **NO** |

**LAST_STAGE:** `R_IDLE`  
**STALL_CLASS:** `AXI_MIG_R_PATH` (AR fires, R never)  
**pred:** none  
**BYTES:** 83  

Note: early `capture_uart_hb.py` substring parse falsely listed `R_BEAT` inside `AR_BEAT`; line-exact parse of `uart_capture.txt` confirms **no** `R_BEAT` line. Script fixed to line-exact.

## Rebuild gates (post-route) — no rebuild this turn

| Metric | Value | Gate | Verdict |
|--------|-------|------|---------|
| core_clk WNS | **+10.881 ns** | ≥0 | **PASS** |
| core_clk TNS | 0 | =0 | **PASS** |
| ui (clk_pll_i) WNS | **+1.885 ns** | ≥0 | **PASS** |
| ui TNS | 0 | =0 | **PASS** |
| unsafe user CDC | **0** | =0 | **PASS** |
| RAMB36 | **104** | ≤135 | **PASS** |
| SIM_FULL | 0 | =0 | **PASS** |
| F2 decimal pred format | kept | — | **PASS** |

**Bit SHA256:** `D2CF44C66AEB6086FE25F669126A7C4B85FEE66C4CBEC8A4B9B8D37E60BD255C`  
**JTAG program:** **PASS** `210319BE776EA` (listener armed first)  
**Flash @ 0x400000:** unchanged  
**B1 `r_path_idle` interlock:** **NOT applied**

## Verdict

| Gate | Verdict |
|------|---------|
| D1 HB rebuild (timing/CDC/BRAM/bit) | **PASS** (prior; not re-run) |
| D1 localize | **PASS** — LAST_STAGE=`R_IDLE`, class=`AXI_MIG_R_PATH` |
| Gate 4 existence (`pred=664`) | **FAIL** — no SOA_Q / BIND / pred |
| `NATIVE_V1_EXISTENCE_BOARD_PASS` | **NOT claimed** |

## Interpretation

- Boot + ownership + query start still healthy through `Q_GO`.
- `SOA_RUN` → wavefront/`soa_running` asserts after start.
- `AR_BEAT` → ≥1 AR handshake after Q_GO (start/command path **not** the stall).
- **No `R_BEAT`** → AXI/MIG R data path never completes a beat after Q_GO.
- `R_BUSY` sticky → `r_path_idle` went **false** mid-query (non-idle observed).
- `R_IDLE` sticky → idle also observed (expected at Q_GO entry; does not contradict busy later).
- Hang is **R-path after AR**, not pre-start ownership, not STARTUPE2.

## DECIDE (next)

| Opt | Action |
|-----|--------|
| **D2** | B1 `r_path_idle` ownership/R-path interlock — **now PLAUSIBLE** (R_BUSY + AR + no R) |
| D3 | Deeper AXI/MIG R probe (RID/RVALID sticky, outstanding) without B1 yet |
| C | Pause Gate 4; human board bring-up |

**Recommendation:** **D2** only after human DECIDE — do not blind-patch B1 in this closeout.

## Forbidden not done

- No re-synth / rebuild this turn  
- No host weight poke  
- No STARTUPE2  
- No B1 patch without DECIDE  
- No R6 main tree  
- No self-claim full `NATIVE_V1_MINI_AI_BOARD_PASS` / existence PASS

## Artifacts

```
results/A7-NATIVE-GRAPH/E2R-HB-SOA-AXI-00/
  PREREGISTER.md
  CLOSEOUT.md (this file)
  e2r_metrics.txt
  BIT_SHA256.txt
  arty_a7_ng_native_v1_hb_soa_axi_00.bit
  uart_capture.txt
  uart_listen_stdout.txt
  bit_program.log
  vivado_build.log
  report_timing_summary.rpt
  report_cdc.rpt
  capture_uart_hb.py
  program via vivado/tcl/program_hb_soa_axi_00.tcl
```
