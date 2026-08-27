# RESULTS — E2-BOARD-EXISTENCE-00

## Verdict

**FAIL** — programmed bitstream; **no UART pred=664**; integrated **WNS −40.339 ns**.

## Measured numbers

| Source | Metric | Value |
|--------|--------|-------|
| post-route | RAMB36 | 96 |
| post-route | LUT | 48542 / 63400 (76.56%) |
| post-route | FF | (see e2_util_route.rpt) |
| post-route | DSP48 | 19 |
| post-route | WNS | **−40.339 ns** |
| post-route | WHS | +0.019 ns |
| bitstream | SHA256 | `EF8FA31226D00450C9173D6DAAD71FDB62005CE6D0BBF791A370A096AD112084` |
| E1 control DCP | SHA256 | `92A27DF729039D60BD18704F7B857FB62CA54AA331B2244F331FC8CB35F358EA` |
| board | JTAG | `210319BE776EA` |
| board | pred | **not observed** |
| board | UART bytes | 0 |

## DCP lineage

| Stage | Artifact | SHA256 |
|-------|----------|--------|
| E1 OOC @ 80 ns | `ab_post_route.dcp` | `92A27DF729039D60BD18704F7B857FB62CA54AA331B2244F331FC8CB35F358EA` |
| E2 integrated SoC | `e2_post_route.dcp` | (see archive; distinct from E1 — full MIG shell) |
| E2 bit | `arty_a7_ng_native_v1_existence_00.bit` | `EF8FA31226D00450C9173D6DAAD71FDB62005CE6D0BBF791A370A096AD112084` |

## Next engineering (out of scope this gate)

1. DDR wmem preload for SIM_FULL=0 (802816 B @ `0x0010_0000`) without 320 BRAM on-chip ROM.
2. Integrated timing: run ab_core at **12.5 MHz** (`core_clk`) with AXI CDC to ui_clk, or re-prove OOC 80 ns constraint on integrated core clock net.
3. Do not claim `NATIVE_V1_EXISTENCE_BOARD_PASS` until UART shows pred=664 with counter hygiene.
