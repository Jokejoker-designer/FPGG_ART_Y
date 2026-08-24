# A7-LM-03 BOARD PASS — 2026-08-17

25,088-param 2-layer / 2-head TinyGPT. FPGA-resident forward + full last-token update. Host compares only.

**Claim:** `ARTY_A7_25K_ONLINE_LM_BOARD_VALIDATED`

Not a general-purpose LLM. Not A7-LM-04. `law_id` remains `lm05-signsgd-v1`.

## Silicon

| | |
|--|--|
| Board | Digilent Arty A7-100T JTAG `210319BE776EA` / UART `210319BE776EB` |
| UART | COM12 115200, `CLK_HZ=50e6` |
| Bit | `arty_a7_lm03.bit` `C98B7C85814C8D4C57CA5E4ED1C9C411BC71EBF2991ABA1B210B9347509F23D1` |
| WNS / TNS | +0.312 / 0 (CLK100MHZ wrapper) |
| clk50 WNS | +3.307 ns |
| LUT / FF / BRAM / DSP | 8642 / 11650 / 32 / 21 |
| Frozen LM-00 | `449A330B…34783` unchanged |
| Frozen LM-01 | `96065A17…507B8` unchanged |
| Frozen LM-02 | `7CEBA854…95CC4` unchanged |
| Failed prior image | `8F7BE781…040ACD` (fold xor=2 add=2955722) snapshotted as `arty_a7_lm03_8F7B_signshift.bit` |

## Root cause that had kept the contract OPEN

RTL XSim matched the oracle. Silicon after the sign-shift bit did not: board fold xor=2 add=2955722 vs oracle xor=255 add=2943381, and not head-only (173 / 2962299). `wr_n=20544` proved the FSM did not skip. UART, upload, and timing were rejected.

Isolation:

1. `dHid` / `dY` / `dH` / `n1_last` / `a_last` forced `ram_style="registers"` (were RAMS64E).
2. `weight_bram25k` locked UG901 READ_FIRST, 1-cycle latency.
3. `0x31 → 0xA4` readback with explicit 3-clk BRAM wait.

Post-synth and post-route core funcsim then matched. Full-FPGA isolation bit one-full on board matched.

## Gates (conjunctive, all met)

| Gate | Result |
|------|--------|
| param count | 25,088 |
| `0x31` init spots 0/1/4096/4608/20992 | exact |
| forward `[1]→16` | pred=123 loss=16 (FPGA) |
| one-full fold vs `a7lm03_fixed_ref.py` | xor=255 add=2943381 wr=20544 |
| one-full ≠ head-only | head-only is 173 / 2962299 |
| corpus 8×24 fold vs same-init Python | xor=162 add=2976236 wr=806976 |
| CE drop (`ce_hw` from FPGA) | 128 → 64 = **50%** ≥ 30% |
| all banks (oracle `all_moved` + fold-exact) | true |
| AFTER | 0 additional writes |
| next-token | FPGA argmax (`0x3B` / status `pred`) |
| WNS | +0.312 |
| frozen 00/01/02 SHA | unchanged |

Evidence: `results/A7-LM-03/one_full_isolation.json`, `results/A7-LM-03/ladder.json`.

## Honest limits

- Host compares folds / CE pages only. It does not compute board CE, pred, or weight updates.
- `all_banks` on the ladder is oracle `all_moved` plus whole-image fold match, not a 25,088-byte UART dump.
- AFTER was proven by a second `0x34` with AFTER on; write counter did not increase.
- This is last-token / last-query attention, sign-SGD + head shift, STE LN. Not full-sequence backprop.
- 21 DSP is the sequential 25K datapath, not the 128-lane tensor engine.

## Next

Do **not** start A7-LM-04 until the user opens that contract. Frozen 00/01/02/03 bits must stay in place.
