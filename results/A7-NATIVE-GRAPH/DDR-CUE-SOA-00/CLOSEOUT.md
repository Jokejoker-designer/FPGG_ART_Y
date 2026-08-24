# CLOSEOUT — ddr_cue_soa_00 (ATTEMPT 2)

**Result:** **FAIL**
**Evidence_class:** `MIG_XSIM_SOA` (Digilent AXI MIG + `ddr3_model`) — **not BOARD**
**Agent:** `a7-ng-memory-arch`
**Attempt:** 2
**Marker:** `A7NG_DDR_CUE_SOA_XSIM_PASS` — **not observed**
**Log:** `results/A7-NATIVE-GRAPH/DDR-CUE-SOA-00/xsim_ddr_cue_soa.log`
**Run script:** `tests/xsim/run_a7ng_ddr_cue_soa.tcl`

## The one unknown (unchanged)

> Can physical SOA layout reduce first-stage DDR bytes/query without changing laws?

**Not answered.** Query fetch never completes; 832 B / 52 beats / top1 id=57 score=165 not measured.

## Observation (FACT)

| Item | Value |
|------|-------|
| Preload | `SOA_PRELOAD_DONE` at ~126 ms sim |
| First query DDR read | `bank 1 col 018` (`0x03000030`) — prior plane beat 4 only |
| ID/CUE reads after preload | **0** `bank 0` read commands (ID `0x01000000`, CUE `0x01100000` never issued) |
| Hang signature | Duplicate `Read bank 1 col 018` AR pair; MIG retry loop; `done_o` never asserts |
| Patterns | 0 / 2 pass before `#900ms` `SOA_TIMEOUT` |
| Marker | No `SOA_PATTERN_PASS`, no `A7NG_DDR_CUE_SOA_XSIM_PASS` |

## Root cause (INFERENCE — high confidence)

1. **Orchestrator / plane handshake:** SOA wavefront advances to prior-plane fetch without completing ID/CUE column DDR reads (spurious or stale `done` before `plane_active` fetch issues AR).
2. **Transport:** Last prior beat (`0x03000030`) shows classic AXI R-channel liveness failure — duplicate AR to col 018, R not fully accepted before `r_ready` drops.

Attempt 2 strategy (reuse proven AR/R engine + post-fetch SOA pack) implemented via `a7ng_axi_read_stream` + gated `done_pulse_o` / `plane_active` / issued==returned guards. **Hang unchanged** in full MIG run (~126 ms → col 018 loop).

## RTL / TB changes (attempt 2)

| File | Change |
|------|--------|
| `rtl/native_graph/memory/a7ng_axi_read_stream.sv` | **NEW** — generic byte AR/R stream from `a7ng_cue_wavefront` law; `done_pulse_o`, `beats_issued_o`, issued==returned completion |
| `rtl/native_graph/memory/a7ng_cue_soa_wavefront.sv` | 3-plane orchestrator; `plane_active`; explicit `SOA_FETCH_PRIOR` case; beat-count gates on `pf_done_pulse` |
| `rtl/native_graph/memory/a7ng_soa_plane_fetch.sv` | Superseded by `a7ng_axi_read_stream` in compile list |
| `tests/xsim/run_a7ng_ddr_cue_soa.tcl` | Compile `a7ng_axi_read_stream.sv` |
| `tests/xsim/tb_a7ng_ddr_cue_soa.sv` | `drain_stale_axi_r()` after preload; gate id `ddr_cue_soa_00r_axi_liveness` prereg |

## Success criteria vs result

| Criterion | Expected | Got |
|-----------|----------|-----|
| Marker | `A7NG_DDR_CUE_SOA_XSIM_PASS` | absent |
| `axi_read_bytes` | 832 | not measured (hang) |
| `axi_read_beats` | 52 | not measured |
| Top-1 law | id=57 score=165 | not reached |
| Patterns | 2 pass | 0 pass |

## Next step

Per `results/A7-NATIVE-GRAPH/STATUS/DDR_CUE_SOA_00R_AXI_LIVENESS.md`:

1. AXI-boundary waveform on `ar_fire` / `r_fire` at `0x03000030`
2. R skid FIFO decoupling `m_axi_rready` from phase FSM
3. 4-AR transaction plan (16+16+16+4 beats) with scoreboard invariants
4. Preload owner-switch audit (`feed_en` handoff)

## LIMITs

- XSim only; no BOARD_PASS claim.
- AI does not declare `NATIVE_V1_MINI_AI_BOARD_PASS`.
