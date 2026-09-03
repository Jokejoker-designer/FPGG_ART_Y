# P2-GATE14-BOARD-PROGRAM-20-00 — preregistration

Human said “Ok cho program”. Token cites this exact gate and bit SHA  
`6975AB757FE592DBD0EAB68FBDC7463559A3712CAA9A8BD1E429C9A6BDF8B39A`.  
`authorize_program=yes`.

Arm COM12 first (continuous, DTR/RTS off). Program **this bit once** to  
JTAG `Digilent/210319BE776EA` / `xc7a100t_0`. Then frozen 20-fact same-bit  
sequence. Preserve raw UART/CFRAME. No old bit. No auto-reprogram on 0-byte  
or mismatch (recapture then STOP). Any JTAG/COM/SHA/transport error → STOP.  
AI must **not** declare Teacher-Off / BOARD_PASS. No 40-fact.
