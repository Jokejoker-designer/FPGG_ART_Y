# A7-LM-05 implementation plan

## Sequence (this is the plan)

| Step | What | Why |
|------|------|-----|
| **1** | 4-layer sequential core, bit-exact vs `TinyGPT399k` (xsim) | **DONE** `A7LM05_XSIM_PASS` |
| **2** | Tiled DDR W + smaller act | **RTL done.** Compact-act re-xsim PASS. Tile mode not xsim'd. See `A7-LM-05-TILE.md` |
| **3** | `arty_a7_lm05_top` + persist 399360 B | **RTL done.** Bit not built. |
| **4** | One-program silicon: fold / persist / K257→511→513 first try / AFTER | Reuse LM-04 tensor engine |
| **5** | Quality confirmation **later**, frozen before the run | Do not reuse unguarded 5% CE / 8-class last-token |

## BRAM budget (XC7A100T = 4860 Kbit)

| Image | Bits | Fits with MIG? |
|-------|-----:|----------------|
| W 399360 × 8 | 3195 K | alone yes |
| Act 65536 × 32 (LM-04 map) | 2097 K | **no**, with W |
| W + act 04-style | 5292 K | **no** |

Silicon W must be **DDR-tiled**. Step 1 may use a large sim RAM so the FSM matches the oracle.

## Not in this step

- Schedule search / R4 reopen
- Granting LM-04 `BOARD_VALIDATED`
- New `law_id`
- Board program (no `arty_a7_lm05.bit` yet)
