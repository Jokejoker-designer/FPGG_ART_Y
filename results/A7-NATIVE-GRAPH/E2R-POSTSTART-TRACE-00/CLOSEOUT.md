# E2R-POSTSTART-TRACE-00 CLOSEOUT

**Date:** 2026-08-27  
**Worktree:** `arty-a7-online-lm-board`  
**Gate:** locate first functional non-progress after silicon `CORE_START`  
**RTL this bag:** **none** (observe existing A+/D1/D3/F1* UART stickies; no pipeline edit)

## Verdict

| Claim | Result |
|-------|--------|
| This TRACE gate | **PASS** — first missing milestone identified |
| `NATIVE_V1_EXISTENCE_BOARD_PASS` | **NO** (`pred` absent) |
| BOARD_PASS / mini-AI | **not claimed** |
| Rebuild / reprogram this bag | **NO** |

**FIRST_MISSING_MILESTONE:** `BIND_DONE`  
**STALL_CLASS:** `LM` (TinyGPT forward / DDR weight-read)  
**STALL_SUBCLASS:** `W_STALL` + `SGO=0` (tile miss; DMA `s_go` never)  
**PRED_VALID:** **NO**  
**PRED_VALUE:** none  

## Honesty: which UART is authority

| Capture | Bit (short) | LAST | Use |
|---------|-------------|------|-----|
| E2R-HB-UART-00 r3 | `261C0CA1…5504F` | `CORE_START` | Coarse Option A only — **no** A+ stickies |
| E2R-HB-RVALID-00 | `889602B4…2E5ACF` | `OUTST` | Query AR, **no** `R_BEAT` |
| E2R-HB-MIG-AR-00 | `8E1E393D…1E05` | `OUTST` | `AR_BEAT=1`, `MIG_AR=0` (CDC/mux before MIG) |
| E2R-CDC-AR-FIX-00 | `678E3541…C039A8` | `CDC_S_ARR` | F1a **falsified**; `CDC_S_ARV` still NO |
| **E2R-LM-PHASE-PROBE-00 (F1n)** | `6EE273BB…4E11A6` | `PHASE=01` | **Richest query-path map** (used below) |
| E2R-WDMA-BFIX-00-EXCL | `6023D9A3…9D28A1` | CLASS B tail | Same hang: `SGO=0` `GRANT=0` `W_STALL` |

Observatory / older session “hang after CORE_START” was **HB-UART-00 coarse UART**, not “core never left reset.” Later bits with A+ stickies **did** leave `CORE_START`.

## Required sticky map (F1n board UART)

Raw: `results/A7-NATIVE-GRAPH/E2R-LM-PHASE-PROBE-00/uart_capture.txt`

| Required name | UART token on this SoC | Observed |
|---------------|------------------------|----------|
| CORE_CLK_ALIVE | (not a string; UART at 100 MHz) | **INFERRED** — heartbeats print |
| CORE_RST_RELEASED | (not a string) | **INFERRED** — `Q_GO` after `CORE_START` |
| QUERY_REQ | (not a string; `qs` START pulse) | **INFERRED** — `Q_GO` |
| QUERY_ACCEPT | `Q_GO` | **YES** |
| SOA_AR_FIRE | `AR_BEAT` | **YES** |
| SOA_R_FIRST | `R_BEAT` / `RV_SEEN` | **YES** (F1n only; earlier bits NO) |
| SOA_R_LAST | (no dedicated token) | **NOT NAMED** |
| SOA_BYTE_COUNT | (axi_bytes not printed this capture) | **NOT OBSERVED** — **cannot** claim 832 B |
| SOA_CANDIDATE_COUNT | (cand_delivered not printed) | **NOT OBSERVED** — **cannot** claim 64 |
| TOPK_START | (no separate token) | **INFERRED** — `TOPK` |
| TOPK_DONE | `TOPK` | **YES** |
| LATE_MAT_REQ | — | **N/A** — `a7ng_late_materialize` **not** in E2 SoC |
| LATE_MAT_DONE | — | **N/A** |
| BIND_START | `BIND_BUSY` | **YES** |
| BIND_DONE | `BIND` (`sticky_bind` ← `bind_done`) | **NO** ← **first missing required completion** |
| OWNER_READY | `OWNER_RDY` | **YES** |
| OWNER_SWITCH | (no token) | **N/A / not printed** — E2 uses `owner_ready` then query; not the blocked full GRAPH↔LM owner FSM |
| LM_REQ | `FWD` / `LM` | **YES** |
| LM_ACTIVE | `CORE_BUSY` `LM` `PHASE=01` | **YES** (embedding) |
| WMEM_RD_FIRST | `WDMA_BUSY` `W_STALL` | **YES** (tile stall) |
| WMEM_RD_COUNT | (not printed) | **NOT OBSERVED** |
| PRED_VALID | `PRED` / `CORE_DONE` | **NO** |
| PRED_VALUE | decimal `pred` | **NO** |

Boot `SOA_OK` is **WMEM/SOA preload**, not the 64-candidate query. **Not** used as SOA functional PASS.

## First non-progress (functional)

After `TOPK` / `ACCEPT` / `PACK`, `BIND_DONE` never asserts.  
`sticky_lm` can still rise on `core_busy` without `bind_done` (observe-only OR in SOC top — does not start LM by itself; TinyGPT `PHASE=01` + `W_STALL` is DUT).

Hang: **LM embedding, weight-tile stall**, DMA `s_go=0` (B-FIX UART).

```
STALL stage=BIND_DONE/LM_WMEM_RD core_marker=W_STALL,PHASE=01,SGO=0
```

No timeout counter on UART this bag (existing stickies only; FSM not mutated).

## Timing / fit (from bits already on silicon — not a new P&R)

| Bit | WNS | TNS | unsafe CDC | BRAM | Gate |
|-----|-----|-----|------------|------|------|
| F1n `6EE273BB…` | (prebuilt program; see that bag) | | | | used for map |
| B-FIX EXCL | **+0.616 ns** | **0** | **0** | **103** | PASS ≤135 |

This TRACE bag did **not** rebuild. Numbers above are archived post-route of those bits.

## DECIDE (STOP — do not implement here)

| If stall is… | Route | This silicon |
|--------------|-------|----------------|
| SOA transport | `ddr_cue_soa` AXI liveness **only** | **NO** — F1n has `R_BEAT` + `SOA_Q` |
| OWNER_READY / OWNER_SWITCH | audit E2 vs blocked full owner FSM; no silent bypass | **NO** — `OWNER_RDY` seen; query started |
| late materialize | board late-mat liveness only | **N/A** — module not in E2 topology |
| **LM** | **DDR weight-read / LM execution liveness only** | **YES** |
| PRED_VALID | record exact FPGA pred | **NO** — no pred |

**Next one unknown (not this gate):** why `SGO=0` after dest wait / `W_STALL` at `PHASE=01`.  
Only `pred=664` on UART may advance to the **human existence seal**.

## Forbidden (not done)

- No Option B / C  
- No R7 / WM ladder / teacher-off exam / perf  
- No frozen 01R/02M/TinyGPT/scorer/Top-K/bind/DDR/weight/PE edits  
- No host winner/address/next-token  
- No BOARD_PASS self-award  

## Artifacts

```
results/A7-NATIVE-GRAPH/E2R-POSTSTART-TRACE-00/
  PREREGISTER.md
  CLOSEOUT.md (this file)
Source UART:
  ../E2R-LM-PHASE-PROBE-00/uart_capture.txt
  ../E2R-WDMA-BFIX-00-EXCL/CLOSEOUT.md
```
