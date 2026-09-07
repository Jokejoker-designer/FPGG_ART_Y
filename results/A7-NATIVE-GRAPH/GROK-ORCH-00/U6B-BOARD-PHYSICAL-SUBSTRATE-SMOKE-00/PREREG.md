# PREREG — U6B-BOARD-PHYSICAL-SUBSTRATE-SMOKE-00

Physical checkpoint of the **current V3.1 board artifact**. Not U5Q. Not U7A.

```text
GATE                     = U6B-BOARD-PHYSICAL-SUBSTRATE-SMOKE-00
BASE                     = 3e2e784274383fe7c79c481d957511c8dfb394dd
BIT                      = arty_a7_ng_native_v1_g14_epoch_rebirth_00.bit
BIT_SHA256               = 1F0F2ABBA1D2A4DEFBC27547E2FCEEA2186458BE89E569AD7CC08BCE9A2FF4B9
JTAG                     = 210319BE776EA  xc7a100t_0
UART                     = COM12 @ 115200
PROGRAM                  = ONCE this gate (reload frozen SRAM bit; no new impl)
REBUILD                  = NO
RTL_EDIT                 = NO
ORACLE_RETARGET          = NO
GATE14_PASS              = NO
BOARD_PASS               = not_claimed
U5Q                      = STILL FAIL
U6_XSIM                  = RETAINED (not this silicon)
U6_PROMOTION_STATUS      = CONDITIONAL_ON_U5Q
U7A                      = CLOSED
R2A                      = CLOSED until after this gate
R2B                      = CLOSED until after this gate
```

## DUT honesty

This bit is Gate14 epoch-rebirth native v1 (`commit 9656245` lineage).

**In the bit:** MIG/DDR persist boot, AXI MIG, UART CFRAME, CDC of that SoC,
reset, C9 pack / C10 OUT, learned-graph candidate path, scorer/Top-K as wired
in `a7ng_native_v1_ab_core`.

**Not in the bit:** `a7ng_unified_retrieval`, AXI sparse directory walker as
U6 owner, 20-bit posting IDs, U6 record LUT materializer, U5 retrieval overflow.

U6 20-bit AXI path remains **XSim-only**. U6B must not claim it.

## PASS (tested path only)

1. Bit SHA is exactly `1F0F2ABB…`. Refuse 3A7EF204 / 7ECCA0E2 / A0B338E0 / B0F64E6C.
2. JTAG is Arty A7 `210319BE776EA`, not PYNQ.
3. Program DONE (this gate's one reload).
4. UART COM12: CFRAME CRC-valid stream after program.
5. C0 boot id `34314347C00114A7`.
6. C8 GEN legal (not 0, not `FFFFFFFF`, ≤ WRAP_LIMIT=6).
7. CMD_STATUS round-trip after boot (no UART lockup).
8. One legal EXAM_QUERY: C9 and/or C10 appear (datapath toggled). Values are
   **OBSERVED**, not an oracle pass.

CDC: live ILA not in this smoke. Classify from existing bit CDC report =
`BIT_REPORT_ONLY`.

Overflow/backpressure: STATUS after query still decodes. Retrieval overflow
telemetry **NOT_IN_ARTIFACT**.

## FAIL classes (first applicable)

BOARD_NOT_ATTACHED, JTAG_MISS, PYNQ, SHA_REFUSE, PROGRAM_FAIL,
UART_DEAD, C0_MISS, GEN_ILLEGAL, UART_LOCKUP, HOST_SEMANTIC_LEAK

## After PASS claim only

`PHYSICAL_SUBSTRATE = PROVEN_FOR_TESTED_PATH`

Still: U5Q=FAIL, U7A=CLOSED, GATE14_PASS=NO, no U6 silicon retrieval claim.
