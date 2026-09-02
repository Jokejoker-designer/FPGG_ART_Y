# P2-GATE14-BOARD-PROGRAM-20-R1-00 RESULTS

HUMAN_TOKEN_ACCEPTED. Arm UART first. Program once. No 40-fact.  
**TEACHER_OFF=not_claimed GATE14_PASS=not_claimed BOARD_PASS=not_claimed**

Previous `P2-GATE14-BOARD-PROGRAM-20-00` WAIT_HUMAN_RECONNECT bag **not overwritten**.

## C0 identity

```text
bit_path=D:\Jetking_sem4\SEM_4\arty-a7-online-lm-grok-orch-00\results\A7-NATIVE-GRAPH\GROK-ORCH-00\P2-WDMA-RELEASE-CDC-AUDIT-03\arty_a7_ng_native_v1_grok_orch_p2_wdma_release_cdc_audit_03.bit
BIT_SHA256=6975AB757FE592DBD0EAB68FBDC7463559A3712CAA9A8BD1E429C9A6BDF8B39A
bytes=3826011
jtag=localhost:3121/xilinx_tcf/Digilent/210319BE776EA
device=xc7a100t_0 part=xc7a100t
uart=COM12 baud=115200 dtr=0 rts=0
pnp=FTDIBUS\VID_0403+PID_6010+210319BE776EB\0000
ftdi_composite=USB\VID_0403&PID_6010\210319BE776E
program_count=1
```

## Program (EVIDENCE BOARD)

```text
PROGRAM_START=2026-09-02T23:57:59
PROGRAM_END=2026-09-02T23:58:17
startup=HIGH
refresh=ok
VIVADO_EXIT=0
lock=PROGRAMMED_ONCE.txt
```

UART listener confirmed alive (`LISTENER_ALIVE.txt`) before `program_hw_devices`. Same COM handle kept open (no close/reopen).

## Raw UART (EVIDENCE BOARD)

```text
uart_raw.bin SHA256=F015A1194F595EDBD593BBA69C99E71100765580E690BCC521A6B0C429CCCEE6
bytes=112
LISTEN_START=2026-09-02T23:56:40+07:00
stale_flush_bytes=0
```

```text
BOOT
MIG_OK
WMEM_OK
TOPK=3B392B291B190B09
PACK=3B392B291B190B09
POISON=0
CORE_DONE
NATIVE_V1_EXIST_ROW,pred=249
```

Patched A-FAST pack `3b392b291b190b09` → **pred=249** (not historical 664). logit0 not printed on UART.

## C0–C11

See `C0_C11_MARKERS.md`.

| ID | Status |
|----|--------|
| C0 | OBSERVED |
| C1 | **NOT_OBSERVED — first divergence** |
| C2 | NOT_OBSERVED |
| C5 | NOT_OBSERVED |
| C6 | NOT_OBSERVED |
| C7 | NOT_OBSERVED (only MIG_OK calib) |
| C8 | NOT_OBSERVED |
| C9 | PARTIAL (TOPK/PACK/POISON only) |
| C10 | NOT_OBSERVED |
| C11 | NOT_OBSERVED |

## 20-fact result

**NOT_RUN.** This SoC ties `uart_txd_in` to `unused_rx`. Host cannot send TRAIN/FLUSH/RELOAD/mapping packets. Frozen `corpus_20.json` was **not** sent (must not send hashes/winners/addresses). UART_SLIM prints one existence query then completes. G5 OUT 549/861/549/237 **not** on this UART.

No reprogram. No 40-fact. No second program. No old bit.

## PROGRAM result

`PROGRAM_OK` count=1 SHA lock held.

## BOARD_PASS

`not_claimed`
