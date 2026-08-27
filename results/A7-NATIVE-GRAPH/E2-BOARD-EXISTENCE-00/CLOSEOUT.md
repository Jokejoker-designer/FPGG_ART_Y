# CLOSEOUT — E2-BOARD-EXISTENCE-00

**Gate:** `native_v1_existence_board_parallel_00`  
**Worktree:** `D:\Jetking_sem4\SEM_4\arty-a7-online-lm-board`  
**Branch:** `native-v1-board-lane-stage0`  
**Evidence class:** `BOARD_UART_EXISTENCE`  
**Verdict:** **FAIL** (narrow existence — not `NATIVE_V1_MINI_AI_BOARD_PASS`)

## Scientific frame

| Field | Value |
|-------|-------|
| OBSERVATION | Stage A XSim PASS pred=664; E1 OOC SIM_FULL=0 BRAM 96 WNS +3.648 ns @ 80 ns |
| UNKNOWN | On programmed Arty, does Native evidence → LM06 → FPGA pred with host_next_token=0? |
| H_CANDIDATE | Board SoC @ E1 lineage reproduces pred=664 on silicon |
| H_RIVAL | Host leak; LM06 inactive; integrated timing fail; missing DDR weights (SIM_FULL=0) |
| FALSIFIER | pred≠664 OR host counters nonzero OR LM06 inactive |
| OUTCOME | **H_RIVAL partially confirmed** — bit programs, UART silent, pred not observed |

## Build attempts

| Attempt | Core generic | Result |
|---------|--------------|--------|
| R1 | SIM_FULL=1 + BOARD_EXISTENCE wmem init | **FAIL place** — RAMB36 320/135 |
| R2 | SIM_FULL=0 + wdma + SOA boot | **Bit generated** — BRAM 96/135; **WNS −40.339 ns** on `clk_pll_i` |

## E1 lineage (reference)

| Item | Value |
|------|--------|
| E1 DCP | `E1-AB-COFIT-PARALLEL-00-CLOCK80/ab_post_route.dcp` |
| E1 DCP SHA256 | `92A27DF729039D60BD18704F7B857FB62CA54AA331B2244F331FC8CB35F358EA` |
| E1 WNS @ 80 ns OOC | +3.648 ns |

## R2 integrated metrics (post-route)

| Metric | Measured | Gate | Verdict |
|--------|----------|------|---------|
| RAMB36 | 96 | ≤ 135 | **PASS** |
| DSP48 | 19 | 0 preferred | informational |
| WNS (design summary) | **−40.339 ns** | ≥ 0 | **FAIL** |
| TNS | −349759 ns | 0 | **FAIL** |
| WHS | +0.019 ns | report | OK |
| THS | 0 | report | OK |
| Bitstream | generated | required | **PASS** |

## Board program

| Item | Value |
|------|--------|
| JTAG target | `localhost:3121/xilinx_tcf/Digilent/210319BE776EA` |
| Part | `xc7a100t_0` |
| Bit SHA256 | `EF8FA31226D00450C9173D6DAAD71FDB62005CE6D0BBF791A370A096AD112084` |
| Program marker | `NATIVE_V1_EXISTENCE_00_PROGRAM_PASS` |
| COM12 | present; 45 s + 30 s capture |

## UART / existence counters

| Metric | Required | Observed |
|--------|----------|----------|
| pred | 664 | **null** (no bytes) |
| host_next_token | 0 | 0 (host did not inject) |
| teacher_api_calls | 0 | 0 |
| learn | 0 | 0 |
| freeze | 1 | 1 (host script policy) |
| actual_lm06_active | 1 | **0** (no bind telemetry) |
| fpga_next_token_valid | >0 | **0** |
| Raw UART | non-empty | **0 bytes** |

**Marker:** not issued (`NATIVE_V1_EXISTENCE_BOARD_PASS` requires pred=664)

## Root causes (ranked)

1. **Integrated timing:** ui_clk domain WNS −40 ns vs E1 OOC +3.6 ns @ 80 ns — full SoC + MIG does not close at MIG ui_clk (~83 MHz).
2. **Weight path:** SIM_FULL=0 tile needs DDR weights @ `DDR_WBASE`; R2 boot loads SOA only — LM forward cannot reach pred=664 without DDR wmem preload engineering.
3. **R1 BRAM:** SIM_FULL=1 integrated needs ~320 RAMB36 (weight_bram803k) — exceeds Artix-100T.

## LIMIT (not full BOARD_PASS)

- SoC shell + MIG + SOA boot + ab_core integrate **fits BRAM** at SIM_FULL=0.
- Bitstream programs on pinned Digilent target.
- Existence pred **not evidenced** on silicon this run.

## Artifacts

```text
results/A7-NATIVE-GRAPH/E2-BOARD-EXISTENCE-00/PREREGISTER.md
results/A7-NATIVE-GRAPH/E2-BOARD-EXISTENCE-00/arty_a7_ng_native_v1_existence_00.bit
results/A7-NATIVE-GRAPH/E2-BOARD-EXISTENCE-00/e2_post_route.dcp
results/A7-NATIVE-GRAPH/E2-BOARD-EXISTENCE-00/e2_timing_route.rpt
results/A7-NATIVE-GRAPH/E2-BOARD-EXISTENCE-00/e2_util_route.rpt
results/A7-NATIVE-GRAPH/E2-BOARD-EXISTENCE-00/e2_postroute_metrics.txt
results/A7-NATIVE-GRAPH/E2-BOARD-EXISTENCE-00/board_uart_capture.txt
results/A7-NATIVE-GRAPH/E2-BOARD-EXISTENCE-00/board_uart_capture.json
results/A7-NATIVE-GRAPH/E2-BOARD-EXISTENCE-00/COMMANDS.txt
results/A7-NATIVE-GRAPH/E2-BOARD-EXISTENCE-00/RESULTS.md
rtl/board/arty_a7_ng_native_v1_ab_soc_top.sv
vivado/tcl/build_native_v1_e2_board_12p5mhz.tcl
vivado/tcl/program_native_v1_existence_00.tcl
```

**Date:** 2026-08-25
