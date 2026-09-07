# RESULTS — U6B-BOARD-PHYSICAL-SUBSTRATE-SMOKE-00

```text
RESULT                   = PASS
PHYSICAL_SUBSTRATE       = PROVEN_FOR_TESTED_PATH
U5Q                      = STILL FAIL
U7A                      = STILL CLOSED
GATE14_PASS              = NO
BOARD_PASS               = not_claimed
ORACLE_RETARGET          = NO
```

## Pin

```text
BIT_SHA256 = 1F0F2ABBA1D2A4DEFBC27547E2FCEEA2186458BE89E569AD7CC08BCE9A2FF4B9
JTAG       = 210319BE776EA  xc7a100t_0
UART       = COM12 @ 115200
PROGRAM    = ONCE this gate (SRAM reload of frozen bit)
C0         = 34314347C00114A7
GEN        = 1
n_frames   = 36
```

## Observed (not oracle)

After legal EXAM_QUERY, C9 pack `2322832182208180` appeared (CONTRA-shaped pack,
**not** graded against HOLD_A 653). C10 `out=0` (mode=5, not exam-mode 8).
UART still decoded STATUS after the query.

## In this bit / not in this bit

Proven path: MIG/DDR boot, UART CFRAME, reset/GEN, STATUS backpressure,
C9 pack / C10 fields toggling on the **Gate14 native v1** SoC.

Not in artifact: U6 AXI sparse walker, 20-bit posting IDs, U6 LUT materializer,
U5 retrieval overflow. CDC live ILA = not this smoke (`BIT_REPORT_ONLY`).
