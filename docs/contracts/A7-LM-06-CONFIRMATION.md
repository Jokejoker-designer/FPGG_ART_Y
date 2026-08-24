# A7-LM-06 — registered confirmation (scale, not 8-class CE)

**Status:** `BOARD_PASS / FROZEN`  
**Frozen recipe:** 2026-08-18 **before** the board hardware ladder  
**law_id:** `lm06-signsgd-v1`  
**Geometry:** V=1024 C=128 d=128 L=4 H=4 d_ff=256 P=802816

Not an 8-way retrieval task. Not a 5% CE close.

## Frozen recipe (host compares only)

```text
seed:           2
context:        [1]
target:         32
lr:             3
opcodes:        K257 → K511 → K513 (one issue each), upload 802816,
                fold, one-full 0x34, fold, persist flush/reload, AFTER
retry:          forbidden
host compute:   forbidden
```

| Check | Expected (xsim `A7LM06_XSIM_PASS` / `TinyGPT803k`) |
|-------|-----------------------------------------------------|
| fold0 | xor=5 add=94638317 |
| one_full | pred=744 loss=16 wr_n=655616 |
| fold1 | xor=23 add=94627297 wr_n=655616 |
| four layers | each layer start line changes vs fold0 |
| persist 802816 | flush+reload ok; reload fold = fold1 |
| AFTER | wr_n unchanged |
| K257/511/513 | first_try |
| timing | WNS≥0 TNS=0 to close; WNS≥+0.20 authorizes LM-07 |

INT16 stored activations (`q_act` on every live tensor) are part of this law.

## One-shot silicon — C3 2026-08-19

| Item | Value |
|------|--------|
| bit | `build/out/arty_a7_lm06c3.bit` |
| SHA-256 | `222F804351261B5878D73E5501E4E34A28D330B09BB4BC3E1590EE79402884C6` |
| WNS / TNS / WHS | +0.359 / 0 / +0.031 ns |
| ladder | `results/A7-LM-06/hardware_c3/ladder.json` |
| ladder SHA-256 | `37A53A73ED551910F4F28E164749F86967B2B1B376B29027B859DA165E689B61` |
| `hardware_pass` | true — every registered gate true |

C0 (`FAIL_UPLOAD_TILE_STALL`), C1 (`FAIL persist_reload`), and C2 (`FAIL persist_flush` from `mem_sel`) stay on disk. Do not reuse those bits for this claim.
