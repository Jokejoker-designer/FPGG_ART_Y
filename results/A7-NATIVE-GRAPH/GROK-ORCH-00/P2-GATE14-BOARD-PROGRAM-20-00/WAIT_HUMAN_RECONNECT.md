# WAIT_HUMAN_RECONNECT

Human token is valid. Hardware is not.

At preflight (commit `a0a5b1f`) COM12 + JTAG `210319BE776EA` / `xc7a100t_0` were present.  
At program-20 start they are **absent**.

| Check | Now |
|-------|-----|
| GetPortNames | COM3, COM4 only |
| COM12 | **absent** |
| FTDI `VID_0403&PID_6010` / `210319BE776E*` | **absent** from PnP |
| `get_hw_targets` | **n_targets=0** `JTAG_ABSENT` |

Arm-UART-first cannot run (no COM12). Program must not run (no JTAG). No fallback. No old bit. No auto-reprogram.

Reconnect Arty A7 USB (same cable, COM12 + Digilent `210319BE776EA`) and re-issue a human token for gate `P2-GATE14-BOARD-PROGRAM-20-00` + SHA `6975AB75…` if a later attempt is wanted.

`PROGRAMMED_ONCE.txt` was **not** written.
