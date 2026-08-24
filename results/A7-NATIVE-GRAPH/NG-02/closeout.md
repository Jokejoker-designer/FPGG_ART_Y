# NG-02 closeout — Top-K + bucket frontier (integrated)

**Laws:** `a7ng-topk-v0`, `a7ng-frontier-v0` (on `a7ng-scorer-v0`)  
**Board:** Arty A7-100T @ 100 MHz  
**Evidence class:** XSim + post-route = **EVIDENCE**

## Gates

| Gate | Result |
|------|--------|
| Top-K XSim | **A7NG02_TOPK_XSIM_PASS** |
| Frontier XSim | **A7NG02_FRONTIER_XSIM_PASS** |
| Physical lanes | **16/16** |
| WNS / TNS | **+0.408 ns / 0** |
| Bit | `build/out/arty_a7_ng02.bit` |
| SHA256 | see `SHA256.txt` / `manifest.json` |

## Not claimed

No MIG DDR graph walk. No Native V1 BOARD_PASS. AI does not declare BOARD_PASS.
