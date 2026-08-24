# A7-EAM-01R-B — randomized silicon close

**Status:** `A7EAM01RB_PASS` — multi-index **router** closed on board.  
**Bit:** `build/out/arty_a7_eam01r.bit` SHA `57D1DF1B…0E9EF6CF`  
**Port:** COM12. Oracle: exhaustive Hamming NN on the 32 stored keys.  
**Keys:** `secrets` 64-bit, pairwise `d≥24`. Host never sends way / addr / match.

| Gate | Result |
|------|--------|
| PING `R1R` | pass |
| 32 MAP miss | pass |
| 32 exact HIT `d=0` token | pass |
| 16× set-byte 1-flip HIT `d=1` | pass (**00G disease gone**) |
| 16× 8-in-one-byte HIT `d=8` | pass |
| 16× 1-per-byte (radius-1 theorem) HIT `d=8` | pass |
| 16× 2-per-byte `d=16` reject | pass |
| 32 unrelated FP | **0** |
| Oracle disagree inside `d≤8` ball | **0** |
| Index overflow | 0 |

LM-00 / 05 / 06 C3 / 00B hashes unchanged.

Outside the MIH ball FPGA may report `best=64` while exhaustive still sees `d~20`. That is the theorem, not a miss-compare. First script revision wrongly required those to match; the close uses in-ball agreement only.
