# Gate14 UART binary protocol v1 — frozen before RTL

**PROGRAM=NO.** VERSION=0x01. CRC16-CCITT-FALSE (init 0xFFFF, poly 0x1021, no xorout) over VERSION..PAYLOAD.

## Command frame (host → FPGA)

```text
SOF0 0xA7
SOF1 0x14
VERSION 0x01
TYPE 1
SEQ 2 LE
LEN 2 LE   (0..8)
PAYLOAD LEN
CRC16 2 LE
```

Parser resyncs on bad byte. Reject: version, length>8, CRC, unknown TYPE, duplicate consumed SEQ, partial frame, queue busy.

## TYPE whitelist

| TYPE | Name | Payload | Glue cmd |
|------|------|---------|----------|
| 0x01 | CMD_RESET_LEARNED | none | C_TRESET |
| 0x02 | CMD_TRAIN_BEGIN | none | C_TRAIN |
| 0x03 | CMD_QUERY_TOKEN | tok u8 | C_TOK |
| 0x04 | CMD_QUERY_COMMIT | none | C_FIRE |
| 0x05 | CMD_REWARD | s8 reward, u16 txn LE | C_REW if txn==FPGA txn else reject |
| 0x06 | CMD_FLUSH | none | C_FLUSH |
| 0x07 | CMD_BRAM_KILL | none | C_KILL |
| 0x08 | CMD_RELOAD | none | C_RELOAD |
| 0x09 | CMD_FREEZE | none | C_FREEZE |
| 0x0A | CMD_TRAIN_RESET | none | C_TRESET |
| 0x0B | CMD_SNAPSHOT | none | CFRAME dump |
| 0x0C | CMD_EXAM_QUERY | tok u8 | C_TOK then C_FIRE |
| 0x0D | CMD_STATUS | none | CFRAME dump |

## CFRAME (FPGA → host)

```text
SOF0 0xC1  SOF1 0x11  VERSION 0x01
CHECKPOINT_ID 1   (0..11)
SEQ 2 LE
LEN 2 LE
PAYLOAD
CRC16 2 LE over VERSION..PAYLOAD
```

Checkpoint payloads (little-endian):

- C0: 8 B identity digest
- C1: 1 B live MODE
- C2: 8 B ANCH
- C3: 8 B Top-K id bytes + 16 B scores
- C4: 8 B evs||evr||evo digest
- C5: 4 B consume, 4 B reject, 1 B last_ack
- C6: 2 B reserved + 1 B sat
- C7: 4 B addr digest, 1 B ack, 1 B err
- C8: 4 B GEN, 8 B SDIG
- C9: 8 B TOPK, 16 B scores, 8 B PACK, 1 B POISON, 4+1+4 R1S/R1R/R1O
- C10: 1 LMST, 1 LMDN, 2 OUT, 2 consumed-X
- C11: 8 ADIG, 8 BDIG, 1 a_forgotten, 1 b_visible

## Clocks

UART PHY: **CLK100MHZ = 100 MHz**, 115200 8N1.  
Command FSM / glue: **core_clk = 12.5 MHz**. Byte CDC toggle+ASYNC_REG 3-flop.
