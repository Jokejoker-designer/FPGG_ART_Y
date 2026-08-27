# E2R F1u CLOSEOUT — E2R-DDR-TILE-DMA-FSM-PROBE-00 (RECAPTURE-2)

**Date:** 2026-08-27  
**Agent:** a7-vivado-gate  
**Gate:** E2R-DDR-TILE-DMA-FSM-PROBE-00  
**Session:** F1u-RECAPTURE-2 (user confirmed board connected)

## ONE CHANGE

DDR tile DMA FSM probes on UART after TILE_MISS: `DMA_ST` (ddr_tile_dma FSM), `SGO` (dma_go sticky), plus existing `TILE_DST`/`TILE_BST`/`SDONE`/`MDONE`/`BUSY_HOLD` chain.

## GATE (build — no rebuild this session)

| Metric | Value | Verdict |
|--------|-------|---------|
| WNS (core) | 8.956 ns | **PASS** (≥0) |
| TNS (core) | 0 | **PASS** |
| WNS (ui) | 2.664 ns | **PASS** |
| unsafe_cdc | 0 | **PASS** |
| RAMB36 | 103 | **PASS** (≤135) |
| DSP | 19 | note |
| gate_pass | 1 | **PASS** |

## BIT / PROGRAM

| Item | Value |
|------|-------|
| BIT_SHA256 | `7BE7C691FC5860DAD0C0FDB124339EA1F688BDCE3E2126AACAE4B8ED03329583` |
| JTAG | `210319BE776EA` |
| COM | COM12 @115200 |
| PROGRAM (RECAPTURE-2) | **PASS** (`DDR_TILE_DMA_FSM_PROBE_BIT_PROGRAM_PASS`) |
| REBUILD | **NO** (frozen bit) |

## UART capture (RECAPTURE-2)

| Item | Value |
|------|-------|
| Capture arm | 1st attempt **FAIL** (COM12 access denied — port held at arm time) |
| Retry | capture only, no reprogram |
| Duration | ~31 s (early stop; 1060 bytes, 2 telemetry cycles) |
| RESET note | not required — bytes received on retry |

### Probe table (board)

| Marker | Value | Decode / note |
|--------|-------|---------------|
| TILE_MISS | **YES** | weight miss stuck |
| TILE_DST | **4** | dma `dbg_dst` = `D_WAITDONE` |
| TILE_BST | **4** | bank `dbg_bst` = `B_REQ` |
| TILE_REQ | **1** | req asserted |
| SDMA_BUSY | **0** | |
| WDMA_BUSY | **1** | |
| WDMA_OWN_UI | **0** | |
| TILE_DMA_BUSY | **1** | |
| TILE_DMA_OWN | **1** | |
| SDONE | **0** | sdone not seen |
| MDONE | **1** | mdone latched |
| BUSY_HOLD | **1** | busy hold active |
| DMA_ST | **0** | ddr_tile_dma FSM = **IDLE** |
| SGO | **0** | dma_go never stuck high |
| W_STALL | **YES** | |
| PHASE | **01** | ST_EMB |
| CORE_BUSY | **YES** | |
| pred | **NO** | no `pred=` line |
| BYTES | 1060 | |

### FSM decode

**Bank bst (`weight_tile803k`):** 0=IDLE 1=FILL 2=FWAIT 3=FCAP **4=REQ** 5=WAITACK 6=STORE 7=SWAIT 8=NEXT  
**DMA dst (`weight_tile_dma` dbg_dst):** 0=IDLE 1=GO 2=FEED 3=DRAIN **4=WAITDONE** 5=ACK  
**DDR tile DMA (`dma_st` probe):** **0=IDLE** (never left IDLE despite TILE_DST=4 on parallel dbg_dst)

## Verdict

| Check | Result |
|-------|--------|
| PROBE_PASS | **YES** — `DMA_ST=` and `SGO=` lines on UART |
| EXISTENCE_PASS | **NO** — pred≠664 (no pred line) |

## Hypothesis (F1u)

| Hypothesis | Result |
|------------|--------|
| H_CANDIDATE (ddr_tile_dma never receives go / stuck IDLE) | **SUPPORTED** — `DMA_ST=0`, `SGO=0`, bank at `B_REQ`, `TILE_DST=4` |
| H_RIVAL (WDMA owns bus) | **PARTIAL** — `WDMA_BUSY=1`, `TILE_DMA_OWN=1`, `BUSY_HOLD=1` |
| FALSIFIER (DMA_ST≥1 or SGO=1) | **NOT MET** |

## Artifacts

- `arty_a7_ng_native_v1_ddr_tile_dma_fsm_probe_00.bit`
- `BIT_SHA256.txt`
- `uart_capture.txt`
- `capture_recapture2_stdout.log`
- `program_recapture2_stdout.log`
- `e2r_metrics.txt`

## NEXT

**F1v** — why `TILE_REQ=1` + bank `B_REQ` + `TILE_DST=WAITDONE` while ddr_tile_dma `DMA_ST` stays IDLE and `SGO=0` (req→go handshake / owner mux).
