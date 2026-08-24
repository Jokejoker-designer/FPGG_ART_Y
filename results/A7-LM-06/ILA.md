# A7-LM-06 debug peek (not ChipScope ILA)

Vivado **BASIC** license rejects `create_debug_core` / ILA IP. Open Hardware Manager **will not** show `hw_ila_1` on this machine.

Instead the debug bit exposes the same 64-bit FSM bus over UART **0x58 → 0xA8**.

| File | Role |
|------|------|
| `build/out/arty_a7_lm06.bit` | **C1 locked** SHA `67C37DD51AED30F82B5B72EC9EF0736DDABA534ED1D724D0ADCAFD2B4282E3BA` — do not overwrite |
| `build/out/arty_a7_lm06c1_hw_partial.bit` | extra C1 copy (same SHA) |
| `build/out/arty_a7_lm06_ila.bit` | debug bit SHA `90889E00CA29302F3B292CA2FB19B0F52E9DA9DAAEEB11C82E1F8768845BFC1D` WNS **+0.211** TNS 0. **Not** for close |

Built 2026-08-19 `A7_LM06_ILA_BUILD_PASS`. C1 SHA re-checked before and after `write_bitstream`.

## Program + peek (does not touch C1)

```text
vivado -mode batch -source vivado/tcl/program_a7lm06_ila.tcl
python tools/a7lm06_ila_peek.py COM12 20 0.2
python tools/a7lm06_ila_hang_capture.py COM12
```

Hang snapshots go to `results/A7-LM-06/ila_hang/` — not `hardware_c1/`.

Then start reload (or the ladder). When it hangs, peek shows the frozen FSM.

Typical deadlock (hypothesis):

`p_busy=1` `persist_bst=STORE` `w_stall=1` `p_dma_owner=1` `wdma_owner=0` `tile_req=1` `tile_bst≠IDLE`

Silicon mid-reload on this debug bit (`ila_hang/capture.json`):

`persist_bst=STORE` `persist_dst=IDLE` `p_dma_owner=0` `w_stall=1` `tile_bst=REQ` `tile_rg=HEAD` `tile_miss=1` `mem_addr=0`

Reload writes TOK while the tile is still parked on HEAD. Later peek: `persist_ch=6271` IDLE — this debug-bit pass finished. C1 hang remains the close record.

## Bit map (`dbg_ila`)

Same table as before (persist_bst [3:0] … mem_addr [63:44]). See `tools/a7lm06_ila_peek.py` `decode()`.
