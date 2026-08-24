# GATE: lm06_ua_core — PASS_NARROW — 2026-08-22

```text
GATE: lm06_ua_core
UNKNOWN: can_u_a_fit_with_weight_tiles_on_soc
TESTS: vivado/tcl/native_graph/measure_lm06_ua_core.tcl (post-route)
EXPECTED: named u_a (act_ram128k16) PRESENT; weight tiles retained; WNS>=0; TNS=0; BRAM<=135; frozen MATCH; new bit ≠ CONTROL D61BA6D4…
ACTUAL: BRAM=128 WNS=+0.257 TNS=0 WHS=+0.024 THS=0; u_a BRAM=64; wt BRAM=64; PE u_sc LUT=1047 FF=1856 lanes=16; DSP=0; SHA=D2C6CF4B…
PASS/FAIL: PASS_NARROW
ARTIFACT: results/A7-NATIVE-GRAPH/LM06-UA/GATE_lm06_ua_core.md
SHA256: D2C6CF4B28706B24CE513E2B7A09A4018EB9BB01EBB864FA3A5375B11DB9A92C
```

## Scientific frame

| Slot | Value |
|------|-------|
| OBSERVATION | weight-cut SoC D61BA6D4… BRAM64 WNS+0.365; act u_a ABSENT LIMIT |
| UNKNOWN | can u_a (frozen-law act_ram128k16) instantiate with weight tiles WNS≥0 TNS=0 BRAM≤device and path > sticky-UART-only? |
| H_CANDIDATE | new bit with named u_a in netlist + timing PASS |
| H_RIVAL | fake lm_path; overwrite frozen LM-06; host answers |
| FALSIFIER | frozen SHA change; fit LIMIT sold as HS-22 closed; BOARD_PASS |
| CONTROL | weight-cut D61BA6D4…; frozen LM-06/01R/02M/A0.3 MATCH |
| UNIT | one post-route SoC composition |

## Measured (post-route)

| Metric | Value | Provenance | Gate |
|--------|------:|------------|------|
| WNS / TNS | +0.257 / 0.000 | `lm06_ua_timing.rpt` Design Timing Summary L141 | **PASS** |
| WHS / THS | +0.024 / 0.000 | same | **PASS** |
| LUT / FF / DSP | 7209 / 8075 / 0 | `lm06_ua_util.rpt` | **PASS** (DSP=0 this cut) |
| Block RAM Tile | 128 / 135 | util | **PASS** (≤135; ≤prefer 130) |
| Weight fabric | PRESENT | hier `u_lm06_wtile` RAMB36=32 + `u_lm06_wpp` RAMB36=32 | **PASS** |
| Act `u_a` | PRESENT | DCP cell `u_a` REF=`act_ram128k16`; 64×`mem_reg_*` RAMB36 | **PASS** |
| PE lanes | 16 fabric | hier `u_sc` LUT=1047 FF=1856; 16×`g_lane` | **PASS** |
| MIG | present | hier `u_mig` LUT=4301 | **PASS** |
| lm_path RTL | sticky after wt_seen **and** act_seen; act_keep into compose | `arty_a7_ng_lm06_ua_soc_top.sv` | **PASS_NARROW** (not board-probed) |
| New SoC bit SHA | D2C6CF4B…B9A92C | live SHA256 | ≠ CONTROL weight-cut |
| CONTROL weight-cut | D61BA6D4…053FA3 | LM06-SOC retained MATCH | **PASS** (HS-20) |
| Frozen LM-06/01R/02M/A0.3 | MATCH | `frozen_sha.txt` | **PASS** (HS-20) |

## LIMIT (honest)

1. **Act cut + weights only:** `act_ram128k16 u_a` (64) + weight fabric (64) = 128 BRAM. Full TinyGPT core / DSP≈154 / snap **ABSENT**.
2. **lm_path:** RTL sticky from weight+act BRAM readback + compose XOR — **not** COM12 board probe this gate.
3. **Not** semantic HS-02 / retrieval answers / BOARD_PASS / HS-22 silicon participation closed.
4. New bit **does not** replace frozen `arty_a7_lm06.bit` or CONTROL weight-cut D61BA6D4… (HS-20).
5. Hier util report omits pure-RAM `u_a` row (Vivado quirk); netlist DCP proves named `u_a`.

## H_RIVAL checks

| Rival | Outcome |
|-------|---------|
| Fake lm_path / no act BRAM | **Did not fire** — u_a 64 + wt 64 post-route |
| Overwrite frozen LM-06 | **Did not fire** — SHA MATCH |
| Host answers / BOARD_PASS | **Did not fire** |

## Explicit non-claims

- Not `NATIVE_V1_MINI_AI_BOARD_PASS`
- Not full LM-06 law forward path (no GPT/DSP core)
- Not silicon teacher-off retrieval / HS-02 semantic / HS-22 closed
- Not WM-00 timing bankable
