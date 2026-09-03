# P2-GATE14-BOARD-PREFLIGHT-00 — preregistration (read-only)

**PROGRAM=NO.** No RTL/build edit. No `program_hw_devices`. No COM port open.  
Codex ACCEPT: WDMA CDC `BIT_READY_NOT_PROGRAMMED`. Candidate bit SHA  
`6975AB757FE592DBD0EAB68FBDC7463559A3712CAA9A8BD1E429C9A6BDF8B39A`.

## Scope

1. Re-hash candidate bit + SOURCE_SHA manifest vs live tree.
2. Enumerate exact JTAG target / device ID and serial ports.
3. Verify COM12 + JTAG `210319BE776EA` present; no other Vivado / hw_server / serial owner.
4. Prepare arm-UART-before-program command and same-bit Gate14 20-fact capture **paths**.
5. If COM12 or JTAG absent: `WAIT_HUMAN_RECONNECT` and STOP.

## Must not

- Edit RTL, constraints, MIG, WMEM, law, or build TCL of the candidate.
- Program any bit (including 6975AB75, D5B, F06C, 2E18, AOS, mailbox).
- Open COM12 / any serial handle.
- Use an old bit (pred=664 historical, D5B, F06C, COFIT LUTRAM mock).
- Claim Teacher-Off, Gate14 close, BOARD_PASS, or silicon BRAM-loss.

## Program authority

Only a **human named token** that cites this exact gate **and** bit SHA `6975AB75…F8B39A` may later authorize program. This bag does not contain that token.
