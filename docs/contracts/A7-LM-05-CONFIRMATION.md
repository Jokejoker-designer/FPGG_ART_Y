# A7-LM-05 — registered confirmation (depth, not 8-class CE)

**Status:** `BOARD_PASS / FROZEN`  
**Frozen recipe:** same gates as `docs/contracts/A7-LM-05.md` plus exact host-compare to the compact-act xsim / `TinyGPT399k` oracle published before the C02 program.  
**law_id:** `lm05-signsgd-v1`  
**Geometry:** V=512 C=64 d=96 L=4 H=4 d_ff=192 P=399360

This confirmation is **not** an 8-way retrieval task and is **not** a 5% CE close. LM-05 is depth/traffic. R4 remains the sealed negative result for unguarded 8-class retrieval.

## Registered recipe (host compares only)

```text
seed:           2
context:        [1]
target:         32
lr:             3
opcodes:        K257 → K511 → K513 (one issue each), upload 399360,
                fold, one-full 0x34, fold, persist flush/reload, AFTER
retry:          forbidden
host compute:   forbidden (compare only)
```

| Check | Expected (xsim / python, before C02 program) |
|-------|-----------------------------------------------|
| fold0 | xor=248 add=46987446 wr_n=0 |
| one_full | pred=5 loss=16 wr_n=344256 |
| fold1 | xor=243 add=46931969 wr_n=344256 |
| four layers | each layer start byte-line changes and matches oracle after |
| persist 399360 | flush+reload ok; reload fold = fold1 |
| AFTER | wr_n unchanged |
| K257/511/513 | first_try, fold exact vs tensor oracle |
| timing | WNS≥0 TNS=0 to close; WNS≥+0.20 authorizes LM-06 |

Collapse/CE class-fraction gates from the LM-05 contract apply **only if** a retrieval task is used. This close does not use one.

## One-shot silicon — C02 2026-08-18

| Item | Value |
|------|--------|
| bit | `build/out/arty_a7_lm05.bit` |
| SHA-256 | `1AA0B5C481B0ADF3CAA599F081B430AF3C28A26FB4715DC56A0D25D940548F51` |
| WNS / TNS / WHS | +0.332 / 0 / +0.028 ns |
| ladder | `results/A7-LM-05/hardware_candidate_02/ladder.json` |
| ladder SHA-256 | `49FF0BD565928670E7A697F53FFBC1AA5FBEE7DDEA3F8DBC4C8DE7619395CC81` |
| `hardware_pass` | true — every registered gate true |

C00 (`FAIL_UPLOAD`) and C01 (`FAIL_FOLD0`) stay on disk. Do not reuse those bits for this claim.
