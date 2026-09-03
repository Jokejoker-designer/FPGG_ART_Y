## What this PR is

Codex audit bag **E2R-CORE-START-RST-PROBE-00**: first silicon discriminator for UART BOOT×2 vs CORE_START hang.

Probe-only SoC UART bank. No frozen-oracle change. No second scorer/Top-K/LM.

**Do not merge** until a human reviews. GATE14_PASS / BOARD_PASS not claimed.

## Bit / silicon

- Unique bit `7ECCA0E2…` UART_SLIM=0 programmed **once** after DONE
- Capture `uart_raw.bin` 732 B, `before_done=0`, **one BOOT**, 180 s
- `Q_GO` + `CORE_DONE` — not stuck after CORE_START
- `n=01` CAUSE=0 — no lock-drop reboot on this SHA

## Files

- `rtl/board/arty_a7_ng_native_v1_ab_soc_top.sv` — sticky probe
- `vivado/tcl/build_e2r_core_start_rst_probe_00.tcl`
- `vivado/tcl/program_e2r_core_start_rst_probe_00.tcl`
- `results/A7-NATIVE-GRAPH/E2R-CORE-START-RST-PROBE-00/` — audit + UART + bit SHA

DCP omitted (size). Bit force-added for SHA replay.

## Related

Parent C9 HOLD_A 748: #1 / PR #2
