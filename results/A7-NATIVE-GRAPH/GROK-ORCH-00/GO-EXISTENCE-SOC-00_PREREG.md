# GO-EXISTENCE-SOC-00 — PREREGISTER (grok-orch-00)

**PROGRAM:** NO until a **new** `com12_authorized_gate` names `research/native-ai-v1-grok-orch-00`.  
**JTAG:** NO this gate. **QSTAR on SoC:** NO. **Cursor CWD:** NO.

## One unknown

Can **this checkout** produce a bitstream of `arty_a7_ng_native_v1_ab_soc_top` with WNS≥0 TNS=0 BRAM36≤135, SHA-pinned to the six sealed fence files?

Not UART `pred=664`. Not BOARD_PASS. Not leftover LONGBOOT/two-pass program.

## CONTROL (product SHA, this tree 2026-08-30)

| File | SHA256 |
|------|--------|
| `rtl/board/a7ng_wdma_cdc.sv` | `E951F1F37D9FE7353103860CA0185D74A1C6D12FB43348C07C91816B093AA582` |
| `rtl/board/arty_a7_ng_native_v1_ab_soc_top.sv` | `57BD7B4D94F160A082734CFFC4A508556CD45FB2A291C2EB9E0DEDFF99EC717F` |
| `rtl/lm/tiny_gpt803k_core.sv` | `355182A70E586B12C0F3EFA67D7A37971864D205660384199EF8AF75228F3DD7` |
| `rtl/ddr/ddr_tile_dma.sv` | `20BAE36ECCB6C94C2C5C9635D5FB7F771F09539E252316CC75D8F723810AD7C5` |
| `rtl/lm/weight_tile803k.sv` | `A4E5FEACC29B1B69BF525915FECB81DEAEF7032A89035582AE513B23F432FCF1` |

If any SHA drifts, **STOP** — do not write a bit.

## Out paths (this bag only)

```text
results/A7-NATIVE-GRAPH/GROK-ORCH-00/GO-EXISTENCE-SOC-00/
build/go_existence_soc_00/     (scratch; not build/out)
arty_a7_ng_native_v1_grok_orch_existence_00.bit
```

Refuse: `close664`, `arty-a7-online-lm-board`, `build/out`, LONGBOOT names, `qstar_*` in srcs, `open_hw_manager`.

## Gates to write bitstream

WNS ≥ 0, TNS = 0, BRAM36 ≤ 135, route complete, candidate-logic CDC unsafe = 0 (clock-gen falsepath rows may exist). SIM_FULL=0. 12.5 MHz core.

## After BIT_OK

Do **not** program. Wait for human token naming this branch. Arm COM12 **before** `program_hw_devices` if/when that token exists.
