# RESULTS — U2-OPTIMIZED-FULLCHIP-COFIT-00

```text
RTL_EDIT    = NO
BIT         = NO
PROGRAM     = NO
GATE14_PASS = NO
M10         = OPEN
PHYS        = 4
TOP         = arty_a7_ng_native_v1_ab_soc_top
PART        = xc7a100tcsg324-1
EVIDENCE    = POST_ROUTE
```

One unknown: does the current ping-pong PHYS=4 C9 SoC **fit and time**?

## Run history

1. First synth **FAIL** `[Synth 8-439] module 'a7ng_learned_prior_graph' not found`.
   Copied P2-G1G5 fileset was the old existence SoC (`persist_gen_fast` + `teacher_off_glue`).
2. Fileset aligned to G14-FINAL-OBS-BIT-00 C9 production list. Re-synth/impl. **PROGRAM=NO**, bitstream skipped.
3. Script first scored `GATE_FAIL free_slices=-15697` because the Slice regex captured **Fixed=0** as Available. Device report is `| Slice | 15697 | 0 | 0 | 15850 | 99.03 |`. Rescored from that row.

## Hard table

| Check | Result |
| --- | --- |
| WNS | **0.808** ns ≥ 0 |
| TNS | **0.000** |
| WHS | **0.020** ns ≥ 0 |
| THS | **0.000** |
| setup/hold failing endpoints | **0 / 0** |
| route errors | **0** (75246/75246 fully routed) |
| DRC ERROR/FATAL | **0** (warnings only) |
| CDC candidate_logic | **0** (1 clkgen falsepath) |
| RAMB36 | **104** / 135 |
| DSP | **19** / 240 |
| Slice | **15697 / 15850** free **153** |
| LUT | **38729 / 63400** (61.09%) |
| FF | **45782 / 126800** (36.11%) |
| DEVICE_FIT | **PASS** |
| bitstream | **SKIP** |
| U2 | **PASS** |

`free=153 < 256` is **RISK** (preferred margin), not a Blueprint hard fail (`<64` would be). Ping-pong dual-bank costs slices vs FINAL-OBS 15589/15850 free 261.

## Not this gate

No board program. No final bit claim. Frozen bits 1F0F2ABB / 9CA2B30D / F24150BD untouched. Oracle HOLD.

NEXT = close U3 from DDR-WAVE-PINGPONG-00 bag `492277f`, then U3R.
