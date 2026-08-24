# A7-LM-05 hardware candidate 01 — BUILD only

Interlock RTL (host R/W gated on `!w_stall`; busy exposes `w_stall || wr_go || rd_go`).  
This is **not** board validation and does **not** authorize LM-06.

| Field | Value |
|-------|--------|
| Bit | `build/out/arty_a7_lm05.bit` |
| SHA-256 | `B7E68295E3277D5761EC8E4F92D73714B13287398DA79D9E0627FDF19B83A1C1` |
| Vivado | 2026.1 batch `vivado/tcl/build_a7lm05.tcl` log `build/a7lm05_interlock.log` |
| Official post-route (physopt) | WNS **+0.292 ns**, TNS **0**, WHS **+0.032 ns**, THS **0** |
| Router intermediate (hold-fix) | WNS +0.291 / WHS +0.031 — superseded by official summary |
| Failed nets | 0 |
| Route | first-iteration converge; no congestion fail |
| LUT / FF / Slice | 39181 (61.80%) / 27810 (21.93%) / 14061 (88.71%) |
| RAMB36 / DSP | 134 / 152 (same footprint as synth) |
| Program | **not run** for this SHA |
| Quality | not run; `A7-LM-05-CONFIRMATION.md` not frozen |

Candidate-00 FAIL preserved:

- `build/out/arty_a7_lm05c0_stall_fail.bit`
- SHA `31D869D62A2CC1A2067F11A288B663509E9374156696A8C2422BEDF815D9772B`
- `results/A7-LM-05/hardware_candidate_00/DIAGNOSTIC.md`

Frozen 00–03 and LM-04 R5 bits were SHA-checked before `write_bitstream` and rechecked after. Unchanged.

WNS ≥ +0.20 is only the **timing half** of the LM-06 gate. LM-06 stays unauthorized until LM-05 BOARD_PASS including hardware ladder + frozen quality confirmation.
