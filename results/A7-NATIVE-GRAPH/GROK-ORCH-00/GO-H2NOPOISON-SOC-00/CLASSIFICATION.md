# G0 — GO-H2NOPOISON-SOC-00 classification

```text
H2NOPOISON_NOFIT_Place_30-487
```

**PROGRAM=NO.** NO_BIT. COM12 not used. BOARD_PASS not claimed.

## Vivado

| Field | Value |
|-------|--------|
| Exit | 2026-08-30 20:52:48 |
| synth_design | completed, 0 errors, 21 critical warnings |
| post-synth Slice LUTs | **63423 / 63400 (100.04%)** `report_utilization.rpt` Design State Synthesized |
| LUT as Logic | 60677 |
| LUT as Memory | 2746 |
| Slice Registers | 58735 (46.32%) |
| Unique Control Sets | 2548 |
| RAMB36 | 103 / 135 |
| DSP | 19 |
| u_ab LUT | 55738 (`report_utilization_hier.rpt`) |
| **u_global LUT** | **7701** |
| **u_merge LUT** | **7686** |
| place_design | **FAIL** `[Place 30-487]` |
| Place detail | 15850 slices, 12320 available, unplaced need 13422; combined LUT 66131 / 63400; FF 58735; control sets 2462 |
| write_bitstream | not reached |
| BIT_SHA256 | none |

## Telemetry finding (not pred=733 cause)

`u_stat_sync` is `#(.WIDTH(47))` in `arty_a7_ng_native_v1_ab_soc_top.sv`. Audit flagged 32-bit concatenations. Cleanup later, one unknown. Not 733.

## vs Cursor poison-off

Same class: live `u_global` (~7.7k LUT merge) + poison-off keeps Global Top-8. Cursor post-synth 63246 LUT, Place 30-487. Grok 63423 LUT (extra UART TOPK/PACK/POISON CDC) — **not better**.

Independent check **CONFIRMS** physical blocker. Next: `GLOBAL-TOPK-MINHEAP-00` research only. Do not reprogram EC286E9E. Do not full-chip integrate min-heap from this G0.
