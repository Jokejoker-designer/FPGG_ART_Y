# Basys 3 board plan

The first board revision should prioritize observability over UI convenience.

## Proposed manual pins

```text
SW7:0   stimulus code
SW15:8  teacher code

BTNU    TRAIN one transaction
BTNC    EVAL one transaction
BTNR    toggle FREEZE
BTNL    RESET learned weights

LED7:0  latched output_spikes
LED8    done pulse / stretched indicator
LED9    update pulse
LED10   freeze state
LED14   train activity
LED15   clock lock / heartbeat
```

For actual text conversation, UART replaces manual switch entry.

## UART protocol planned

```text
TRAIN:
A5 81 stimulus teacher checksum

EVAL:
A5 82 stimulus 00 checksum

CONTROL:
A5 83 command argument checksum

RESULT:
A5 84 output updates mismatch flags checksum
```

No training corpus is stored in FPGA ROM.
