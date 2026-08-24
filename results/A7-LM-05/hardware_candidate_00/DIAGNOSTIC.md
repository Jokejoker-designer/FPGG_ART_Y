# A7-LM-05 hardware candidate 00 — FAIL_UPLOAD_TILE_STALL

- Bit: `build/out/arty_a7_lm05c0_stall_fail.bit`
- SHA-256: `31D869D62A2CC1A2067F11A288B663509E9374156696A8C2422BEDF815D9772B`
- Timing: WNS `+0.102 ns`, TNS `0`, WHS `+0.038 ns`
- Program result: JTAG startup HIGH; DDR calibration and A5/A1 UART status passed.
- Diagnostic write: address `129024` (first byte of layer 1), requested bytes `A1 A2 A3 A4 A5 A6 A7 A8`.
- Readback after tile refill: `F9 FF 01 FC 01 FB FE FF`.
- Verdict: `FAIL_UPLOAD_TILE_STALL`. This candidate is not board validation evidence and must not be used to close LM-05.

Root cause: the top-level host write/read FSM advanced while `weight_tile399k.stall` was asserted during a layer cache miss. The candidate-01 RTL gates host read/write progress on `!w_stall`, rejects overlapping host requests, and exposes `w_stall || wr_go || rd_go` through the status busy bit for host flow control.

No LM-00…04 bitstream was modified. LM-05 quality confirmation was not run.
