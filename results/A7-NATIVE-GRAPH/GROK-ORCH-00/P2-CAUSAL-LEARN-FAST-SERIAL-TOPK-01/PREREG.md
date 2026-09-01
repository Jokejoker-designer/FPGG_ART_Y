# P2-CAUSAL-LEARN-FAST-SERIAL-TOPK-01 — preregistration (before data)

**PROGRAM=NO.** One unknown: can sequential candidate scan + iterative Top-8 (minheap comparator law) replace the FAST-00 combinational 8-sort, keep four-arm C3/C7/C9 bit-exact, and close OOC LUT<=800 FF<=800 BRAM/DSP=0 WNS/TNS/WHS/THS clean?

Do **not** open G4. Do **not** instantiate full-chip `a7ng_topk` / `a7ng_topk_stream_minheap`. Do **not** modify G1/G2 sources.

Parent FAST-00: PASS_FUNCTIONAL / FAIL_PHYSICAL (LUT=3869 WNS=-2.277). Preserve that bag.

| Frozen | SHA256 |
|---|---|
| G1 resolver | `2219DA29C265D2461ED30783EBEA0F0649050B9B6E5F6EAFDB8F1C4E05F3F5F7` |
| G2 delta | `0614386298F31DC6A5EB456959290F9C6ADDC899FBF91F8CD49BB5A3D2BBA800` |

Four-arm oracle unchanged: pos up, neg down, unrel unchanged, contra down. Host reward-only.
