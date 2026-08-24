# A7-LM-05 hardware candidate 01 — FAIL_UPLOAD_FIRST_BYTE

- Bit SHA-256: `B7E68295E3277D5761EC8E4F92D73714B13287398DA79D9E0627FDF19B83A1C1`
- Timing: WNS `+0.292 ns`, TNS `0`, WHS `+0.032 ns`, THS `0`
- Program result: JTAG startup HIGH; DDR calibration and UART status passed.
- Diagnostic write at layer-1 base address `129024`: requested `A1 A2 A3 A4 A5 A6 A7 A8`; readback `0D A2 A3 A4 A5 A6 A7 A8`.
- Verdict: `FAIL_UPLOAD_FIRST_BYTE`. Candidate 01 is not LM-05 board validation evidence.

The candidate-01 interlock correctly held bytes 2–8 during `w_stall`, but byte 0 was issued in the cycle before the new address made the tile miss visible. Candidate 02 preloads `mem_addr_u` when the UART frame is accepted, allowing `w_stall` to rise before `mem_we` and before `wr_i` advances.

LM-05 quality confirmation was not run. No frozen LM-00…04 artifact was modified.
