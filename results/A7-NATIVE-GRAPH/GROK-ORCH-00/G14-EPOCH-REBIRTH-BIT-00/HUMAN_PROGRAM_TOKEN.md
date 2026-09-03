# HUMAN PROGRAM TOKEN — G14-EPOCH-REBIRTH-BIT-00

```text
READY_TO_PROGRAM = YES
PROGRAM          = NO
```

Agent must not call `program_device` / `hw_server` program.

Board: Arty A7-100T `xc7a100tcsg324-1`  
JTAG: Digilent `210319BE776EA`  
UART: COM12 @ 115200  

Bit:

```text
arty_a7_ng_native_v1_g14_epoch_rebirth_00.bit
SHA256=1F0F2ABBA1D2A4DEFBC27547E2FCEEA2186458BE89E569AD7CC08BCE9A2FF4B9
```

Frozen oracle (do not retarget):

```text
HOLD_A C9=8382238122802120 OUT=653
UNREL  OUT=689
CONTRA OUT=237
HOLD_B OUT=60
```

Expect vs fail bit `3A7EF204`: boot C8 GEN ≠ `FFFFFFFF`; HOLD_A C9/OUT match oracle if epoch closed the dirty-DRAM path.

Program once. Capture UART GEN / commit_seq / C9 / OUT after CORE_DONE.
