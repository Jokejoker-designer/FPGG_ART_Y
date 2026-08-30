# GLOBAL-TOPK-MINHEAP-BIT-01 — PREBUILD_READY

**PREBUILD_READY = YES.** **PROGRAM=NO** until a human token names this gate **and** this SHA.

| Field | Value |
|-------|--------|
| Bit | `arty_a7_ng_native_v1_grok_orch_minheap_01.bit` |
| SHA256 | `439CC42D9BA0B3780C384C47E6E7F0A886269929E3ED3667471F064A8A222A8D` |
| Size | 3826011 B (file match BIT_SHA256.txt) |
| WNS | **+0.416 ns** |
| TNS | 0 |
| WHS | **+0.018 ns** |
| THS | 0 |
| core_WNS | +3.288 |
| ui_WNS | +2.421 |
| RAMB36 | 103 |
| DSP | 19 |
| CDC candidate_logic | 2 (FINDING, not skip) |
| Place | success (BIT-00 was Place 30-487; BIT-01 used `opt_design -control_set_merge`) |
| `open_hw_manager` | not used |
| COM12 | not held |
| BOARD_PASS | not_claimed |

RTL: `poison_i=0` + min-heap `u_global`. A-FAST XSim `pred=664` Top-8 E0.

Refuse leftover: EC286E9E, 00517465, h2nopoison NO_BIT, BIT-00 NO_BIT.

After token: arm COM12 DTR/RTS false → JTAG `210319BE776EA` only → this SHA → UART `POISON=0` `TOPK=` `PACK=` `NATIVE_V1_EXIST_ROW,pred=`. Golden pack `3B392B291B190B09`. Existence only `pred=664`.
