# E2R F1v CLOSEOUT — E2R-WDMA-OWNER-GRANT-PROBE-00

**Date:** 2026-08-27  
**Agent:** a7-vivado-gate  
**Gate:** E2R-WDMA-OWNER-GRANT-PROBE-00  
**Session:** F1v-RESUME (build interrupted 07:51 → completed 08:22; program + UART)

## ONE CHANGE

UART probes for `wdma_owner`, `wdma_owner_grant`, `r_path_idle`, sticky `m_go` (msgs 61–64) at first TILE_DST=4 boot. Probe only.

## GATE (build — post-route)

| Metric | Value | Verdict |
|--------|-------|---------|
| WNS (core) | 8.119 ns | **PASS** (≥0) |
| TNS (core) | 0 | **PASS** |
| WNS (ui) | 1.326 ns | **PASS** |
| TNS (ui) | 0 | **PASS** |
| unsafe_cdc | 0 | **PASS** |
| RAMB36 | 103 | **PASS** (≤135) |
| u_ab RAMB36 (preplace) | 19 | **PASS** (≤120) |
| DSP | 19 | note |
| gate_pass | 1 | **PASS** |

## BIT / PROGRAM

| Item | Value |
|------|-------|
| BIT_SHA256 | `6DA35A623B185592D07DB19D82EEC2009F82E9DB77714C49AC9B1CC402E47534` |
| JTAG | `210319BE776EA` |
| COM | COM12 @115200 |
| PROGRAM | **PASS** (`WDMA_OWNER_GRANT_PROBE_BIT_PROGRAM_PASS`) |

## UART capture

| Item | Value |
|------|-------|
| Arm | capture armed before program (parallel build session); first-attempt stderr = COM12 access denied at program overlap |
| Authoritative | `capture_stdout.log` — full boot cycle then BOOT flood |
| Retry (no reprogram) | `uart_capture_retry.txt` — BOOT-only (no telemetry cycle) |

### Probe table (board — first boot cycle)

| Marker | Value | Decode / note |
|--------|-------|---------------|
| TILE_DST | **4** | D_WAITDONE (F1u control) |
| DMA_ST | **0** | ddr_tile_dma IDLE (F1u control) |
| SGO | **0** | dma_go never stuck (F1u control) |
| WDMA_OWNER | **1** | core wdma_owner latched |
| WDMA_GRANT | **0** | grant blocked |
| RPATH_IDLE | **0** | read path not idle → grant gate fails |
| MGO | **NO** | msg_sel was `[5:0]` — index 64 wraps to 0 (`BOOT`); RTL patched to `[6:0]` (rebuild pending) |
| WDMA_OWN_UI | **0** | mux owner not granted to tile DMA |
| TILE_DMA_OWN | **1** | tile side owns req |
| MDONE | **1** | |
| BUSY_HOLD | **1** | |
| TILE_REQ | **1** | |
| pred | **NO** | |

## Hypothesis (F1v)

| Hypothesis | Result |
|------------|--------|
| H_CANDIDATE (grant=0 because r_path_idle=0) | **SUPPORTED** — WDMA_OWNER=1, WDMA_GRANT=0, RPATH_IDLE=0 |
| H_RIVAL (m_go never pulsed) | **INCONCLUSIVE** — MGO line absent on UART |
| FALSIFIER (WDMA_GRANT=1 + MGO=1 but SGO=0) | **NOT MET** |

## Verdict

| Check | Result |
|-------|--------|
| PROBE_PASS | **NO** — MGO= line missing (3/4 F1v keys) |
| EXISTENCE_PASS | **NO** — pred≠664 |

## Artifacts

- `arty_a7_ng_native_v1_wdma_owner_grant_probe_00.bit`
- `BIT_SHA256.txt`
- `e2r_metrics.txt`
- `capture_stdout.log` / `uart_capture.txt`
- `program_stdout.log`
- `build_stdout.log`
- route/util/timing reports + DCPs

## NEXT

**F1w** — (1) rebuild with `msg_sel`/`nxt_sel` widened to `[6:0]` (fix applied in RTL); (2) trace why `r_path_idle=0` while WDMA_OWNER=1 at D_WAITDONE; target unblock `wdma_owner_grant` → `WDMA_OWN_UI`.
