# NG-03 closeout — DDR shard + BRAM hotset

**Law:** `a7ng-hotset-v0`  
**Board:** Arty A7-100T Digilent AXI MIG  

## Gates

| Gate | Result | Class |
|------|--------|-------|
| Hotset XSim | **A7NG03_HOTSET_XSIM_PASS** | EVIDENCE |
| Shard+AXI model XSim | **A7NG03_SHARD_XSIM_PASS** (`bytes=32`, `hits=1`, `misses=2`, `cands=3`) | EVIDENCE |
| DDR map archived | `DDR_MAP.md` (`0x0100_0000` node base, 16 B/record) | EVIDENCE |
| MIG post-route | **WNS +1.166 / TNS 0**; LUT/FF/BRAM/DSP 4345/3716/0/0 | EVIDENCE |
| Bit | `build/out/arty_a7_ng03.bit` | EVIDENCE |
| SHA256 | see `SHA256.txt` / `manifest.json` | EVIDENCE |
| Silicon smoke | programmed via `xsdb` (LED: calib / seed_done / smoke_pass / hb) | EVIDENCE |
| Native V1 BOARD_PASS | **not claimed** | — |

## Not claimed

No full-graph scan. Host does not choose DDR address. AI does not declare BOARD_PASS.
